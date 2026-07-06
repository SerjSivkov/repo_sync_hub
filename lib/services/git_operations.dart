import '../core/app_settings.dart';
import '../models/git_project.dart';
import 'git_runner.dart';
import 'git_scanner.dart';

typedef LogSink = void Function(String line);

/// Операции pull / push / sync для репозиториев.
class GitOperations {
  GitOperations(this._runner);

  final GitRunner _runner;

  String buildGitlabUrl(AppSettings settings, String repoName) {
    final base = settings.gitlabBaseUrl;
    final group = settings.gitlabGroup.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    final token = settings.gitlabToken.trim();

    var url = '$base/$group/$repoName.git';
    if (token.isNotEmpty) {
      final uri = Uri.parse(url);
      url = '${uri.scheme}://oauth2:$token@${uri.host}${uri.path}';
    }
    return url;
  }

  Future<GitProject> pullDefaultBranch(
    GitProject project,
    AppSettings settings, {
    LogSink? log,
  }) async {
    final defaultBranch = project.defaultBranch;
    if (defaultBranch == null) {
      return project.copyWith(
        status: GitProjectStatus.warning,
        lastMessage: 'Не найдена ветка main/master',
      );
    }

    log?.call('[${project.name}] pull $defaultBranch');
    var working = project.copyWith(status: GitProjectStatus.pulling);

    if (settings.fetchBeforePull) {
      log?.call('  git fetch --all --prune');
      final fetch = await _runner.run(project.path, ['fetch', '--all', '--prune']);
      if (!fetch.ok) {
        return working.copyWith(
          status: GitProjectStatus.error,
          lastMessage: fetch.combined,
        );
      }
    }

    final current = await _runner.currentBranch(project.path);
    if (current != defaultBranch) {
      if (working.isDirty && settings.autoStashBeforePull) {
        log?.call('  git stash push -u');
        await _runner.run(
          project.path,
          ['stash', 'push', '-u', '-m', 'repo_sync_hub auto-stash'],
        );
      }
      log?.call('  git checkout $defaultBranch');
      final checkout = await _runner.run(project.path, ['checkout', defaultBranch]);
      if (!checkout.ok) {
        return working.copyWith(
          status: GitProjectStatus.error,
          lastMessage: checkout.combined,
        );
      }
    }

    log?.call('  git pull --ff-only');
    final pull = await _runner.run(
      project.path,
      ['pull', '--ff-only', 'origin', defaultBranch],
    );
    if (!pull.ok) {
      final fallback = await _runner.run(project.path, ['pull', '--ff-only']);
      if (!fallback.ok) {
        return working.copyWith(
          status: GitProjectStatus.error,
          lastMessage: fallback.combined,
        );
      }
    }

    return _refreshAfter(project, settings, GitProjectStatus.success, 'pull ok');
  }

  Future<GitProject> pushToGitlab(
    GitProject project,
    AppSettings settings, {
    LogSink? log,
  }) async {
    log?.call('[${project.name}] push → GitLab');
    var working = project.copyWith(status: GitProjectStatus.pushing);

    final remoteName = settings.gitlabRemoteName;
    final remotes = await _runner.listRemotes(project.path);
    final host = settings.gitlabHost.replaceAll(RegExp(r'^https?://'), '');
    final hasGitlabRemote = remotes.entries.any(
      (e) => e.key == remoteName && e.value.contains(host),
    );

    if (!hasGitlabRemote) {
      final remoteUrl = buildGitlabUrl(settings, project.name);
      await _runner.ensureRemote(
        repoPath: project.path,
        remoteName: remoteName,
        remoteUrl: remoteUrl,
        log: log,
      );
    } else {
      log?.call('  remote $remoteName уже указывает на GitLab');
    }

    final branch = project.defaultBranch ?? await _runner.defaultBranch(project.path);
    if (branch == null) {
      return working.copyWith(
        status: GitProjectStatus.warning,
        lastMessage: 'Нет ветки main/master для push',
      );
    }

    final current = await _runner.currentBranch(project.path);
    if (current != branch) {
      log?.call('  git checkout $branch');
      final checkout = await _runner.run(project.path, ['checkout', branch]);
      if (!checkout.ok) {
        return working.copyWith(
          status: GitProjectStatus.error,
          lastMessage: checkout.combined,
        );
      }
    }

    log?.call('  git push $remoteName $branch');
    final push = await _runner.run(project.path, ['push', remoteName, branch]);
    if (!push.ok) {
      return working.copyWith(
        status: GitProjectStatus.error,
        lastMessage: push.combined,
      );
    }

    if (settings.pushTags) {
      log?.call('  git push $remoteName --tags');
      await _runner.run(project.path, ['push', remoteName, '--tags']);
    }

    return _refreshAfter(project, settings, GitProjectStatus.success, 'push ok');
  }

  Future<GitProject> syncProject(
    GitProject project,
    AppSettings settings, {
    LogSink? log,
  }) async {
    log?.call('[${project.name}] sync (pull + push)');
    final pulled = await pullDefaultBranch(
      project.copyWith(status: GitProjectStatus.syncing),
      settings,
      log: log,
    );
    if (pulled.status == GitProjectStatus.error) return pulled;
    return pushToGitlab(pulled, settings, log: log);
  }

  Future<GitProject> _refreshAfter(
    GitProject project,
    AppSettings settings,
    GitProjectStatus status,
    String message,
  ) async {
    final scanner = GitScanner(_runner);
    final refreshed = await scanner.scan(
      rootPath: project.path,
      recursive: false,
      settings: settings,
    );
    if (refreshed.isEmpty) {
      return project.copyWith(status: status, lastMessage: message);
    }
    return refreshed.first.copyWith(status: status, lastMessage: message);
  }
}
