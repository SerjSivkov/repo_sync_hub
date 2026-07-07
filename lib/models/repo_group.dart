import '../l10n/app_localizations.dart';
import 'git_project.dart';

/// Группа репозиториев по дочерней директории сканирования.
class RepoGroup {
  RepoGroup({
    required this.name,
    required this.projects,
    this.isErrorGroup = false,
  });

  final String name;
  final List<GitProject> projects;

  /// Псевдо-группа «Ошибки», всегда сверху.
  final bool isErrorGroup;

  int get updatesCount => projects.where((p) => p.hasRemoteUpdates).length;
  int get abandonedCount => projects.where((p) => p.isAbandoned).length;
}

/// Псевдо-группа «Ошибки» — сентинел, локализуется в виджете.
const String kErrorGroupName = '\u0000errors';

/// Локализует имя группы: сентинелы → перевод, обычные имена — как есть.
String localizedGroupName(AppLocalizations l10n, String name) => switch (name) {
      kErrorGroupName => l10n.groupErrors,
      kGroupNoGroup => l10n.groupNoGroup,
      kGroupRoot => l10n.groupRoot,
      _ => name,
    };

/// Разбивает проекты на группы согласно требованиям:
/// 1. Репозитории с ошибками — отдельная группа сверху.
/// 2. Остальные — по дочерней директории (1 уровень ниже корня сканирования).
/// 3. Внутри группы — сортировка по последним стянутым изменениям (свежие сверху),
///    заброшенные (>1 года без обновлений) — в самом низу группы.
List<RepoGroup> groupProjects(List<GitProject> projects) {
  final failed = projects.where((p) => p.scanFailed).toList();
  final ok = projects.where((p) => !p.scanFailed).toList();

  final byGroup = <String, List<GitProject>>{};
  for (final project in ok) {
    byGroup.putIfAbsent(project.groupName, () => []).add(project);
  }

  int withinGroup(GitProject a, GitProject b) {
    // Заброшенные всегда ниже активных.
    if (a.isAbandoned != b.isAbandoned) return a.isAbandoned ? 1 : -1;
    // Доступные обновления — выше.
    if (a.hasRemoteUpdates != b.hasRemoteUpdates) {
      return a.hasRemoteUpdates ? -1 : 1;
    }
    // Свежие изменения — выше.
    final byDate = b.sortDate.compareTo(a.sortDate);
    if (byDate != 0) return byDate;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  final groups = <RepoGroup>[];
  if (failed.isNotEmpty) {
    failed.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    groups.add(RepoGroup(
      name: kErrorGroupName,
      projects: failed,
      isErrorGroup: true,
    ));
  }

  final names = byGroup.keys.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  for (final name in names) {
    final list = byGroup[name]!..sort(withinGroup);
    groups.add(RepoGroup(name: name, projects: list));
  }

  return groups;
}
