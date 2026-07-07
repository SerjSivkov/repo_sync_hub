import 'dart:io';

import '../models/git_project.dart';

typedef LogSink = void Function(String line);

/// Запуск git-команд в репозитории.
class GitRunner {
  Future<GitCommandResult> run(
    String repoPath,
    List<String> args, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final result = await Process.run(
      'git',
      args,
      workingDirectory: repoPath,
      runInShell: false,
    ).timeout(timeout);

    return GitCommandResult(
      exitCode: result.exitCode,
      stdout: '${result.stdout}',
      stderr: '${result.stderr}',
    );
  }

  Future<String?> currentBranch(String repoPath) async {
    final r = await run(repoPath, ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (!r.ok) return null;
    final branch = r.stdout.trim();
    return branch == 'HEAD' ? null : branch;
  }

  Future<String?> defaultBranch(String repoPath) async {
    for (final candidate in ['main', 'master']) {
      final local = await run(
        repoPath,
        ['show-ref', '--verify', '--quiet', 'refs/heads/$candidate'],
      );
      if (local.ok) return candidate;
    }

    final remote = await _primaryRemote(repoPath);
    if (remote != null) {
      for (final candidate in ['main', 'master']) {
        final remoteRef = await run(
          repoPath,
          ['show-ref', '--verify', '--quiet', 'refs/remotes/$remote/$candidate'],
        );
        if (remoteRef.ok) return candidate;
      }
      final sym = await run(repoPath, ['symbolic-ref', 'refs/remotes/$remote/HEAD']);
      if (sym.ok) {
        final parts = sym.stdout.trim().split('/');
        if (parts.length >= 4) return parts.last;
      }
    }
    return null;
  }

  Future<String?> primaryRemote(String repoPath) => _primaryRemote(repoPath);

  Future<String?> _primaryRemote(String repoPath) async {
    final remotes = await listRemotes(repoPath);
    if (remotes.containsKey('origin')) return 'origin';
    return remotes.keys.isEmpty ? null : remotes.keys.first;
  }

  Future<Map<String, String>> listRemotes(String repoPath) async {
    final r = await run(repoPath, ['remote', '-v']);
    if (!r.ok) return {};

    final map = <String, String>{};
    for (final line in r.stdout.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final name = parts[0];
      final url = parts[1];
      if (!map.containsKey(name)) map[name] = url;
    }
    return map;
  }

  Future<bool> isDirty(String repoPath) async {
    final r = await run(repoPath, ['status', '--porcelain']);
    return r.ok && r.stdout.trim().isNotEmpty;
  }

  /// Всего коммитов в репозитории (по всем достижимым из HEAD).
  Future<int?> commitCount(String repoPath) async {
    final r = await run(repoPath, ['rev-list', '--count', 'HEAD']);
    if (!r.ok) return null;
    return int.tryParse(r.stdout.trim());
  }

  /// Дата последнего коммита (committer date HEAD).
  Future<DateTime?> lastCommitDate(String repoPath) async {
    final r = await run(repoPath, ['log', '-1', '--format=%ct']);
    if (!r.ok) return null;
    final seconds = int.tryParse(r.stdout.trim());
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  /// Размер рабочей копии в байтах (через `du -sk`).
  Future<int?> repoSizeBytes(String repoPath) async {
    try {
      final result = await Process.run('du', ['-sk', repoPath])
          .timeout(const Duration(seconds: 30));
      if (result.exitCode != 0) return null;
      final out = '${result.stdout}'.trim();
      final kb = int.tryParse(out.split(RegExp(r'\s+')).first);
      return kb == null ? null : kb * 1024;
    } catch (_) {
      return null;
    }
  }

  Future<(int, int)> aheadBehind(String repoPath) async {
    final branch = await currentBranch(repoPath);
    if (branch == null) return (0, 0);

    final upstream = await run(repoPath, ['rev-parse', '--abbrev-ref', '$branch@{upstream}']);
    if (!upstream.ok) return (0, 0);

    final upstreamName = upstream.stdout.trim();
    final counts = await run(
      repoPath,
      ['rev-list', '--left-right', '--count', '$branch...$upstreamName'],
    );
    if (!counts.ok) return (0, 0);

    final parts = counts.stdout.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return (0, 0);
    return (int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
  }

  /// Сколько коммитов на remote/defaultBranch нет локально.
  Future<int> commitsBehindRemote(
    String repoPath, {
    required String branch,
    required String remote,
  }) async {
    final remoteRef = await run(
      repoPath,
      ['show-ref', '--verify', '--quiet', 'refs/remotes/$remote/$branch'],
    );
    if (!remoteRef.ok) return 0;

    final localRef = await run(
      repoPath,
      ['show-ref', '--verify', '--quiet', 'refs/heads/$branch'],
    );
    if (!localRef.ok) {
      final countOnlyRemote = await run(
        repoPath,
        ['rev-list', '--count', 'refs/remotes/$remote/$branch'],
      );
      if (!countOnlyRemote.ok) return 0;
      return int.tryParse(countOnlyRemote.stdout.trim()) ?? 0;
    }

    final behind = await run(
      repoPath,
      ['rev-list', '--count', '$branch..$remote/$branch'],
    );
    if (!behind.ok) return 0;
    return int.tryParse(behind.stdout.trim()) ?? 0;
  }

  /// Клонирует репозиторий [url] в директорию [destDir].
  /// Если задан [directoryName], клонирует в подпапку с этим именем.
  /// Возвращает результат git-команды (клонирование может быть долгим).
  Future<GitCommandResult> clone({
    required String destDir,
    required String url,
    String? directoryName,
    LogSink? log,
    Duration timeout = const Duration(minutes: 30),
  }) async {
    final args = ['clone', url, ?directoryName];
    log?.call('  git clone $url');
    final result = await Process.run(
      'git',
      args,
      workingDirectory: destDir,
      runInShell: false,
    ).timeout(timeout);

    return GitCommandResult(
      exitCode: result.exitCode,
      stdout: '${result.stdout}',
      stderr: '${result.stderr}',
    );
  }

  Future<void> ensureRemote({
    required String repoPath,
    required String remoteName,
    required String remoteUrl,
    LogSink? log,
  }) async {
    final remotes = await listRemotes(repoPath);
    if (remotes.containsKey(remoteName)) {
      if (remotes[remoteName] == remoteUrl) return;
      log?.call('  remote set-url $remoteName');
      await run(repoPath, ['remote', 'set-url', remoteName, remoteUrl]);
      return;
    }
    log?.call('  remote add $remoteName');
    await run(repoPath, ['remote', 'add', remoteName, remoteUrl]);
  }
}
