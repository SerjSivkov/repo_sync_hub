import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/app_settings.dart';
import '../models/git_project.dart';
import 'git_runner.dart';

/// Поиск git-репозиториев в заданной директории.
class GitScanner {
  GitScanner(this._runner);

  final GitRunner _runner;

  Future<List<GitProject>> scan({
    required String rootPath,
    required bool recursive,
    required AppSettings settings,
  }) async {
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw StateError('Директория не найдена: $rootPath');
    }

    final repoPaths = <String>{};
    await _collectRepoPaths(root, recursive: recursive, sink: repoPaths);

    final projects = <GitProject>[];
    for (final repoPath in repoPaths.toList()..sort()) {
      final info = await _inspectRepo(repoPath, settings);
      if (info != null) projects.add(info);
    }
    return projects;
  }

  Future<void> _collectRepoPaths(
    Directory dir, {
    required bool recursive,
    required Set<String> sink,
  }) async {
    if (await _isGitRepo(dir.path)) {
      sink.add(p.normalize(dir.path));
      return;
    }

    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (_skipDir(name)) continue;

      if (await _isGitRepo(entity.path)) {
        sink.add(p.normalize(entity.path));
        continue;
      }

      if (recursive) {
        await _collectRepoPaths(entity, recursive: true, sink: sink);
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

  Future<GitProject?> _inspectRepo(String path, AppSettings settings) async {
    final name = p.basename(path);
    final branch = await _runner.currentBranch(path);
    final defaultBranch = await _runner.defaultBranch(path);
    final dirty = await _runner.isDirty(path);
    final aheadBehind = await _runner.aheadBehind(path);
    final remotes = await _runner.listRemotes(path);
    final gitlabRemote = _pickGitlabRemote(remotes, settings);
    final origin = remotes[settings.gitlabRemoteName] ?? remotes['origin'];

    return GitProject(
      name: name,
      path: path,
      currentBranch: branch,
      defaultBranch: defaultBranch,
      isDirty: dirty,
      ahead: aheadBehind.$1,
      behind: aheadBehind.$2,
      gitlabRemote: gitlabRemote,
      originUrl: origin,
      lastMessage: _statusLine(branch, defaultBranch, dirty, aheadBehind),
    );
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
  ) {
    final parts = <String>[];
    if (branch != null) parts.add('ветка $branch');
    if (defaultBranch != null && branch != defaultBranch) {
      parts.add('default $defaultBranch');
    }
    if (dirty) parts.add('есть изменения');
    if (aheadBehind.$1 > 0) parts.add('+${aheadBehind.$1}');
    if (aheadBehind.$2 > 0) parts.add('-${aheadBehind.$2}');
    return parts.isEmpty ? 'ok' : parts.join(', ');
  }
}
