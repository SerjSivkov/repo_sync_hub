import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Режим отображения списка репозиториев.
enum RepoViewMode { list, tree }

/// Настройки приложения (персистентные).
class AppSettings {
  AppSettings({
    this.projectsRoots = const [],
    this.remoteHost = 'gitlab.com',
    this.remoteGroup = 'mobile',
    this.remoteToken = '',
    this.remoteName = 'origin',
    this.recursiveScan = false,
    this.autoStashBeforePull = true,
    this.fetchBeforePull = true,
    this.pushTags = false,
    this.themeMode = ThemeMode.system,
    this.viewMode = RepoViewMode.list,
    this.autoScanOnStartup = false,
    this.scanCacheTtlMinutes = 60,
    this.scanConcurrency = 4,
    this.scheduleEnabled = false,
    this.scheduleIntervalMinutes = 60,
  });

  static const _keyRoots = 'projects_roots';
  static const _keyRootLegacy = 'projects_root';
  static const _keyHost = 'remote_host';
  static const _keyHostLegacy = 'gitlab_host';
  static const _keyGroup = 'remote_group';
  static const _keyGroupLegacy = 'gitlab_group';
  static const _keyToken = 'remote_token';
  static const _keyTokenLegacy = 'gitlab_token';
  static const _keyRemote = 'remote_name';
  static const _keyRemoteLegacy = 'gitlab_remote_name';
  static const _keyRecursive = 'recursive_scan';
  static const _keyAutoStash = 'auto_stash';
  static const _keyFetch = 'fetch_before_pull';
  static const _keyPushTags = 'push_tags';
  static const _keyTheme = 'theme_mode';
  static const _keyView = 'view_mode';
  static const _keyAutoScan = 'auto_scan_startup';
  static const _keyCacheTtl = 'scan_cache_ttl';
  static const _keyConcurrency = 'scan_concurrency';
  static const _keyScheduleOn = 'schedule_enabled';
  static const _keyScheduleMin = 'schedule_interval_min';

  /// Директории сканирования (можно несколько).
  final List<String> projectsRoots;

  /// Хост системы-приёмника (GitLab, Gitea, самописный git-сервер и т.п.).
  final String remoteHost;
  final String remoteGroup;
  final String remoteToken;

  /// Имя remote, на который выполняется push.
  final String remoteName;

  final bool recursiveScan;
  final bool autoStashBeforePull;
  final bool fetchBeforePull;
  final bool pushTags;

  final ThemeMode themeMode;
  final RepoViewMode viewMode;

  /// Сканировать автоматически при запуске (иначе — показ из кэша).
  final bool autoScanOnStartup;

  /// Сколько минут результат сканирования считается свежим (кэш).
  final int scanCacheTtlMinutes;

  /// Сколько репозиториев сканировать параллельно (1–16).
  final int scanConcurrency;

  final bool scheduleEnabled;
  final int scheduleIntervalMinutes;

  /// Первая директория — для операций, где нужен один корень.
  String get primaryRoot =>
      projectsRoots.isNotEmpty ? projectsRoots.first : '';

  bool get hasRoots => projectsRoots.any((r) => r.trim().isNotEmpty);

  String get remoteBaseUrl {
    final host = remoteHost.trim();
    if (host.startsWith('http://') || host.startsWith('https://')) {
      return host.replaceAll(RegExp(r'/+$'), '');
    }
    return 'https://$host';
  }

  AppSettings copyWith({
    List<String>? projectsRoots,
    String? remoteHost,
    String? remoteGroup,
    String? remoteToken,
    String? remoteName,
    bool? recursiveScan,
    bool? autoStashBeforePull,
    bool? fetchBeforePull,
    bool? pushTags,
    ThemeMode? themeMode,
    RepoViewMode? viewMode,
    bool? autoScanOnStartup,
    int? scanCacheTtlMinutes,
    int? scanConcurrency,
    bool? scheduleEnabled,
    int? scheduleIntervalMinutes,
  }) {
    return AppSettings(
      projectsRoots: projectsRoots ?? this.projectsRoots,
      remoteHost: remoteHost ?? this.remoteHost,
      remoteGroup: remoteGroup ?? this.remoteGroup,
      remoteToken: remoteToken ?? this.remoteToken,
      remoteName: remoteName ?? this.remoteName,
      recursiveScan: recursiveScan ?? this.recursiveScan,
      autoStashBeforePull: autoStashBeforePull ?? this.autoStashBeforePull,
      fetchBeforePull: fetchBeforePull ?? this.fetchBeforePull,
      pushTags: pushTags ?? this.pushTags,
      themeMode: themeMode ?? this.themeMode,
      viewMode: viewMode ?? this.viewMode,
      autoScanOnStartup: autoScanOnStartup ?? this.autoScanOnStartup,
      scanCacheTtlMinutes: scanCacheTtlMinutes ?? this.scanCacheTtlMinutes,
      scanConcurrency: scanConcurrency ?? this.scanConcurrency,
      scheduleEnabled: scheduleEnabled ?? this.scheduleEnabled,
      scheduleIntervalMinutes:
          scheduleIntervalMinutes ?? this.scheduleIntervalMinutes,
    );
  }

