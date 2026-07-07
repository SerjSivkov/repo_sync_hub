import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/locale_controller.dart';

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
      throw StateError(l10n.errNoHomeDir);
    }
    final desktop = Directory(p.join(home, 'Desktop'));
    if (!await desktop.exists()) {
      throw StateError(l10n.errNoDesktop(desktop.path));
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
      throw StateError(l10n.errOpenFailed('${result.stderr}'));
    }
  }

  /// Открывает директорию репозитория в Терминале.
  static Future<void> openInTerminal(String repoPath) async {
    final result = await Process.run('open', ['-a', 'Terminal', repoPath]);
    if (result.exitCode != 0) {
      throw StateError(l10n.errOpenTerminalFailed('${result.stderr}'));
    }
  }

  /// Перемещает директорию репозитория в Корзину (обратимо).
  /// Использует Finder через AppleScript, чтобы удаление было в системную
  /// Корзину, а не безвозвратным.
  static Future<void> moveToTrash(String repoPath) async {
    final dir = Directory(repoPath);
    if (!await dir.exists()) {
      throw StateError(l10n.errRepoNotFound(repoPath));
    }
    // Экранируем двойные кавычки и обратные слэши для строки AppleScript.
    final escaped = repoPath.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    final script =
        'tell application "Finder" to move POSIX file "$escaped" to trash';
    final result = await Process.run('osascript', ['-e', script]);
    if (result.exitCode != 0) {
      throw StateError(l10n.errTrashFailed('${result.stderr}'.trim()));
    }
  }

  /// Открывает ссылку в браузере по умолчанию.
  static Future<void> openUrl(String url) async {
    final result = await Process.run('open', [url]);
    if (result.exitCode != 0) {
      throw StateError(l10n.errOpenFailed('${result.stderr}'));
    }
  }
}
