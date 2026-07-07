import 'dart:io';

import 'package:path/path.dart' as p;

/// Создание ярлыков на репозитории и открытие их в системе (macOS).
class RepoShortcut {
  /// Создаёт ярлык (симлинк) на директорию репозитория на Рабочем столе.
  /// Возвращает путь к созданному ярлыку.
  static Future<String> createDesktopShortcut(
    String repoPath, {
    String? label,
  }) async {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      throw StateError('Не удалось определить домашнюю директорию');
    }
    final desktop = Directory(p.join(home, 'Desktop'));
    if (!await desktop.exists()) {
      throw StateError('Папка «Рабочий стол» не найдена: ${desktop.path}');
    }

    final name = label ?? p.basename(repoPath);
    var linkPath = p.join(desktop.path, name);
    // Не затираем существующий файл — добавляем суффикс.
    var counter = 1;
    while (await FileSystemEntity.type(linkPath) !=
        FileSystemEntityType.notFound) {
      linkPath = p.join(desktop.path, '$name ($counter)');
      counter++;
    }

    await Link(linkPath).create(repoPath);
    return linkPath;
  }

  /// Открывает директорию репозитория в Finder.
  static Future<void> revealInFinder(String repoPath) async {
    final result = await Process.run('open', [repoPath]);
    if (result.exitCode != 0) {
      throw StateError('open завершился с ошибкой: ${result.stderr}');
    }
  }

  /// Открывает директорию репозитория в Терминале.
  static Future<void> openInTerminal(String repoPath) async {
    final result = await Process.run('open', ['-a', 'Terminal', repoPath]);
    if (result.exitCode != 0) {
      throw StateError('open -a Terminal завершился с ошибкой: ${result.stderr}');
    }
  }
}
