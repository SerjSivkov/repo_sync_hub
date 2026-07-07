import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/app_settings.dart';
import '../models/git_project.dart';
import '../models/scan_progress.dart';
import 'git_runner.dart';
import 'scan_cancellation.dart';

typedef ScanProgressCallback = void Function(ScanProgress progress);

class _RepoRef {
  const _RepoRef(this.path, this.root);
  final String path;
  final String root;
}

/// Поиск git-репозиториев в заданных директориях.
class GitScanner {
  GitScanner(this._runner);

  final GitRunner _runner;

  /// Сканирует несколько корневых директорий. Если репозиторий есть в [cached]
  /// и его последнее сканирование свежее [cacheTtl], git не опрашивается —
  /// данные берутся из кэша (чтобы не сканировать при каждом входе).
  Future<List<GitProject>> scan({
    required List<String> roots,
    required bool recursive,
    required AppSettings settings,
    Map<String, GitProject> cached = const {},
    Duration? cacheTtl,
    ScanProgressCallback? onProgress,
    ScanCancellation? cancellation,
  }) async {
    final refs = <_RepoRef>[];
    final seen = <String>{};
    for (final rawRoot in roots) {
      final root = p.normalize(rawRoot.trim());
      if (root.isEmpty) continue;
      final dir = Directory(root);
      if (!await dir.exists()) continue;

      final paths = <String>{};
      await _collectRepoPaths(
        dir,
        recursive: recursive,
        sink: paths,
        cancellation: cancellation,
      );
      if (cancellation?.isCancelled ?? false) throw ScanCancelledException();
      for (final path in paths) {
        if (seen.add(path)) refs.add(_RepoRef(path, root));
      }
    }

    refs.sort((a, b) => a.path.compareTo(b.path));

    final projects = <GitProject>[];
    var successCount = 0;
    var errorCount = 0;
    var cancelled = false;

    void emit(int completed, String? currentName, {bool stopped = false}) {
      onProgress?.call(
        ScanProgress(
          total: refs.length,
          completed: completed,
          successCount: successCount,
          errorCount: errorCount,
          currentName: currentName,
          projects: List.unmodifiable(projects),
          cancelled: stopped,
        ),
      );
    }

    emit(0, refs.isNotEmpty ? p.basename(refs.first.path) : null);

    for (var i = 0; i < refs.length; i++) {
      if (cancellation?.isCancelled ?? false) {
        cancelled = true;
        break;
      }

      final ref = refs[i];
      final name = p.basename(ref.path);
      emit(i, name);

      try {
        final prev = cached[ref.path];
        final GitProject? info;
        if (_isFresh(prev, cacheTtl)) {
          info = prev!.copyWith(
            scanRoot: ref.root,
            status: GitProjectStatus.idle,
          );
        } else {
          info = await inspectRepo(
            ref.path,
            settings,
            scanRoot: ref.root,
            previous: prev,
            cancellation: cancellation,
          );
        }
        if (cancellation?.isCancelled ?? false) {
          cancelled = true;
          break;
        }
        if (info != null) {
          projects.add(info);
          if (info.scanFailed) {
            errorCount++;
          } else {
            successCount++;
          }
        }
      } catch (e) {
        if (e is ScanCancelledException) {
          cancelled = true;
          break;
        }
        errorCount++;
        projects.add(
          GitProject(
            name: name,
            path: ref.path,
            scanRoot: ref.root,
            scanError: '$e',
            status: GitProjectStatus.error,
            lastMessage: 'Ошибка сканирования',
          ),
        );
      }
    }

    emit(cancelled ? projects.length : refs.length, null, stopped: cancelled);

    if (cancelled) {
      throw ScanCancelledException();
    }

    return projects;
  }

  bool _isFresh(GitProject? prev, Duration? ttl) {
    if (prev == null || ttl == null || prev.scanFailed) return false;
    final scanned = prev.lastScannedAt;
    if (scanned == null) return false;
    return DateTime.now().difference(scanned) < ttl;
  }

  Future<void> _collectRepoPaths(
    Directory dir, {
    required bool recursive,
    required Set<String> sink,
    ScanCancellation? cancellation,
  }) async {
    if (cancellation?.isCancelled ?? false) return;

    if (await _isGitRepo(dir.path)) {
      sink.add(p.normalize(dir.path));
      return;
    }

    await for (final entity in dir.list(followLinks: false)) {
      if (cancellation?.isCancelled ?? false) return;
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (_skipDir(name)) continue;

      if (await _isGitRepo(entity.path)) {
        sink.add(p.normalize(entity.path));
        continue;
      }

      if (recursive) {
        await _collectRepoPaths(
          entity,
          recursive: true,
          sink: sink,
          cancellation: cancellation,
        );
      }
    }
  }

