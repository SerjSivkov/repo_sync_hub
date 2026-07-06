/// Статус операции над одним репозиторием.
enum GitProjectStatus {
  idle,
  scanning,
  pulling,
  pushing,
  syncing,
  success,
  warning,
  error,
}

/// Краткая информация о git-репозитории.
class GitProject {
  GitProject({
    required this.name,
    required this.path,
    this.currentBranch,
    this.defaultBranch,
    this.isDirty = false,
    this.ahead = 0,
    this.behind = 0,
    this.gitlabRemote,
    this.originUrl,
    this.lastMessage,
    this.status = GitProjectStatus.idle,
    this.selected = true,
  });

  final String name;
  final String path;
  final String? currentBranch;
  final String? defaultBranch;
  final bool isDirty;
  final int ahead;
  final int behind;
  final String? gitlabRemote;
  final String? originUrl;
  final String? lastMessage;
  final GitProjectStatus status;
  final bool selected;

  bool get hasGitlabRemote => gitlabRemote != null;

  bool get isOnDefaultBranch {
    if (currentBranch == null || defaultBranch == null) return false;
    return currentBranch == defaultBranch;
  }

  GitProject copyWith({
    String? currentBranch,
    String? defaultBranch,
    bool? isDirty,
    int? ahead,
    int? behind,
    String? gitlabRemote,
    String? originUrl,
    String? lastMessage,
    GitProjectStatus? status,
    bool? selected,
  }) {
    return GitProject(
      name: name,
      path: path,
      currentBranch: currentBranch ?? this.currentBranch,
      defaultBranch: defaultBranch ?? this.defaultBranch,
      isDirty: isDirty ?? this.isDirty,
      ahead: ahead ?? this.ahead,
      behind: behind ?? this.behind,
      gitlabRemote: gitlabRemote ?? this.gitlabRemote,
      originUrl: originUrl ?? this.originUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      status: status ?? this.status,
      selected: selected ?? this.selected,
    );
  }
}

/// Результат git-команды.
class GitCommandResult {
  const GitCommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get ok => exitCode == 0;

  String get combined {
    final parts = <String>[];
    if (stdout.trim().isNotEmpty) parts.add(stdout.trim());
    if (stderr.trim().isNotEmpty) parts.add(stderr.trim());
    return parts.join('\n');
  }
}
