import 'package:flutter_test/flutter_test.dart';
import 'package:repo_sync_hub/core/app_settings.dart';
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
}
