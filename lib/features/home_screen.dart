import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as pathlib;

import '../core/app_settings.dart';
import '../core/format.dart';
import '../core/locale_controller.dart';
import '../core/theme_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/git_project.dart';
import '../models/repo_group.dart';
import '../models/scan_progress.dart';
import '../services/git_operations.dart';
import '../services/git_runner.dart';
import '../services/git_scanner.dart';
import '../services/repo_cache.dart';
import '../services/repo_shortcut.dart';
import '../services/scan_cancellation.dart';
import 'about_screen.dart';
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
        _log(l10n.logCacheLoaded(cached.length));
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
      _log(l10n.logScheduledScan);
      _scan();
    });
    _log(l10n.logScheduleEnabled(_settings.scheduleIntervalMinutes));
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
    _log(l10n.logStoppingScan);
  }

  Future<void> _persistCache() => _cache.save(_projects);

  Future<void> _scan() async {
    if (!_settings.hasRoots) {
      _log(l10n.logNoRoots);
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
    _log(l10n.logScanStart(_settings.projectsRoots.join(', ')));
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
      final ok = projects.where((p) => !p.scanFailed).length;
      final errors = projects.where((p) => p.scanFailed).length;
      _log(
        withUpdates > 0
            ? l10n.logScanDoneUpdates(
                projects.length, ok, errors, withUpdates)
            : l10n.logScanDone(projects.length, ok, errors),
      );
    } on ScanCancelledException {
      if (!mounted) return;
      final progress = _scanProgress;
      final scanned = _projects.length;
      final total = progress?.total ?? scanned;
      _log(
        l10n.logScanStopped(
          scanned,
          total,
          progress?.successCount ?? 0,
          progress?.errorCount ?? 0,
        ),
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
      _log(l10n.logScanError('$e'));
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
      _log(l10n.logNoSelection);
      return;
    }
    setState(() {
      _busy = true;
      _scanProgress = null;
    });
    _log(l10n.logOperationHeader(label, targets.length));
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
        _log(l10n.logProjectMessage(
          project.name,
          updated.lastMessage ?? updated.status.name,
        ));
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _projects[index] = _projects[index].copyWith(
            status: GitProjectStatus.error,
            lastMessage: '$e',
          );
        });
        _log(l10n.logProjectError(project.name, '$e'));
      }
    }
    await _persistCache();
    if (mounted) setState(() => _busy = false);
  }

  void _openAbout() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
    );
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

  Future<void> _cycleLanguage() async {
    final next = _settings.languageCode == 'ru' ? 'en' : 'ru';
    final updated = _settings.copyWith(languageCode: next);
    setState(() => _settings = updated);
    appLocale.value = Locale(next);
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
    _log(l10n.logSelectedWithUpdates(count));
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
        l10n.labelPull,
        (x) => _ops.pullDefaultBranch(x, _settings, log: _log),
      );

  void _push(GitProject p) => _runOnProjects(
        [p],
        l10n.labelPush,
        (x) => _ops.pushToGitlab(x, _settings, log: _log),
      );

  void _sync(GitProject p) => _runOnProjects(
        [p],
        l10n.labelSync,
        (x) => _ops.syncProject(x, _settings, log: _log),
      );

  Future<void> _createShortcut(GitProject p) async {
    try {
      final path = await RepoShortcut.createDesktopShortcut(p.path);
      _log(l10n.logShortcutCreated(p.name, path));
      _toast(l10n.snackShortcutCreated);
    } catch (e) {
      _log(l10n.logShortcutFailed(p.name, '$e'));
      _toast(l10n.snackShortcutFailed('$e'));
    }
  }

  Future<void> _revealInFinder(GitProject p) async {
    try {
      await RepoShortcut.revealInFinder(p.path);
    } catch (e) {
      _log(l10n.logFinderError(p.name, '$e'));
    }
  }

  Future<void> _openInTerminal(GitProject p) async {
    try {
      await RepoShortcut.openInTerminal(p.path);
    } catch (e) {
      _log(l10n.logTerminalError(p.name, '$e'));
    }
  }

  Future<void> _deleteProject(GitProject p) async {
    final l = l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.deleteDialogBody(p.name)),
            const SizedBox(height: 12),
            Text(
              l.deleteDialogPath(p.path),
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (p.isDirty) ...[
              const SizedBox(height: 12),
              Text(
                l.deleteDialogDirtyWarning,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.error,
                    ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _log(l10n.logDeleting(p.name, p.path));
    try {
      await RepoShortcut.moveToTrash(p.path);
      if (!mounted) return;
      setState(() => _projects.removeWhere((x) => x.path == p.path));
      await _persistCache();
      _log(l10n.logDeleted(p.name));
      _toast(l10n.snackDeleted);
    } catch (e) {
      _log(l10n.logDeleteFailed(p.name, '$e'));
      _toast(l10n.snackDeleteFailed('$e'));
    }
  }

  Future<void> _addRepository() async {
    if (!_settings.hasRoots) {
      _toast(l10n.cloneDialogNoRoots);
      _log(l10n.logNoRoots);
      return;
    }
    final result = await showDialog<_CloneRequest>(
      context: context,
      builder: (ctx) => _CloneDialog(roots: _settings.projectsRoots),
    );
    if (result == null) return;
    await _clone(result.url, result.targetDir);
  }

  Future<void> _clone(String url, String targetDir) async {
    final name = gitRepoNameFromUrl(url);
    if (name == null) {
      _toast(l10n.snackCloneInvalidUrl);
      return;
    }
    final destPath = pathlib.join(targetDir, name);
    if (await FileSystemEntity.type(destPath) !=
        FileSystemEntityType.notFound) {
      _toast(l10n.snackCloneExists(name));
      return;
    }

    setState(() => _busy = true);
    _log(l10n.logCloneStart(url, targetDir));
    try {
      final res = await _runner.clone(
        destDir: targetDir,
        url: url,
        directoryName: name,
        log: _log,
      );
      if (!res.ok) {
        _log(l10n.logCloneFailed(res.combined));
        _toast(l10n.snackCloneFailed(res.combined));
        return;
      }
      final project = await _scanner.inspectRepo(
        destPath,
        _settings,
        scanRoot: targetDir,
      );
      if (!mounted) return;
      if (project != null) {
        setState(() {
          _projects.removeWhere((x) => x.path == project.path);
          _projects.add(project);
          _projects.sort((a, b) => a.path.compareTo(b.path));
        });
        await _persistCache();
      }
      _log(l10n.logCloneDone(name));
      _toast(l10n.snackCloneDone);
    } catch (e) {
      _log(l10n.logCloneFailed('$e'));
      _toast(l10n.snackCloneFailed('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRemote(GitProject p) async {
    final url = p.remoteWebUrl;
    if (url == null) {
      _log(l10n.logNoRemoteLink(p.name));
      _toast(l10n.snackNoRemote);
      return;
    }
    try {
      await RepoShortcut.openUrl(url);
      _log(l10n.logOpenedRemote(p.name, url));
    } catch (e) {
      _log(l10n.logOpenRemoteFailed(p.name, '$e'));
      _toast(l10n.snackOpenRemoteFailed('$e'));
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
    final l10n = AppLocalizations.of(context);
    final selectedCount = _selectedProjects.length;
    final isScanning = _scanning;
    final groups = groupProjects(_projects);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.tooltipLanguageCycle(_languageLabel(l10n)),
            onPressed: _cycleLanguage,
            icon: const Icon(Icons.language),
          ),
          IconButton(
            tooltip: _settings.viewMode == RepoViewMode.list
                ? l10n.tooltipShowTree
                : l10n.tooltipShowList,
            onPressed: _toggleView,
            icon: Icon(_settings.viewMode == RepoViewMode.list
                ? Icons.account_tree
                : Icons.view_list),
          ),
          IconButton(
            tooltip: l10n.tooltipThemeCycle(_themeLabel(l10n, _settings.themeMode)),
            onPressed: _cycleTheme,
            icon: Icon(switch (_settings.themeMode) {
              ThemeMode.system => Icons.brightness_auto,
              ThemeMode.light => Icons.light_mode,
              ThemeMode.dark => Icons.dark_mode,
            }),
          ),
          IconButton(
            tooltip: l10n.tooltipSettings,
            onPressed: _busy ? null : _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'О приложении',
            onPressed: _openAbout,
            icon: const Icon(Icons.info_outline_rounded),
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
              l10n.labelPullMasterMain,
              (p) => _ops.pullDefaultBranch(p, _settings, log: _log),
            ),
            onPush: () => _runOnProjects(
              _selectedProjects,
              l10n.labelPush,
              (p) => _ops.pushToGitlab(p, _settings, log: _log),
            ),
            onSync: () => _runOnProjects(
              _selectedProjects,
              l10n.labelSync,
              (p) => _ops.syncProject(p, _settings, log: _log),
            ),
            onStopScan: _stopScan,
            onSettings: _openSettings,
            onAddRepo: _addRepository,
          ),
          Expanded(
            flex: 3,
            child: _projects.isEmpty && !isScanning
                ? Center(
                    child: Text(
                      !_settings.hasRoots
                          ? l10n.emptyNoRoots
                          : l10n.emptyNotFound,
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
                    onOpenRemote: _openRemote,
                    onDelete: _deleteProject,
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

String _themeLabel(AppLocalizations l10n, ThemeMode m) => switch (m) {
      ThemeMode.system => l10n.themeSystem,
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
    };

String _languageLabel(AppLocalizations l10n) =>
    appLocale.value.languageCode == 'en'
        ? l10n.languageEnglish
        : l10n.languageRussian;

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
    required this.onAddRepo,
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
  final VoidCallback onAddRepo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
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
                        ? l10n.rootsNone
                        : roots.length == 1
                            ? roots.first
                            : l10n.rootsMultiple(roots.length, roots.join(', ')),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.tooltipAddRepo,
                  visualDensity: VisualDensity.compact,
                  onPressed: busy || !settings.hasRoots ? null : onAddRepo,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                ),
                if (lastScanAt != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Tooltip(
                      message: l10n.tooltipLastScan,
                      child: Text(
                        l10n.scanRelative(Format.relativeDate(l10n, lastScanAt)),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                Text(l10n.counter(selectedCount, totalCount)),
              ],
            ),
            if (isScanning && progress != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      progress.cancelled
                          ? l10n.progressStopping
                          : progress.currentName != null
                              ? l10n.progressScanningName(progress.currentName!)
                              : progress.total == 0
                                  ? l10n.progressSearching
                                  : l10n.progressScanning,
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
                l10n.progressOkErrors(progress.successCount, progress.errorCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (progress != null && progress.isDone && !busy) ...[
              const SizedBox(height: 8),
              Text(
                progress.cancelled
                    ? l10n.doneStopped(
                        progress.successCount,
                        progress.errorCount,
                        progress.completed,
                        progress.total,
                      )
                    : l10n.doneScan(progress.successCount, progress.errorCount),
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
                  message: l10n.tooltipDirectories,
                  child: FilledButton.tonalIcon(
                    onPressed: busy ? null : onSettings,
                    icon: const Icon(Icons.folder_open),
                    label: Text(l10n.actionDirectories),
                  ),
                ),
                Tooltip(
                  message: isScanning ? l10n.tooltipScanStop : l10n.tooltipScanStart,
                  child: FilledButton.tonalIcon(
                    onPressed:
                        isScanning ? onStopScan : (busy ? null : onScan),
                    icon: Icon(isScanning ? Icons.stop_rounded : Icons.refresh),
                    label: Text(isScanning ? l10n.actionStop : l10n.actionScan),
                  ),
                ),
                Tooltip(
                  message: l10n.tooltipPull,
                  child: FilledButton.icon(
                    onPressed: busy || selectedCount == 0 ? null : onPull,
                    icon: const Icon(Icons.download),
                    label: Text(l10n.actionPull),
                  ),
                ),
                Tooltip(
                  message: l10n.tooltipPush,
                  child: FilledButton.icon(
                    onPressed: busy || selectedCount == 0 ? null : onPush,
                    icon: const Icon(Icons.upload),
                    label: Text(l10n.actionPush),
                  ),
                ),
                Tooltip(
                  message: l10n.tooltipSync,
                  child: FilledButton.icon(
                    onPressed: busy || selectedCount == 0 ? null : onSync,
                    icon: const Icon(Icons.sync),
                    label: Text(l10n.actionSync),
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
    required this.onOpenRemote,
    required this.onDelete,
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
  final void Function(GitProject project) onOpenRemote;
  final void Function(GitProject project) onDelete;

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
          onOpenRemote: () => widget.onOpenRemote(p),
          onDelete: () => widget.onDelete(p),
        );

    return Column(
      children: [
        CheckboxListTile(
          value: allSelected,
          tristate: true,
          onChanged: widget.busy ? null : widget.onToggleAll,
          title: Row(
            children: [
              Text(AppLocalizations.of(context).selectAll),
              if (updatesCount > 0) ...[
                const SizedBox(width: 12),
                _Badge(
                  label: AppLocalizations.of(context).updatesBadgeCount(updatesCount),
                  icon: Icons.system_update_alt,
                  color: Colors.orange.shade700,
                  tooltip: AppLocalizations.of(context).selectWithUpdatesTooltip,
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
            ? AppLocalizations.of(context).tooltipExpandGroup
            : AppLocalizations.of(context).tooltipCollapseGroup,
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
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Flexible(
          child: Text(
            localizedGroupName(l10n, group.name),
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
            label: l10n.groupUpdatesBadge(group.updatesCount),
            icon: Icons.arrow_downward_rounded,
            color: Colors.orange.shade700,
            tooltip: l10n.tooltipGroupUpdates,
          ),
        ],
        if (group.abandonedCount > 0) ...[
          const SizedBox(width: 8),
          _Badge(
            label: l10n.groupAbandonedBadge(group.abandonedCount),
            icon: Icons.hourglass_bottom,
            color: Colors.blueGrey,
            tooltip: l10n.tooltipGroupAbandoned,
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
    required this.onOpenRemote,
    required this.onDelete,
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
  final VoidCallback onOpenRemote;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final unknown = l10n.unknownBranch;

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
                            : l10n.badgeUpdatesShort,
                        icon: Icons.arrow_downward_rounded,
                        color: theme.colorScheme.tertiary,
                        tooltip: l10n.tooltipHasUpdates,
                      ),
                    ],
                    if (project.updatesReceived) ...[
                      const SizedBox(width: 8),
                      _Badge(
                        label: l10n.badgeReceived,
                        icon: Icons.check_circle_outline,
                        color: Colors.green.shade700,
                        tooltip: l10n.tooltipReceived,
                      ),
                    ],
                    if (project.isAbandoned) ...[
                      const SizedBox(width: 8),
                      _Badge(
                        label: l10n.labelAbandoned,
                        icon: Icons.hourglass_bottom,
                        color: Colors.blueGrey,
                        tooltip: l10n.tooltipAbandoned,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.branchLine(project.currentBranch ?? unknown, project.defaultBranch ?? unknown)}'
                  '${project.isDirty ? ' · ${l10n.labelDirty}' : ''}',
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
            tooltip: l10n.tooltipCommitCount,
          ),
          _MetricCell(
            icon: Icons.sd_storage_outlined,
            value: Format.bytes(l10n, project.sizeBytes),
            tooltip: l10n.tooltipRepoSize,
          ),
          _MetricCell(
            icon: Icons.download_done,
            value: Format.relativeDate(l10n, project.lastPulledAt),
            tooltip: project.lastPulledAt == null
                ? l10n.tooltipLastPullNever
                : l10n.tooltipLastPull(Format.dateTime(project.lastPulledAt)),
            width: 110,
          ),
          IconButton(
            tooltip: project.remoteWebUrl != null
                ? l10n.tooltipOpenRemote(project.remoteWebUrl!)
                : l10n.tooltipNoRemote,
            onPressed:
                busy || project.remoteWebUrl == null ? null : onOpenRemote,
            icon: const Icon(Icons.open_in_browser),
          ),
          _ProjectMenu(
            busy: busy,
            hasRemoteUrl: project.remoteWebUrl != null,
            onPull: onPull,
            onPush: onPush,
            onSync: onSync,
            onShortcut: onShortcut,
            onReveal: onReveal,
            onTerminal: onTerminal,
            onOpenRemote: onOpenRemote,
            onDelete: onDelete,
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
    required this.hasRemoteUrl,
    required this.onPull,
    required this.onPush,
    required this.onSync,
    required this.onShortcut,
    required this.onReveal,
    required this.onTerminal,
    required this.onOpenRemote,
    required this.onDelete,
  });

  final bool busy;
  final bool hasRemoteUrl;
  final VoidCallback onPull;
  final VoidCallback onPush;
  final VoidCallback onSync;
  final VoidCallback onShortcut;
  final VoidCallback onReveal;
  final VoidCallback onTerminal;
  final VoidCallback onOpenRemote;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      enabled: !busy,
      tooltip: l10n.menuActions,
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
          case 'remote':
            onOpenRemote();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'pull', child: Text(l10n.menuPull)),
        PopupMenuItem(value: 'push', child: Text(l10n.menuPush)),
        PopupMenuItem(value: 'sync', child: Text(l10n.menuSync)),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'remote',
          enabled: hasRemoteUrl,
          child: Text(l10n.menuOpenRemote),
        ),
        PopupMenuItem(value: 'shortcut', child: Text(l10n.menuShortcut)),
        PopupMenuItem(value: 'finder', child: Text(l10n.menuFinder)),
        PopupMenuItem(value: 'terminal', child: Text(l10n.menuTerminal)),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            l10n.menuDelete,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Text(l10n.logTitle, style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              TextButton(
                  onPressed: logs.isEmpty ? null : onClear,
                  child: Text(l10n.logClear)),
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

/// Результат диалога клонирования: URL и выбранная директория назначения.
class _CloneRequest {
  const _CloneRequest(this.url, this.targetDir);
  final String url;
  final String targetDir;
}

class _CloneDialog extends StatefulWidget {
  const _CloneDialog({required this.roots});

  final List<String> roots;

  @override
  State<_CloneDialog> createState() => _CloneDialogState();
}

class _CloneDialogState extends State<_CloneDialog> {
  final _urlCtrl = TextEditingController();
  late String _target = widget.roots.first;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    Navigator.pop(context, _CloneRequest(url, _target));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.cloneDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _urlCtrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.cloneDialogUrlLabel,
              hintText: l10n.cloneDialogUrlHint,
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (widget.roots.length > 1) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _target,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.cloneDialogTargetLabel,
              ),
              items: [
                for (final r in widget.roots)
                  DropdownMenuItem(
                    value: r,
                    child: Text(r, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _target = v ?? _target),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.actionClone),
        ),
      ],
    );
  }
}
