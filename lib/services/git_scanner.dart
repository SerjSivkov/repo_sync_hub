import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/app_settings.dart';
import '../models/git_project.dart';
import '../models/scan_progress.dart';
import 'git_runner.dart';
import 'scan_cancellation.dart';

typedef ScanProgressCallback = void Function(ScanProgress progress);

/// Поиск git-репозиториев в заданной директории.
class GitScanner {
  GitScanner(this._runner);

  final GitRunner _runner;

  Future<List<GitProject>> scan({
    required String rootPath,
    required bool recursive,
    required AppSettings settings,
    ScanProgressCallback? onProgress,
    ScanCancellation? cancellation,
  }) async {
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw StateError('Директория не найдена: $rootPath');
    }

    final repoPaths = <String>{};
    await _collectRepoPaths(
      root,
      recursive: recursive,
      sink: repoPaths,
      cancellation: cancellation,
    );
    if (cancellation?.isCancelled ?? false) {
      throw ScanCancelledException();
    }

    final sortedPaths = repoPaths.toList()..sort();

    final projects = <GitProject>[];
    var successCount = 0;
    var errorCount = 0;
    var cancelled = false;

    void emit(int completed, String? currentName, {bool stopped = false}) {
      onProgress?.call(
        ScanProgress(
          total: sortedPaths.length,
          completed: completed,
          successCount: successCount,
          errorCount: errorCount,
          currentName: currentName,
          projects: List.unmodifiable(projects),
          cancelled: stopped,
        ),
      );
    }

    emit(0, sortedPaths.isNotEmpty ? p.basename(sortedPaths.first) : null);

    for (var i = 0; i < sortedPaths.length; i++) {
      if (cancellation?.isCancelled ?? false) {
        cancelled = true;
        break;
      }

      final repoPath = sortedPaths[i];
      final name = p.basename(repoPath);
      emit(i, name);

      try {
        final info = await _inspectRepo(repoPath, settings, cancellation: cancellation);
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
            path: repoPath,
            scanError: '$e',
            status: GitProjectStatus.error,
            lastMessage: 'Ошибка сканирования',
          ),
        );
      }
    }

    emit(cancelled ? projects.length : sortedPaths.length, null, stopped: cancelled);

    if (cancelled) {
      throw ScanCancelledException();
    }

    return projects;
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

  Future<GitProject?> _inspectRepo(
    String path,
    AppSettings settings, {
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
      final gitlabRemote = _pickGitlabRemote(remotes, settings);
      final origin = remotes[settings.gitlabRemoteName] ?? remotes['origin'];

      var remoteBehind = 0;
      if (defaultBranch != null) {
        final remote = gitlabRemote ?? await _runner.primaryRemote(path);
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
        currentBranch: branch,
        defaultBranch: defaultBranch,
        isDirty: dirty,
        ahead: aheadBehind.$1,
        behind: aheadBehind.$2,
        remoteBehindCount: remoteBehind,
        gitlabRemote: gitlabRemote,
        originUrl: origin,
        lastMessage: _statusLine(branch, defaultBranch, dirty, aheadBehind, remoteBehind),
        status: GitProjectStatus.idle,
      );
    } on ScanCancelledException {
      rethrow;
    } catch (e) {
      return GitProject(
        name: name,
        path: path,
        scanError: '$e',
        status: GitProjectStatus.error,
        lastMessage: 'Ошибка: $e',
      );
    }
  }

  String? _pickGitlabRemote(Map<String, String> remotes, AppSettings settings) {
    final host = settings.gitlabHost.replaceAll(RegExp(r'^https?://'), '');
    for (final entry in remotes.entries) {
      if (entry.value.contains(host)) return entry.key;
    }
    final preferred = settings.gitlabRemoteName;
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
