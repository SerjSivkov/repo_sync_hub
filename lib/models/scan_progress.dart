import 'git_project.dart';

/// Прогресс сканирования репозиториев.
class ScanProgress {
  const ScanProgress({
    required this.total,
    required this.completed,
    required this.successCount,
    required this.errorCount,
    this.currentName,
    this.projects = const [],
    this.cancelled = false,
  });

  final int total;
  final int completed;
  final int successCount;
  final int errorCount;
  final String? currentName;
  final List<GitProject> projects;
  final bool cancelled;

  double get fraction => total == 0 ? 0 : completed / total;

  bool get isDone => cancelled || (total > 0 && completed >= total);
}
