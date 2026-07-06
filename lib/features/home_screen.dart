import 'package:flutter/material.dart';

import '../core/app_settings.dart';
import '../models/git_project.dart';
import '../models/scan_progress.dart';
import '../services/git_operations.dart';
import '../services/git_runner.dart';
import '../services/git_scanner.dart';
import '../services/scan_cancellation.dart';
import 'settings_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _runner = GitRunner();
  late final GitScanner _scanner = GitScanner(_runner);
  late final GitOperations _ops = GitOperations(_runner);

  AppSettings _settings = AppSettings();
  List<GitProject> _projects = [];
  final List<String> _logs = [];
  bool _busy = false;
  bool _scanning = false;
  ScanCancellation? _scanCancellation;
  ScanProgress? _scanProgress;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AppSettings.load();
    if (!mounted) return;
    setState(() => _settings = settings);
    if (settings.projectsRoot.isNotEmpty) {
      await _scan();
    }
  }

  void _log(String line) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String().substring(11, 19)} $line');
      if (_logs.length > 500) _logs.removeLast();
    });
  }

  List<GitProject> get _selectedProjects =>
      _projects.where((p) => p.selected).toList(growable: false);

  void _stopScan() {
    if (!_scanning) return;
    _scanCancellation?.cancel();
    _log('Остановка сканирования…');
  }

  Future<void> _scan() async {
    if (_settings.projectsRoot.isEmpty) {
      _log('Укажите директорию с проектами в настройках');
      return;
    }
    final cancellation = ScanCancellation();
    setState(() {
      _busy = true;
      _scanning = true;
      _scanCancellation = cancellation;
      _scanProgress = const ScanProgress(
        total: 0,
        completed: 0,
        successCount: 0,
        errorCount: 0,
      );
    });
    _log('Сканирование ${_settings.projectsRoot}…');
    try {
      final projects = await _scanner.scan(
        rootPath: _settings.projectsRoot,
        recursive: _settings.recursiveScan,
        settings: _settings,
        cancellation: cancellation,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _scanProgress = progress;
            _projects = List.from(progress.projects);
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _scanProgress = ScanProgress(
          total: projects.length,
          completed: projects.length,
          successCount: projects.where((p) => !p.scanFailed).length,
          errorCount: projects.where((p) => p.scanFailed).length,
          projects: projects,
        );
      });
      final withUpdates = projects.where((p) => p.hasRemoteUpdates).length;
      _log(
        'Готово: ${projects.length} репозиториев, '
        'OK ${projects.where((p) => !p.scanFailed).length}, '
        'ошибок ${projects.where((p) => p.scanFailed).length}'
        '${withUpdates > 0 ? ', обновлений доступно: $withUpdates' : ''}',
      );
    } on ScanCancelledException {
      if (!mounted) return;
      final progress = _scanProgress;
      final scanned = _projects.length;
      final total = progress?.total ?? scanned;
      _log(
        'Сканирование остановлено: $scanned из $total, '
        'OK ${progress?.successCount ?? 0}, ошибок ${progress?.errorCount ?? 0}',
      );
      if (progress != null) {
        setState(() {
          _scanProgress = ScanProgress(
            total: progress.total,
            completed: progress.completed,
            successCount: progress.successCount,
            errorCount: progress.errorCount,
            projects: _projects,
            cancelled: true,
          );
        });
      }
    } catch (e) {
      _log('Ошибка сканирования: $e');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _scanning = false;
          _scanCancellation = null;
        });
      }
    }
  }

  Future<void> _runOnProjects(
    List<GitProject> targets,
    String label,
    Future<GitProject> Function(GitProject p) action,
  ) async {
    if (targets.isEmpty) {
      _log('Нет выбранных проектов');
      return;
    }
    setState(() {
      _busy = true;
      _scanProgress = null;
    });
    _log('=== $label (${targets.length}) ===');
    for (final project in targets) {
      final index = _projects.indexWhere((p) => p.path == project.path);
      if (index < 0) continue;
      setState(() {
        _projects[index] = _projects[index].copyWith(
          status: GitProjectStatus.scanning,
          clearUpdatesReceived: true,
        );
      });
      try {
        final updated = await action(project);
        if (!mounted) return;
        setState(() => _projects[index] = updated);
        _log('[${project.name}] ${updated.lastMessage ?? updated.status.name}');
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _projects[index] = _projects[index].copyWith(
            status: GitProjectStatus.error,
            lastMessage: '$e',
          );
        });
        _log('[${project.name}] ошибка: $e');
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _openSettings() async {
    final updated = await showModalBottomSheet<AppSettings>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SettingsSheet(initial: _settings),
    );
    if (updated == null) return;
    await updated.save();
    setState(() => _settings = updated);
    if (updated.projectsRoot.isNotEmpty) await _scan();
  }

  void _toggleSelectAll(bool? value) {
    final select = value ?? false;
    setState(() {
      _projects = _projects.map((p) => p.copyWith(selected: select)).toList();
    });
  }

  void _toggleProject(int index, bool? value) {
    setState(() {
      _projects[index] = _projects[index].copyWith(selected: value ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = _selectedProjects.length;
    final isScanning = _scanning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repo Sync Hub'),
        actions: [
          IconButton(
            tooltip: 'Настройки',
            onPressed: _busy ? null : _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          _Toolbar(
            rootPath: _settings.projectsRoot,
            busy: _busy,
            isScanning: isScanning,
            scanProgress: _scanProgress,
            selectedCount: selectedCount,
            totalCount: _projects.length,
            onScan: _scan,
            onPull: () => _runOnProjects(
              _selectedProjects,
              'Pull main/master',
              (p) => _ops.pullDefaultBranch(p, _settings, log: _log),
            ),
            onPush: () => _runOnProjects(
              _selectedProjects,
              'Push GitLab',
              (p) => _ops.pushToGitlab(p, _settings, log: _log),
            ),
            onSync: () => _runOnProjects(
              _selectedProjects,
              'Sync',
              (p) => _ops.syncProject(p, _settings, log: _log),
            ),
            onStopScan: _stopScan,
            onSettings: _openSettings,
          ),
          Expanded(
            flex: 3,
            child: _projects.isEmpty && !isScanning
                ? Center(
                    child: Text(
                      _settings.projectsRoot.isEmpty
                          ? 'Выберите директорию с git-проектами'
                          : 'Репозитории не найдены',
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                : _ProjectList(
                    projects: _projects,
                    busy: _busy,
                    onToggleAll: _toggleSelectAll,
                    onToggle: _toggleProject,
                    onPull: (p) => _runOnProjects(
                      [p],
                      'Pull',
                      (x) => _ops.pullDefaultBranch(x, _settings, log: _log),
                    ),
                    onPush: (p) => _runOnProjects(
                      [p],
                      'Push',
                      (x) => _ops.pushToGitlab(x, _settings, log: _log),
                    ),
                    onSync: (p) => _runOnProjects(
                      [p],
                      'Sync',
                      (x) => _ops.syncProject(x, _settings, log: _log),
                    ),
                  ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 1,
            child: _LogPanel(logs: _logs, onClear: () => setState(_logs.clear)),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.rootPath,
    required this.busy,
    required this.isScanning,
    required this.scanProgress,
    required this.selectedCount,
    required this.totalCount,
    required this.onScan,
    required this.onPull,
    required this.onPush,
    required this.onSync,
    required this.onStopScan,
    required this.onSettings,
  });

  final String rootPath;
  final bool busy;
  final bool isScanning;
  final ScanProgress? scanProgress;
  final int selectedCount;
  final int totalCount;
  final VoidCallback onScan;
  final VoidCallback onPull;
  final VoidCallback onPush;
  final VoidCallback onSync;
  final VoidCallback onStopScan;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = scanProgress;

    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rootPath.isEmpty ? 'Директория не задана' : rootPath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text('$selectedCount / $totalCount'),
              ],
            ),
            if (isScanning && progress != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      progress.cancelled
                          ? 'Остановка…'
                          : progress.currentName != null
                              ? 'Сканирование: ${progress.currentName}'
                              : progress.total == 0
                                  ? 'Поиск репозиториев…'
                                  : 'Сканирование…',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (progress.total > 0)
                    Text(
                      '${progress.completed}/${progress.total}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              if (progress.total > 0) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(value: progress.fraction),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 6),
              Text(
                'OK: ${progress.successCount} · ошибок: ${progress.errorCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (progress != null && progress.isDone && !busy) ...[
              const SizedBox(height: 8),
              Text(
                progress.cancelled
                    ? 'Остановлено: OK ${progress.successCount}, ошибок ${progress.errorCount}, '
                        'просканировано ${progress.completed}/${progress.total}'
                    : 'Сканирование: OK ${progress.successCount}, ошибок ${progress.errorCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: busy ? null : onSettings,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Директория'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isScanning ? onStopScan : (busy ? null : onScan),
                  icon: Icon(isScanning ? Icons.stop_rounded : Icons.refresh),
                  label: Text(isScanning ? 'Остановить' : 'Сканировать'),
                ),
                FilledButton.icon(
                  onPressed: busy || selectedCount == 0 ? null : onPull,
                  icon: const Icon(Icons.download),
                  label: const Text('Pull'),
                ),
                FilledButton.icon(
                  onPressed: busy || selectedCount == 0 ? null : onPush,
                  icon: const Icon(Icons.upload),
                  label: const Text('Push GitLab'),
                ),
                FilledButton.icon(
                  onPressed: busy || selectedCount == 0 ? null : onSync,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectList extends StatelessWidget {
  const _ProjectList({
    required this.projects,
    required this.busy,
    required this.onToggleAll,
    required this.onToggle,
    required this.onPull,
    required this.onPush,
    required this.onSync,
  });

  final List<GitProject> projects;
  final bool busy;
  final void Function(bool? value) onToggleAll;
  final void Function(int index, bool? value) onToggle;
  final void Function(GitProject project) onPull;
  final void Function(GitProject project) onPush;
  final void Function(GitProject project) onSync;

  @override
  Widget build(BuildContext context) {
    final allSelected = projects.isNotEmpty && projects.every((p) => p.selected);
    final updatesCount = projects.where((p) => p.hasRemoteUpdates).length;

    return Column(
      children: [
        CheckboxListTile(
          value: allSelected,
          tristate: true,
          onChanged: busy ? null : onToggleAll,
          title: Row(
            children: [
              const Text('Выбрать все'),
              if (updatesCount > 0) ...[
                const SizedBox(width: 12),
                _UpdatesChip(
                  label: 'обновлений: $updatesCount',
                  icon: Icons.system_update_alt,
                  color: Colors.orange.shade700,
                ),
              ],
            ],
          ),
          dense: true,
        ),
        Expanded(
          child: ListView.separated(
            itemCount: projects.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = projects[index];
              return _ProjectTile(
                project: p,
                busy: busy,
                onChanged: (v) => onToggle(index, v),
                onPull: () => onPull(p),
                onPush: () => onPush(p),
                onSync: () => onSync(p),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.project,
    required this.busy,
    required this.onChanged,
    required this.onPull,
    required this.onPush,
    required this.onSync,
  });

  final GitProject project;
  final bool busy;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onPull;
  final VoidCallback onPush;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Checkbox(value: project.selected, onChanged: busy ? null : onChanged),
      title: Row(
        children: [
          _StatusDot(status: project.status, scanFailed: project.scanFailed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (project.hasRemoteUpdates)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _UpdatesChip(
                label: project.remoteBehindCount > 0
                    ? '+${project.remoteBehindCount}'
                    : 'обновления',
                icon: Icons.arrow_downward_rounded,
                color: theme.colorScheme.tertiary,
                tooltip: 'Доступны обновления на remote',
              ),
            ),
          if (project.updatesReceived)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _UpdatesChip(
                label: 'получены',
                icon: Icons.check_circle_outline,
                color: Colors.green.shade700,
                tooltip: 'Обновления успешно подтянуты',
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${project.currentBranch ?? '?'} · default ${project.defaultBranch ?? '?'}'
            '${project.isDirty ? ' · dirty' : ''}',
          ),
          if (project.gitlabRemote != null)
            Text('remote: ${project.gitlabRemote}', style: theme.textTheme.bodySmall),
          if (project.scanError != null)
            Text(
              project.scanError!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            )
          else if (project.lastMessage != null)
            Text(project.lastMessage!, style: theme.textTheme.bodySmall),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        enabled: !busy,
        onSelected: (value) {
          switch (value) {
            case 'pull':
              onPull();
            case 'push':
              onPush();
            case 'sync':
              onSync();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'pull', child: Text('Pull main/master')),
          PopupMenuItem(value: 'push', child: Text('Push на GitLab')),
          PopupMenuItem(value: 'sync', child: Text('Sync (pull + push)')),
        ],
      ),
    );
  }
}

class _UpdatesChip extends StatelessWidget {
  const _UpdatesChip({
    required this.label,
    required this.icon,
    required this.color,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    if (tooltip == null) return chip;
    return Tooltip(message: tooltip!, child: chip);
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status, required this.scanFailed});

  final GitProjectStatus status;
  final bool scanFailed;

  @override
  Widget build(BuildContext context) {
    final color = scanFailed
        ? Colors.red
        : switch (status) {
            GitProjectStatus.idle => Colors.grey,
            GitProjectStatus.scanning ||
            GitProjectStatus.pulling ||
            GitProjectStatus.pushing ||
            GitProjectStatus.syncing =>
              Colors.blue,
            GitProjectStatus.success => Colors.green,
            GitProjectStatus.warning => Colors.orange,
            GitProjectStatus.error => Colors.red,
          };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LogPanel extends StatelessWidget {
  const _LogPanel({required this.logs, required this.onClear});

  final List<String> logs;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Text('Лог', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              TextButton(onPressed: logs.isEmpty ? null : onClear, child: const Text('Очистить')),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: logs.length,
            itemBuilder: (context, index) => Text(
              logs[index],
              style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
