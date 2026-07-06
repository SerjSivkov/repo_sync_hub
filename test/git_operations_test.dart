import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sync_hub/core/app_settings.dart';
import 'package:repo_sync_hub/models/git_project.dart';
import 'package:repo_sync_hub/models/scan_progress.dart';
import 'package:repo_sync_hub/services/git_operations.dart';
import 'package:repo_sync_hub/services/git_runner.dart';

void main() {
  group('AppSettings', () {
    test('gitlabBaseUrl adds https when host has no scheme', () {
      final settings = AppSettings(gitlabHost: 'gitlab.example.com');
      expect(settings.gitlabBaseUrl, 'https://gitlab.example.com');
    });

    test('gitlabBaseUrl keeps explicit scheme', () {
      final settings = AppSettings(gitlabHost: 'http://gitlab.local');
      expect(settings.gitlabBaseUrl, 'http://gitlab.local');
    });
  });

  group('GitOperations.buildGitlabUrl', () {
    final ops = GitOperations(GitRunner());

    test('builds group slug url', () {
      final settings = AppSettings(
        gitlabHost: 'gitlab.com',
        gitlabGroup: 'mobile',
      );
      expect(
        ops.buildGitlabUrl(settings, 'term_conn_vault'),
        'https://gitlab.com/mobile/term_conn_vault.git',
      );
    });

    test('embeds oauth token when provided', () {
      final settings = AppSettings(
        gitlabHost: 'https://gitlab.com',
        gitlabGroup: 'mobile',
        gitlabToken: 'secret-token',
      );
      expect(
        ops.buildGitlabUrl(settings, 'gdebenz'),
        'https://oauth2:secret-token@gitlab.com/mobile/gdebenz.git',
      );
    });
  });

  group('GitProject', () {
    test('hasRemoteUpdates when remoteBehindCount > 0', () {
      final project = GitProject(name: 'a', path: '/a', remoteBehindCount: 3);
      expect(project.hasRemoteUpdates, isTrue);
    });
  });

  group('ScanProgress', () {
    test('fraction reflects completed over total', () {
      const progress = ScanProgress(total: 10, completed: 4, successCount: 3, errorCount: 1);
      expect(progress.fraction, 0.4);
      expect(progress.isDone, isFalse);
    });

    test('isDone when cancelled', () {
      const progress = ScanProgress(
        total: 10,
        completed: 3,
        successCount: 2,
        errorCount: 1,
        cancelled: true,
      );
      expect(progress.isDone, isTrue);
    });
  });

  group('GitCommandResult.pulledUpdates', () {
    test('detects fast-forward pull', () {
      const result = GitCommandResult(
        exitCode: 0,
        stdout: 'Updating abc..def\nFast-forward',
        stderr: '',
      );
      expect(result.pulledUpdates, isTrue);
    });

    test('detects already up to date', () {
      const result = GitCommandResult(
        exitCode: 0,
        stdout: 'Already up to date.',
        stderr: '',
      );
      expect(result.pulledUpdates, isFalse);
    });
  });
}
