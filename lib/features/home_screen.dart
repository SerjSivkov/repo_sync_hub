import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_settings.dart';
import '../core/format.dart';
import '../core/theme_controller.dart';
import '../models/git_project.dart';
import '../models/repo_group.dart';
import '../models/scan_progress.dart';
import '../services/git_operations.dart';
import '../services/git_runner.dart';
import '../services/git_scanner.dart';
import '../services/repo_cache.dart';
import '../services/repo_shortcut.dart';
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
  final _cache = RepoCache();

  AppSettings _settings = AppSettings();
  List<GitProject> _projects = [];
  final List<String> _logs = [];
  bool _busy = false;
  bool _scanning = false;
  ScanCancellation? _scanCancellation;
  ScanProgress? _scanProgress;
  Timer? _scheduleTimer;
  DateTime? _lastScanFinishedAt;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _scheduleTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final settings = await AppSettings.load();
    final cached = await _cache.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _projects = cached;
    });
    appThemeMode.value = settings.themeMode;
    _setupSchedule();

    if (settings.hasRoots) {
      if (settings.autoScanOnStartup || cached.isEmpty) {
        await _scan();
      } else {
        _log('Загружено из кэша: ${cached.length} репозиториев '
            '(сканирование при запуске отключено)');
      }
    }
  }

  void _setupSchedule() {
    _scheduleTimer?.cancel();
    if (!_settings.scheduleEnabled || _settings.scheduleIntervalMinutes <= 0) {
      return;
    }
    final interval = Duration(minutes: _settings.scheduleIntervalMinutes);
    _scheduleTimer = Timer.periodic(interval, (_) {
      if (_busy || _scanning) return;
      if (!_settings.hasRoots) return;
      _log('Плановое сканирование (по расписанию)…');
      _scan();
    });
    _log('Расписание включено: каждые '
        '${_settings.scheduleIntervalMinutes} мин');
  }

  void _log(String line) {
    setState(() {
      _logs.insert(
          0, '${DateTime.now().toIso8601String().substring(11, 19)} $line');
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

  Future<void> _persistCache() => _cache.save(_projects);

  Future<void> _scan() async {
    if (!_settings.hasRoots) {
      _log('Укажите директории с проектами в настройках');
      return;
    }
    final cancellation = ScanCancellation();
    final cachedByPath = {for (final p in _projects) p.path: p};
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
    _log('Сканирование: ${_settings.projectsRoots.join(', ')}…');
    try {
      final projects = await _scanner.scan(
        roots: _settings.projectsRoots,
        recursive: _settings.recursiveScan,
        settings: _settings,
        cached: cachedByPath,
        cacheTtl: _settings.scanCacheTtlMinutes > 0
            ? Duration(minutes: _settings.scanCacheTtlMinutes)
            : null,
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
        _lastScanFinishedAt = DateTime.now();
        _scanProgress = ScanProgress(
          total: projects.length,
          completed: projects.length,
          successCount: projects.where((p) => !p.scanFailed).length,
          errorCount: projects.where((p) => p.scanFailed).length,
          projects: projects,
        );
      });
      await _persistCache();
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
      await _persistCache();
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
    await _persistCache();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _openSettings() async {
    final previousRoots = _settings.projectsRoots;
    final updated = await showModalBottomSheet<AppSettings>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SettingsSheet(initial: _settings),
    );
    if (updated == null) return;
    await updated.save();
    setState(() => _settings = updated);
    appThemeMode.value = updated.themeMode;
    _setupSchedule();

    final rootsChanged =
        !_listEquals(previousRoots, updated.projectsRoots);
    if (updated.hasRoots && (rootsChanged || _projects.isEmpty)) {
      await _scan();
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _cycleTheme() async {
    final next = switch (_settings.themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    final updated = _settings.copyWith(themeMode: next);
    setState(() => _settings = updated);
    appThemeMode.value = next;
    await updated.save();
  }

  Future<void> _toggleView() async {
    final next = _settings.viewMode == RepoViewMode.list
        ? RepoViewMode.tree
        : RepoViewMode.list;
    final updated = _settings.copyWith(viewMode: next);
    setState(() => _settings = updated);
    await updated.save();
  }

  void _toggleSelectAll(bool? value) {
    final select = value ?? false;
    setState(() {
      _projects = _projects.map((p) => p.copyWith(selected: select)).toList();
    });
  }

  void _selectOnlyWithUpdates() {
    if (_busy) return;
    setState(() {
      _projects = _projects
          .map((p) => p.copyWith(selected: p.hasRemoteUpdates))
          .toList();
    });
    final count = _projects.where((p) => p.hasRemoteUpdates).length;
    _log('Выбрано репозиториев с обновлениями: $count');
  }

  void _toggleProject(String path, bool? value) {
    final index = _projects.indexWhere((p) => p.path == path);
    if (index < 0) return;
    setState(() {
      _projects[index] = _projects[index].copyWith(selected: value ?? false);
    });
  }

  void _pull(GitProject p) => _runOnProjects(
        [p],
        'Pull',
        (x) => _ops.pullDefaultBranch(x, _settings, log: _log),
      );

  void _push(GitProject p) => _runOnProjects(
        [p],
        'Push',
        (x) => _ops.pushToGitlab(x, _settings, log: _log),
      );

  void _sync(GitProject p) => _runOnProjects(
        [p],
        'Sync',
        (x) => _ops.syncProject(x, _settings, log: _log),
      );

  Future<void> _createShortcut(GitProject p) async {
    try {
      final path = await RepoShortcut.createDesktopShortcut(p.path);
      _log('[${p.name}] ярлык создан: $path');
      _toast('Ярлык создан на Рабочем столе');
    } catch (e) {
      _log('[${p.name}] не удалось создать ярлык: $e');
      _toast('Не удалось создать ярлык: $e');
    }
  }

  Future<void> _revealInFinder(GitProject p) async {
    try {
      await RepoShortcut.revealInFinder(p.path);
    } catch (e) {
      _log('[${p.name}] Finder: $e');
    }
  }

  Future<void> _openInTerminal(GitProject p) async {
    try {
      await RepoShortcut.openInTerminal(p.path);
    } catch (e) {
      _log('[${p.name}] Terminal: $e');
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = _selectedProjects.length;
    final isScanning = _scanning;
    final groups = groupProjects(_projects);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repo Sync Hub'),
        actions: [
          IconButton(
            tooltip: _settings.viewMode == RepoViewMode.list
                ? 'Показать деревом'
                : 'Показать построчно',
            onPressed: _toggleView,
            icon: Icon(_settings.viewMode == RepoViewMode.list
                ? Icons.account_tree
                : Icons.view_list),
          ),
          IconButton(
            tooltip: 'Тема: ${_themeLabel(_settings.themeMode)} '
                '(нажмите для переключения)',
            onPressed: _cycleTheme,
            icon: Icon(switch (_settings.themeMode) {
              ThemeMode.system => Icons.brightness_auto,
              ThemeMode.light => Icons.light_mode,
              ThemeMode.dark => Icons.dark_mode,
            }),
          ),
          IconButton(
            tooltip: 'Настройки: директории, приёмник, тема, расписание',
            onPressed: _busy ? null : _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          _Toolbar(
            settings: _settings,
            busy: _busy,
            isScanning: isScanning,
            scanProgress: _scanProgress,
            selectedCount: selectedCount,
            totalCount: _projects.length,
            lastScanAt: _lastScanFinishedAt,
            onScan: _scan,
            onPull: () => _runOnProjects(
              _selectedProjects,
              'Pull main/master',
              (p) => _ops.pullDefaultBranch(p, _settings, log: _log),
            ),
            onPush: () => _runOnProjects(
              _selectedProjects,
              'Push',
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
                      !_settings.hasRoots
                          ? 'Выберите директории с git-проектами в настройках'
                          : 'Репозитории не найдены — запустите сканирование',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  )
                : _ProjectListArea(
                    groups: groups,
                    projects: _projects,
                    viewMode: _settings.viewMode,
                    busy: _busy,
                    onToggleAll: _toggleSelectAll,
                    onSelectWithUpdates: _selectOnlyWithUpdates,
                    onToggle: _toggleProject,
                    onPull: _pull,
                    onPush: _push,
                    onSync: _sync,
                    onShortcut: _createShortcut,
                    onReveal: _revealInFinder,
                    onTerminal: _openInTerminal,
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

String _themeLabel(ThemeMode m) => switch (m) {
      ThemeMode.system => 'системная',
      ThemeMode.light => 'светлая',
      ThemeMode.dark => 'тёмная',
    };

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.settings,
    required this.busy,
    required this.isScanning,
    required this.scanProgress,
    required this.selectedCount,
    required this.totalCount,
    required this.lastScanAt,
    required this.onScan,
    required this.onPull,
    required this.onPush,
    required this.onSync,
    required this.onStopScan,
    required this.onSettings,
  });

  final AppSettings settings;
  final bool busy;
  final bool isScanning;
  final ScanProgress? scanProgress;
  final int selectedCount;
  final int totalCount;
  final DateTime? lastScanAt;
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
    final roots = settings.projectsRoots;

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
                    roots.isEmpty
                        ? 'Директории не заданы'
                        : roots.length == 1
                            ? roots.first
                            : '${roots.length} директорий: ${roots.join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (lastScanAt != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Tooltip(
                      message: 'Последнее сканирование',
                      child: Text(
                        'скан: ${Format.relativeDate(lastScanAt)}',
                        style: theme.textTheme.bodySmall,
                      ),
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
                Tooltip(
                  message: 'Открыть настройки и выбрать директории сканирования',
                  child: FilledButton.tonalIcon(
                    onPressed: busy ? null : onSettings,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Директории'),
                  ),
                ),
                Tooltip(
                  message: isScanning
                      ? 'Прервать текущее сканирование'
                      : 'Просканировать директории и обновить статусы репозиториев',
                  child: FilledButton.tonalIcon(
                    onPressed:
                        isScanning ? onStopScan : (busy ? null : onScan),
                    icon: Icon(isScanning ? Icons.stop_rounded : Icons.refresh),
                    label: Text(isScanning ? 'Остановить' : 'Сканировать'),
                  ),
                ),
                Tooltip(
                  message:
                      'Стянуть обновления (pull main/master) для выбранных репозиториев',
                  child: FilledButton.icon(
                    onPressed: busy || selectedCount == 0 ? null : onPull,
                    icon: const Icon(Icons.download),
                    label: const Text('Pull'),
                  ),
                ),
                Tooltip(
                  message:
                      'Отправить (push) выбранные репозитории в систему-приёмник',
                  child: FilledButton.icon(
                    onPressed: busy || selectedCount == 0 ? null : onPush,
                    icon: const Icon(Icons.upload),
                    label: const Text('Push'),
                  ),
                ),
                Tooltip(
                  message: 'Синхронизировать: pull, затем push для выбранных',
                  child: FilledButton.icon(
                    onPressed: busy || selectedCount == 0 ? null : onSync,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectListArea extends StatefulWidget {
  const _ProjectListArea({
    required this.groups,
    required this.projects,
    required this.viewMode,
    required this.busy,
    required this.onToggleAll,
    required this.onSelectWithUpdates,
    required this.onToggle,
    required this.onPull,
    required this.onPush,
    required this.onSync,
    required this.onShortcut,
    required this.onReveal,
    required this.onTerminal,
  });

  final List<RepoGroup> groups;
  final List<GitProject> projects;
  final RepoViewMode viewMode;
  final bool busy;
  final void Function(bool? value) onToggleAll;
  final VoidCallback onSelectWithUpdates;
  final void Function(String path, bool? value) onToggle;
  final void Function(GitProject project) onPull;
  final void Function(GitProject project) onPush;
  final void Function(GitProject project) onSync;
  final void Function(GitProject project) onShortcut;
  final void Function(GitProject project) onReveal;
  final void Function(GitProject project) onTerminal;

  @override
  State<_ProjectListArea> createState() => _ProjectListAreaState();
}

class _ProjectListAreaState extends State<_ProjectListArea> {
  /// Свёрнутые группы (по имени) — их репозитории скрыты в построчном виде.
  final Set<String> _collapsed = {};

  void _toggleGroup(String name) {
    setState(() {
      if (!_collapsed.remove(name)) _collapsed.add(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final projects = widget.projects;
    final allSelected = projects.isNotEmpty && projects.every((p) => p.selected);
    final updatesCount = projects.where((p) => p.hasRemoteUpdates).length;

    Widget tile(GitProject p) => _ProjectTile(
          project: p,
          busy: widget.busy,
          onChanged: (v) => widget.onToggle(p.path, v),
          onPull: () => widget.onPull(p),
          onPush: () => widget.onPush(p),
          onSync: () => widget.onSync(p),
          onShortcut: () => widget.onShortcut(p),
          onReveal: () => widget.onReveal(p),
          onTerminal: () => widget.onTerminal(p),
        );

    return Column(
      children: [
        CheckboxListTile(
          value: allSelected,
          tristate: true,
          onChanged: widget.busy ? null : widget.onToggleAll,
          title: Row(
            children: [
              const Text('Выбрать все'),
              if (updatesCount > 0) ...[
                const SizedBox(width: 12),
                _Badge(
                  label: 'обновлений: $updatesCount',
                  icon: Icons.system_update_alt,
                  color: Colors.orange.shade700,
                  tooltip: 'Выбрать только репозитории с обновлениями',
                  onTap: widget.busy ? null : widget.onSelectWithUpdates,
                ),
              ],
            ],
          ),
          dense: true,
        ),
        const Divider(height: 1),
        Expanded(
          child: widget.viewMode == RepoViewMode.tree
              ? ListView(
                  children: [
                    for (final g in widget.groups)
                      _TreeGroup(group: g, tileBuilder: tile),
                  ],
                )
              : ListView(
                  children: [
                    for (final g in widget.groups) ...[
                      _GroupHeader(
                        group: g,
                        collapsed: _collapsed.contains(g.name),
                        onTap: () => _toggleGroup(g.name),
                      ),
                      if (!_collapsed.contains(g.name))
                        for (final p in g.projects) tile(p),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _TreeGroup extends StatelessWidget {
  const _TreeGroup({required this.group, required this.tileBuilder});

  final RepoGroup group;
  final Widget Function(GitProject) tileBuilder;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      leading: Icon(
        group.isErrorGroup ? Icons.error_outline : Icons.folder_outlined,
        color: group.isErrorGroup ? Theme.of(context).colorScheme.error : null,
      ),
      title: _GroupTitle(group: group),
      childrenPadding: const EdgeInsets.only(left: 8),
      children: [for (final p in group.projects) tileBuilder(p)],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.group,
    required this.collapsed,
    required this.onTap,
  });

  final RepoGroup group;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: group.isErrorGroup
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.35)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Tooltip(
        message: collapsed
            ? 'Развернуть группу'
            : 'Свернуть группу — скрыть репозитории',
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  collapsed ? Icons.chevron_right : Icons.expand_more,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Icon(
                  group.isErrorGroup ? Icons.error_outline : Icons.folder,
                  size: 18,
                  color: group.isErrorGroup ? theme.colorScheme.error : null,
                ),
                const SizedBox(width: 8),
                Expanded(child: _GroupTitle(group: group)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({required this.group});

  final RepoGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Flexible(
          child: Text(
            group.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: group.isErrorGroup ? theme.colorScheme.error : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text('${group.projects.length}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        if (group.updatesCount > 0) ...[
          const SizedBox(width: 8),
          _Badge(
            label: '↓${group.updatesCount}',
            icon: Icons.arrow_downward_rounded,
            color: Colors.orange.shade700,
            tooltip: 'Доступно обновлений в группе',
          ),
        ],
        if (group.abandonedCount > 0) ...[
          const SizedBox(width: 8),
          _Badge(
            label: 'заброшено: ${group.abandonedCount}',
            icon: Icons.hourglass_bottom,
            color: Colors.blueGrey,
            tooltip: 'Репозитории без обновлений больше года',
          ),
        ],
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
    required this.onShortcut,
    required this.onReveal,
    required this.onTerminal,
  });

  final GitProject project;
  final bool busy;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onPull;
  final VoidCallback onPush;
  final VoidCallback onSync;
  final VoidCallback onShortcut;
  final VoidCallback onReveal;
  final VoidCallback onTerminal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
              value: project.selected, onChanged: busy ? null : onChanged),
          _StatusDot(status: project.status, scanFailed: project.scanFailed),
          const SizedBox(width: 8),
          // Название + подпись
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        project.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (project.hasRemoteUpdates) ...[
                      const SizedBox(width: 8),
                      _Badge(
                        label: project.remoteBehindCount > 0
                            ? '+${project.remoteBehindCount}'
                            : 'обновления',
                        icon: Icons.arrow_downward_rounded,
                        color: theme.colorScheme.tertiary,
                        tooltip: 'Доступны обновления на remote',
                      ),
                    ],
                    if (project.updatesReceived) ...[
                      const SizedBox(width: 8),
                      _Badge(
                        label: 'получены',
                        icon: Icons.check_circle_outline,
                        color: Colors.green.shade700,
                        tooltip: 'Обновления успешно подтянуты',
                      ),
                    ],
                    if (project.isAbandoned) ...[
                      const SizedBox(width: 8),
                      _Badge(
                        label: 'заброшен',
                        icon: Icons.hourglass_bottom,
                        color: Colors.blueGrey,
                        tooltip: 'Не обновлялся больше года',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${project.currentBranch ?? '?'} · default '
                  '${project.defaultBranch ?? '?'}'
                  '${project.isDirty ? ' · dirty' : ''}',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                if (project.scanError != null)
                  Text(
                    project.scanError!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (project.lastMessage != null)
                  Text(
                    project.lastMessage!,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Столбцы-метрики
          _MetricCell(
            icon: Icons.commit,
            value: Format.count(project.commitCount),
            tooltip: 'Количество коммитов',
          ),
          _MetricCell(
            icon: Icons.sd_storage_outlined,
            value: Format.bytes(project.sizeBytes),
            tooltip: 'Размер репозитория на диске',
          ),
          _MetricCell(
            icon: Icons.download_done,
            value: Format.relativeDate(project.lastPulledAt),
            tooltip: project.lastPulledAt == null
                ? 'Обновления через приложение ещё не стягивались'
                : 'Последнее стягивание: '
                    '${Format.dateTime(project.lastPulledAt)}',
            width: 110,
          ),
          _ProjectMenu(
            busy: busy,
            onPull: onPull,
            onPush: onPush,
            onSync: onSync,
            onShortcut: onShortcut,
            onReveal: onReveal,
            onTerminal: onTerminal,
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.icon,
    required this.value,
    required this.tooltip,
    this.width = 84,
  });

  final IconData icon;
  final String value;
  final String tooltip;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: width,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectMenu extends StatelessWidget {
  const _ProjectMenu({
    required this.busy,
    required this.onPull,
    required this.onPush,
    required this.onSync,
    required this.onShortcut,
    required this.onReveal,
    required this.onTerminal,
  });

  final bool busy;
  final VoidCallback onPull;
  final VoidCallback onPush;
  final VoidCallback onSync;
  final VoidCallback onShortcut;
  final VoidCallback onReveal;
  final VoidCallback onTerminal;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      enabled: !busy,
      tooltip: 'Действия с репозиторием',
      onSelected: (value) {
        switch (value) {
          case 'pull':
            onPull();
          case 'push':
            onPush();
          case 'sync':
            onSync();
          case 'shortcut':
            onShortcut();
          case 'finder':
            onReveal();
          case 'terminal':
            onTerminal();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'pull', child: Text('Pull main/master')),
        PopupMenuItem(value: 'push', child: Text('Push в приёмник')),
        PopupMenuItem(value: 'sync', child: Text('Sync (pull + push)')),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'shortcut',
          child: Text('Создать ярлык на Рабочем столе'),
        ),
        PopupMenuItem(value: 'finder', child: Text('Показать в Finder')),
        PopupMenuItem(value: 'terminal', child: Text('Открыть в Терминале')),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
    this.tooltip,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String? tooltip;
  final VoidCallback? onTap;

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
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    Widget child = chip;
    if (onTap != null) {
      child = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: chip,
        ),
      );
    }
    if (tooltip == null) return child;
    return Tooltip(message: tooltip!, child: child);
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
              TextButton(
                  onPressed: logs.isEmpty ? null : onClear,
                  child: const Text('Очистить')),
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
