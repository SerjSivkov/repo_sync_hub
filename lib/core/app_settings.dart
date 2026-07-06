import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Настройки приложения (персистентные).
class AppSettings {
  AppSettings({
    this.projectsRoot = '',
    this.gitlabHost = 'gitlab.com',
    this.gitlabGroup = 'mobile',
    this.gitlabToken = '',
    this.gitlabRemoteName = 'origin',
    this.recursiveScan = false,
    this.autoStashBeforePull = true,
    this.fetchBeforePull = true,
    this.pushTags = false,
  });

  static const _keyRoot = 'projects_root';
  static const _keyHost = 'gitlab_host';
  static const _keyGroup = 'gitlab_group';
  static const _keyToken = 'gitlab_token';
  static const _keyRemote = 'gitlab_remote_name';
  static const _keyRecursive = 'recursive_scan';
  static const _keyAutoStash = 'auto_stash';
  static const _keyFetch = 'fetch_before_pull';
  static const _keyPushTags = 'push_tags';

  final String projectsRoot;
  final String gitlabHost;
  final String gitlabGroup;
  final String gitlabToken;
  final String gitlabRemoteName;
  final bool recursiveScan;
  final bool autoStashBeforePull;
  final bool fetchBeforePull;
  final bool pushTags;

  String get gitlabBaseUrl {
    final host = gitlabHost.trim();
    if (host.startsWith('http://') || host.startsWith('https://')) {
      return host.replaceAll(RegExp(r'/+$'), '');
    }
    return 'https://$host';
  }

  AppSettings copyWith({
    String? projectsRoot,
    String? gitlabHost,
    String? gitlabGroup,
    String? gitlabToken,
    String? gitlabRemoteName,
    bool? recursiveScan,
    bool? autoStashBeforePull,
    bool? fetchBeforePull,
    bool? pushTags,
  }) {
    return AppSettings(
      projectsRoot: projectsRoot ?? this.projectsRoot,
      gitlabHost: gitlabHost ?? this.gitlabHost,
      gitlabGroup: gitlabGroup ?? this.gitlabGroup,
      gitlabToken: gitlabToken ?? this.gitlabToken,
      gitlabRemoteName: gitlabRemoteName ?? this.gitlabRemoteName,
      recursiveScan: recursiveScan ?? this.recursiveScan,
      autoStashBeforePull: autoStashBeforePull ?? this.autoStashBeforePull,
      fetchBeforePull: fetchBeforePull ?? this.fetchBeforePull,
      pushTags: pushTags ?? this.pushTags,
    );
  }

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      projectsRoot: prefs.getString(_keyRoot) ?? '',
      gitlabHost: prefs.getString(_keyHost) ?? 'gitlab.com',
      gitlabGroup: prefs.getString(_keyGroup) ?? 'mobile',
      gitlabToken: prefs.getString(_keyToken) ?? '',
      gitlabRemoteName: prefs.getString(_keyRemote) ?? 'origin',
      recursiveScan: prefs.getBool(_keyRecursive) ?? false,
      autoStashBeforePull: prefs.getBool(_keyAutoStash) ?? true,
      fetchBeforePull: prefs.getBool(_keyFetch) ?? true,
      pushTags: prefs.getBool(_keyPushTags) ?? false,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRoot, projectsRoot);
    await prefs.setString(_keyHost, gitlabHost);
    await prefs.setString(_keyGroup, gitlabGroup);
    await prefs.setString(_keyToken, gitlabToken);
    await prefs.setString(_keyRemote, gitlabRemoteName);
    await prefs.setBool(_keyRecursive, recursiveScan);
    await prefs.setBool(_keyAutoStash, autoStashBeforePull);
    await prefs.setBool(_keyFetch, fetchBeforePull);
    await prefs.setBool(_keyPushTags, pushTags);
  }

  Map<String, dynamic> toJson() => {
        'projectsRoot': projectsRoot,
        'gitlabHost': gitlabHost,
        'gitlabGroup': gitlabGroup,
        'gitlabRemoteName': gitlabRemoteName,
        'recursiveScan': recursiveScan,
        'autoStashBeforePull': autoStashBeforePull,
        'fetchBeforePull': fetchBeforePull,
        'pushTags': pushTags,
      };

  @override
  String toString() => jsonEncode(toJson());
}
