import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/git_project.dart';

/// Кэш результатов сканирования: позволяет не сканировать репозитории
/// при каждом входе в приложение и хранит даты последнего pull/скана.
class RepoCache {
  static const _key = 'repo_cache_v1';

  Future<List<GitProject>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(GitProject.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, GitProject>> loadByPath() async {
    final list = await load();
    return {for (final p in list) p.path: p};
  }

  Future<void> save(List<GitProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final data = projects.map((p) => p.toJson()).toList();
    await prefs.setString(_key, jsonEncode(data));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
