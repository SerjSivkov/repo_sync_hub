import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sync_hub/core/app_settings.dart';
import 'package:repo_sync_hub/models/git_project.dart';
import 'package:repo_sync_hub/models/repo_group.dart';
import 'package:repo_sync_hub/models/scan_progress.dart';
import 'package:repo_sync_hub/services/git_operations.dart';
import 'package:repo_sync_hub/services/git_runner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppSettings', () {
    test('remoteBaseUrl adds https when host has no scheme', () {
      final settings = AppSettings(remoteHost: 'gitlab.example.com');
      expect(settings.remoteBaseUrl, 'https://gitlab.example.com');
    });

    test('remoteBaseUrl keeps explicit scheme', () {
      final settings = AppSettings(remoteHost: 'http://gitlab.local');
      expect(settings.remoteBaseUrl, 'http://gitlab.local');
    });

    test('scanConcurrency defaults to 4', () {
      expect(AppSettings().scanConcurrency, 4);
    });

    test('scanConcurrency round-trips through SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final original = AppSettings(scanConcurrency: 8);
      await original.save();
      final loaded = await AppSettings.load();
      expect(loaded.scanConcurrency, 8);
    });

    test('languageCode defaults to ru', () {
      expect(AppSettings().languageCode, 'ru');
    });

    test('languageCode round-trips through SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final original = AppSettings(languageCode: 'en');
      await original.save();
      final loaded = await AppSettings.load();
      expect(loaded.languageCode, 'en');
    });

    test('languageCode falls back to ru for unknown values', () async {
      SharedPreferences.setMockInitialValues({'language_code': 'fr'});
      final loaded = await AppSettings.load();
      expect(loaded.languageCode, 'ru');
    });
  });

  group('GitOperations.buildRemoteUrl', () {
    final ops = GitOperations(GitRunner());

    test('builds group slug url', () {
      final settings = AppSettings(
        remoteHost: 'gitlab.com',
        remoteGroup: 'mobile',
      );
      expect(
        ops.buildRemoteUrl(settings, 'term_conn_vault'),
        'https://gitlab.com/mobile/term_conn_vault.git',
      );
    });

    test('embeds oauth token when provided', () {
      final settings = AppSettings(
        remoteHost: 'https://gitlab.com',
        remoteGroup: 'mobile',
        remoteToken: 'secret-token',
      );
      expect(
        ops.buildRemoteUrl(settings, 'gdebenz'),
        'https://oauth2:secret-token@gitlab.com/mobile/gdebenz.git',
      );
    });
  });

  group('groupProjects', () {
    test('abandoned repos sink to the bottom of the group', () {
      final fresh = GitProject(
        name: 'fresh',
        path: '/root/app/fresh',
        scanRoot: '/root',
        lastPulledAt: DateTime.now(),
      );
      final old = GitProject(
        name: 'old',
        path: '/root/app/old',
        scanRoot: '/root',
        lastCommitAt: DateTime.now().subtract(const Duration(days: 400)),
      );
      final groups = groupProjects([old, fresh]);
      expect(groups.single.name, 'app');
      expect(groups.single.projects.map((p) => p.name), ['fresh', 'old']);
    });

    test('error repos form the first group', () {
      final ok = GitProject(name: 'ok', path: '/root/a/ok', scanRoot: '/root');
      final bad = GitProject(
        name: 'bad',
        path: '/root/b/bad',
        scanRoot: '/root',
        scanError: 'boom',
      );
      final groups = groupProjects([ok, bad]);
      expect(groups.first.isErrorGroup, isTrue);
      expect(groups.first.projects.single.name, 'bad');
    });
  });

  group('GitProject', () {
    test('hasRemoteUpdates when remoteBehindCount > 0', () {
      final project = GitProject(name: 'a', path: '/a', remoteBehindCount: 3);
      expect(project.hasRemoteUpdates, isTrue);
    });
  });

  group('gitRemoteToWebUrl', () {
    test('keeps https url and strips .git suffix', () {
      expect(
        gitRemoteToWebUrl('https://github.com/mobile/app.git'),
        'https://github.com/mobile/app',
      );
    });

    test('keeps http scheme', () {
      expect(
        gitRemoteToWebUrl('http://git.local/mobile/app'),
        'http://git.local/mobile/app',
      );
    });

    test('drops userinfo (token) from https url', () {
      expect(
        gitRemoteToWebUrl('https://oauth2:secret@gitlab.com/mobile/app.git'),
        'https://gitlab.com/mobile/app',
      );
    });

    test('converts scp-like ssh url to https', () {
      expect(
        gitRemoteToWebUrl('git@github.com:mobile/app.git'),
        'https://github.com/mobile/app',
      );
    });

    test('converts ssh:// url and drops port', () {
      expect(
        gitRemoteToWebUrl('ssh://git@gitlab.com:22/mobile/app.git'),
        'https://gitlab.com/mobile/app',
      );
    });

    test('converts git:// url', () {
      expect(
        gitRemoteToWebUrl('git://github.com/mobile/app.git'),
        'https://github.com/mobile/app',
      );
    });

    test('preserves non-default https port', () {
      expect(
        gitRemoteToWebUrl('https://git.local:8443/mobile/app.git'),
        'https://git.local:8443/mobile/app',
      );
    });

    test('returns null for null/empty/unparseable', () {
      expect(gitRemoteToWebUrl(null), isNull);
      expect(gitRemoteToWebUrl(''), isNull);
      expect(gitRemoteToWebUrl('   '), isNull);
    });

    test('remoteWebUrl getter uses originUrl', () {
      final project = GitProject(
        name: 'app',
        path: '/app',
        originUrl: 'git@github.com:mobile/app.git',
      );
      expect(project.remoteWebUrl, 'https://github.com/mobile/app');
    });
  });

  group('gitRepoNameFromUrl', () {
    test('extracts name from https url with .git suffix', () {
      expect(gitRepoNameFromUrl('https://github.com/mobile/app.git'), 'app');
    });

    test('extracts name from https url without suffix', () {
      expect(gitRepoNameFromUrl('https://github.com/mobile/app'), 'app');
    });

    test('extracts name from scp-like ssh url', () {
      expect(gitRepoNameFromUrl('git@github.com:mobile/app.git'), 'app');
    });

    test('extracts name from ssh:// url', () {
      expect(gitRepoNameFromUrl('ssh://git@gitlab.com:22/mobile/app.git'),
          'app');
    });

    test('ignores trailing slash', () {
      expect(gitRepoNameFromUrl('https://github.com/mobile/app/'), 'app');
    });

    test('handles dots in the repository name', () {
      expect(gitRepoNameFromUrl('https://github.com/mobile/my.app.git'),
          'my.app');
    });

    test('returns null for null/empty', () {
      expect(gitRepoNameFromUrl(null), isNull);
      expect(gitRepoNameFromUrl('   '), isNull);
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