  bool _skipDir(String name) {
    if (name.startsWith('.')) return true;
    const skip = {'node_modules', 'build', 'vendor', 'Pods', '.dart_tool'};
    return skip.contains(name);
  }

  Future<bool> _isGitRepo(String path) async {
    return Directory(p.join(path, '.git')).exists();
  }

  /// Опрашивает один репозиторий и собирает метрики (ветки, размер, коммиты…).
  Future<GitProject?> inspectRepo(
    String path,
    AppSettings settings, {
    String? scanRoot,
    GitProject? previous,
    ScanCancellation? cancellation,
  }) async {
    final name = p.basename(path);

    try {
      if (cancellation?.isCancelled ?? false) throw ScanCancelledException();

      final branch = await _runner.currentBranch(path);
      if (cancellation?.isCancelled ?? false) throw ScanCancelledException();

      final defaultBranch = await _runner.defaultBranch(path);
      final dirty = await _runner.isDirty(path);

      if (settings.fetchBeforePull) {
        await _runner.run(path, ['fetch', '--all', '--prune']);
        if (cancellation?.isCancelled ?? false) throw ScanCancelledException();
      }

      final aheadBehind = await _runner.aheadBehind(path);
      final remotes = await _runner.listRemotes(path);
      final targetRemote = _pickTargetRemote(remotes, settings);
      final origin = remotes[settings.remoteName] ?? remotes['origin'];

      final commitCount = await _runner.commitCount(path);
      final lastCommitAt = await _runner.lastCommitDate(path);
      final sizeBytes = await _runner.repoSizeBytes(path);

      var remoteBehind = 0;
      if (defaultBranch != null) {
        final remote = targetRemote ?? await _runner.primaryRemote(path);
        if (remote != null) {
          remoteBehind = await _runner.commitsBehindRemote(
            path,
            branch: defaultBranch,
            remote: remote,
          );
        }
      }

      return GitProject(
        name: name,
        path: path,
        scanRoot: scanRoot ?? previous?.scanRoot,
        currentBranch: branch,
        defaultBranch: defaultBranch,
        isDirty: dirty,
        ahead: aheadBehind.$1,
        behind: aheadBehind.$2,
        remoteBehindCount: remoteBehind,
        targetRemote: targetRemote,
        originUrl: origin,
        commitCount: commitCount,
        sizeBytes: sizeBytes,
        lastCommitAt: lastCommitAt,
        lastPulledAt: previous?.lastPulledAt,
        lastScannedAt: DateTime.now(),
        lastMessage: _statusLine(
          branch,
          defaultBranch,
          dirty,
          aheadBehind,
          remoteBehind,
        ),
        status: GitProjectStatus.idle,
        selected: previous?.selected ?? true,
      );
    } on ScanCancelledException {
      rethrow;
    } catch (e) {
      return GitProject(
        name: name,
        path: path,
        scanRoot: scanRoot ?? previous?.scanRoot,
        lastScannedAt: DateTime.now(),
        scanError: '$e',
        status: GitProjectStatus.error,
        lastMessage: 'Ошибка: $e',
      );
    }
  }

  String? _pickTargetRemote(Map<String, String> remotes, AppSettings settings) {
    final host = settings.remoteHost.replaceAll(RegExp(r'^https?://'), '');
    for (final entry in remotes.entries) {
      if (host.isNotEmpty && entry.value.contains(host)) return entry.key;
    }
    final preferred = settings.remoteName;
    if (remotes.containsKey(preferred)) return preferred;
    if (remotes.containsKey('gitlab')) return 'gitlab';
    if (remotes.containsKey('origin')) return 'origin';
    return remotes.keys.isEmpty ? null : remotes.keys.first;
  }

  String _statusLine(
    String? branch,
    String? defaultBranch,
    bool dirty,
    (int, int) aheadBehind,
    int remoteBehind,
  ) {
    final parts = <String>[];
    if (branch != null) parts.add('ветка $branch');
    if (defaultBranch != null && branch != defaultBranch) {
      parts.add('default $defaultBranch');
    }
    if (dirty) parts.add('есть изменения');
    if (remoteBehind > 0) parts.add('обновлений: $remoteBehind');
    if (aheadBehind.$1 > 0) parts.add('+${aheadBehind.$1}');
    if (aheadBehind.$2 > 0) parts.add('-${aheadBehind.$2}');
    return parts.isEmpty ? 'ok' : parts.join(', ');
  }
}
