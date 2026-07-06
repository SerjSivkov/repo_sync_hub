import 'package:flutter/material.dart';

import '../core/app_settings.dart';
import '../models/git_project.dart';
import '../services/git_operations.dart';
import '../services/git_runner.dart';
import '../services/git_scanner.dart';
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

  Future<void> _scan() async {
    if (_settings.projectsRoot.isEmpty) {
      _log('Укажите директорию с проектами в настройках');
      return;
    }
    setState(() => _busy = true);
    _log('Сканирование ${_settings.projectsRoot}…');
    try {
      final projects = await _scanner.scan(
        rootPath: _settings.projectsRoot,
        recursive: _settings.recursiveScan,
        settings: _settings,
      );
      setState(() => _projects = projects);
      _log('Найдено репозиториев: ${projects.length}');
    } catch (e) {
      _log('Ошибка сканирования: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
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
    setState(() => _busy = true);
    _log('=== $label (${targets.length}) ===');
    for (final project in targets) {
      final index = _projects.indexWhere((p) => p.path == project.path);
      if (index < 0) continue;
      setState(() {
        _projects[index] = _projects[index].copyWith(status: GitProjectStatus.scanning);
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
            onSettings: _openSettings,
          ),
          Expanded(
            flex: 3,
            child: _projects.isEmpty
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
    required this.selectedCount,
    required this.totalCount,
    required this.onScan,
    required this.onPull,
    required this.onPush,
    required this.onSync,
    required this.onSettings,
  });

  final String rootPath;
  final bool busy;
  final int selectedCount;
  final int totalCount;
  final VoidCallback onScan;
  final VoidCallback onPull;
  final VoidCallback onPush;
  final VoidCallback onSync;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
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
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text('$selectedCount / $totalCount'),
              ],
            ),
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
                  onPressed: busy ? null : onScan,
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Сканировать'),
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

    return Column(
      children: [
        CheckboxListTile(
          value: allSelected,
          tristate: true,
          onChanged: busy ? null : onToggleAll,
          title: const Text('Выбрать все'),
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
    return ListTile(
      leading: Checkbox(value: project.selected, onChanged: busy ? null : onChanged),
      title: Row(
        children: [
          _StatusDot(status: project.status),
          const SizedBox(width: 8),
          Expanded(child: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w600))),
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
            Text('remote: ${project.gitlabRemote}', style: Theme.of(context).textTheme.bodySmall),
          if (project.lastMessage != null)
            Text(project.lastMessage!, style: Theme.of(context).textTheme.bodySmall),
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

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final GitProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      GitProjectStatus.idle => Colors.grey,
      GitProjectStatus.scanning || GitProjectStatus.pulling || GitProjectStatus.pushing || GitProjectStatus.syncing => Colors.blue,
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