  static ThemeMode _themeFrom(String? v) => switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _themeTo(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Миграция: одиночная директория → список.
    var roots = prefs.getStringList(_keyRoots);
    if (roots == null || roots.isEmpty) {
      final legacy = prefs.getString(_keyRootLegacy);
      roots = (legacy != null && legacy.isNotEmpty) ? [legacy] : <String>[];
    }

    String pick(String key, String legacy, String fallback) =>
        prefs.getString(key) ?? prefs.getString(legacy) ?? fallback;

    return AppSettings(
      projectsRoots: roots,
      remoteHost: pick(_keyHost, _keyHostLegacy, 'gitlab.com'),
      remoteGroup: pick(_keyGroup, _keyGroupLegacy, 'mobile'),
      remoteToken: pick(_keyToken, _keyTokenLegacy, ''),
      remoteName: pick(_keyRemote, _keyRemoteLegacy, 'origin'),
      recursiveScan: prefs.getBool(_keyRecursive) ?? false,
      autoStashBeforePull: prefs.getBool(_keyAutoStash) ?? true,
      fetchBeforePull: prefs.getBool(_keyFetch) ?? true,
      pushTags: prefs.getBool(_keyPushTags) ?? false,
      themeMode: _themeFrom(prefs.getString(_keyTheme)),
      viewMode: prefs.getString(_keyView) == 'tree'
          ? RepoViewMode.tree
          : RepoViewMode.list,
      autoScanOnStartup: prefs.getBool(_keyAutoScan) ?? false,
      scanCacheTtlMinutes: prefs.getInt(_keyCacheTtl) ?? 60,
      scanConcurrency: prefs.getInt(_keyConcurrency) ?? 4,
      scheduleEnabled: prefs.getBool(_keyScheduleOn) ?? false,
      scheduleIntervalMinutes: prefs.getInt(_keyScheduleMin) ?? 60,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyRoots, projectsRoots);
    await prefs.setString(_keyHost, remoteHost);
    await prefs.setString(_keyGroup, remoteGroup);
    await prefs.setString(_keyToken, remoteToken);
    await prefs.setString(_keyRemote, remoteName);
    await prefs.setBool(_keyRecursive, recursiveScan);
    await prefs.setBool(_keyAutoStash, autoStashBeforePull);
    await prefs.setBool(_keyFetch, fetchBeforePull);
    await prefs.setBool(_keyPushTags, pushTags);
    await prefs.setString(_keyTheme, _themeTo(themeMode));
    await prefs.setString(
        _keyView, viewMode == RepoViewMode.tree ? 'tree' : 'list');
    await prefs.setBool(_keyAutoScan, autoScanOnStartup);
    await prefs.setInt(_keyCacheTtl, scanCacheTtlMinutes);
    await prefs.setInt(_keyConcurrency, scanConcurrency);
    await prefs.setBool(_keyScheduleOn, scheduleEnabled);
    await prefs.setInt(_keyScheduleMin, scheduleIntervalMinutes);
  }

  Map<String, dynamic> toJson() => {
        'projectsRoots': projectsRoots,
        'remoteHost': remoteHost,
        'remoteGroup': remoteGroup,
        'remoteName': remoteName,
        'recursiveScan': recursiveScan,
        'autoStashBeforePull': autoStashBeforePull,
        'fetchBeforePull': fetchBeforePull,
        'pushTags': pushTags,
        'themeMode': _themeTo(themeMode),
        'viewMode': viewMode.name,
      'autoScanOnStartup': autoScanOnStartup,
      'scanCacheTtlMinutes': scanCacheTtlMinutes,
      'scanConcurrency': scanConcurrency,
      'scheduleEnabled': scheduleEnabled,
      'scheduleIntervalMinutes': scheduleIntervalMinutes,
    };

  @override
  String toString() => jsonEncode(toJson());
}
