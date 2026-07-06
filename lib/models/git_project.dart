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
    this.remoteBehindCount = 0,
    this.updatesReceived = false,
    this.gitlabRemote,
    this.originUrl,
    this.lastMessage,
    this.scanError,
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
  /// Коммиты на remote, которых нет локально (после fetch).
  final int remoteBehindCount;
  /// Pull только что подтянул новые коммиты.
  final bool updatesReceived;
  final String? gitlabRemote;
  final String? originUrl;
  final String? lastMessage;
  final String? scanError;
  final GitProjectStatus status;
  final bool selected;

  bool get hasGitlabRemote => gitlabRemote != null;

  bool get hasRemoteUpdates => remoteBehindCount > 0;

  bool get scanFailed => scanError != null;

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
    int? remoteBehindCount,
    bool? updatesReceived,
    String? gitlabRemote,
    String? originUrl,
    String? lastMessage,
    String? scanError,
    GitProjectStatus? status,
    bool? selected,
    bool clearUpdatesReceived = false,
    bool clearScanError = false,
  }) {
    return GitProject(
      name: name,
      path: path,
      currentBranch: currentBranch ?? this.currentBranch,
      defaultBranch: defaultBranch ?? this.defaultBranch,
      isDirty: isDirty ?? this.isDirty,
      ahead: ahead ?? this.ahead,
      behind: behind ?? this.behind,
      remoteBehindCount: remoteBehindCount ?? this.remoteBehindCount,
      updatesReceived: clearUpdatesReceived ? false : (updatesReceived ?? this.updatesReceived),
      gitlabRemote: gitlabRemote ?? this.gitlabRemote,
      originUrl: originUrl ?? this.originUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      scanError: clearScanError ? null : (scanError ?? this.scanError),
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

  bool get pulledUpdates {
    final out = combined.toLowerCase();
    if (out.contains('already up to date')) return false;
    if (out.contains('fast-forward')) return true;
    if (out.contains('files changed')) return true;
    if (out.contains('insertion')) return true;
    return stdout.trim().isNotEmpty && !out.contains('already up to date');
  }
}
