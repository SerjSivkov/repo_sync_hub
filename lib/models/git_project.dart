import 'package:path/path.dart' as p;

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

/// Порог «заброшенности»: репозиторий не обновлялся дольше этого срока.
const Duration kAbandonedThreshold = Duration(days: 365);

/// Сентинелы спец-названий групп (локализуются в виджете отображения).
const String kGroupNoGroup = '\u0000no_group';
const String kGroupRoot = '\u0000root';

/// Краткая информация о git-репозитории.
class GitProject {
  GitProject({
    required this.name,
    required this.path,
    this.scanRoot,
    this.currentBranch,
    this.defaultBranch,
    this.isDirty = false,
    this.ahead = 0,
    this.behind = 0,
    this.remoteBehindCount = 0,
    this.updatesReceived = false,
    this.targetRemote,
    this.originUrl,
    this.commitCount,
    this.sizeBytes,
    this.lastCommitAt,
    this.lastPulledAt,
    this.lastScannedAt,
    this.lastMessage,
    this.scanError,
    this.status = GitProjectStatus.idle,
    this.selected = true,
  });

  final String name;
  final String path;

  /// Корневая директория сканирования, к которой относится репозиторий.
  final String? scanRoot;

  final String? currentBranch;
  final String? defaultBranch;
  final bool isDirty;
  final int ahead;
  final int behind;

  /// Коммиты на remote, которых нет локально (после fetch).
  final int remoteBehindCount;

  /// Pull только что подтянул новые коммиты.
  final bool updatesReceived;

  /// Remote, указывающий на настроенную систему-приёмник.
  final String? targetRemote;
  final String? originUrl;

  /// Всего коммитов в репозитории (rev-list --count HEAD).
  final int? commitCount;

  /// Размер рабочей копии в байтах.
  final int? sizeBytes;

  /// Дата последнего коммита в репозитории.
  final DateTime? lastCommitAt;

  /// Дата последнего успешного стягивания обновлений через приложение.
  final DateTime? lastPulledAt;

  /// Дата последнего сканирования репозитория.
  final DateTime? lastScannedAt;

  final String? lastMessage;
  final String? scanError;
  final GitProjectStatus status;
  final bool selected;

  bool get hasTargetRemote => targetRemote != null;

  bool get hasRemoteUpdates => remoteBehindCount > 0;

  /// Ссылка на origin, пригодная для открытия в браузере (https).
  /// Нормализует SSH/scp-подобные URL git в http(s). `null`, если origin
  /// не задан или его нельзя привести к веб-ссылке.
  String? get remoteWebUrl => gitRemoteToWebUrl(originUrl);

  bool get scanFailed => scanError != null;

  bool get isOnDefaultBranch {
    if (currentBranch == null || defaultBranch == null) return false;
    return currentBranch == defaultBranch;
  }

  /// Последняя активность: наш pull либо последний коммит в репозитории.
  DateTime? get lastActivity {
    final dates = <DateTime>[?lastPulledAt, ?lastCommitAt];
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.last;
  }

  /// Репозиторий не обновлялся дольше года — считается заброшенным.
  bool get isAbandoned {
    final activity = lastActivity;
    if (activity == null) return false;
    return DateTime.now().difference(activity) > kAbandonedThreshold;
  }

  /// Ключ сортировки внутри группы: по последним стянутым изменениям.
  DateTime get sortDate =>
      lastPulledAt ?? lastCommitAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Группа = дочерняя директория на 1 уровень ниже директории сканирования.
  /// Для спец-случаев возвращает стабильные ключи-сентинелы
  /// ([kGroupNoGroup]/[kGroupRoot]), которые локализуются в виджете.
  String get groupName {
    final root = scanRoot;
    if (root == null || root.isEmpty) return kGroupNoGroup;
    final rel = p.relative(path, from: root);
    final parts =
        p.split(rel).where((e) => e != '.' && e.isNotEmpty).toList();
    if (parts.length <= 1) return kGroupRoot;
    return parts.first;
  }

  GitProject copyWith({
    String? scanRoot,
    String? currentBranch,
    String? defaultBranch,
    bool? isDirty,
    int? ahead,
    int? behind,
    int? remoteBehindCount,
    bool? updatesReceived,
    String? targetRemote,
    String? originUrl,
    int? commitCount,
    int? sizeBytes,
    DateTime? lastCommitAt,
    DateTime? lastPulledAt,
    DateTime? lastScannedAt,
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
      scanRoot: scanRoot ?? this.scanRoot,
      currentBranch: currentBranch ?? this.currentBranch,
      defaultBranch: defaultBranch ?? this.defaultBranch,
      isDirty: isDirty ?? this.isDirty,
      ahead: ahead ?? this.ahead,
      behind: behind ?? this.behind,
      remoteBehindCount: remoteBehindCount ?? this.remoteBehindCount,
      updatesReceived: clearUpdatesReceived
          ? false
          : (updatesReceived ?? this.updatesReceived),
      targetRemote: targetRemote ?? this.targetRemote,
      originUrl: originUrl ?? this.originUrl,
      commitCount: commitCount ?? this.commitCount,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      lastCommitAt: lastCommitAt ?? this.lastCommitAt,
      lastPulledAt: lastPulledAt ?? this.lastPulledAt,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      scanError: clearScanError ? null : (scanError ?? this.scanError),
      status: status ?? this.status,
      selected: selected ?? this.selected,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'scanRoot': scanRoot,
        'currentBranch': currentBranch,
        'defaultBranch': defaultBranch,
        'isDirty': isDirty,
        'ahead': ahead,
        'behind': behind,
        'remoteBehindCount': remoteBehindCount,
        'targetRemote': targetRemote,
        'originUrl': originUrl,
        'commitCount': commitCount,
        'sizeBytes': sizeBytes,
        'lastCommitAt': lastCommitAt?.millisecondsSinceEpoch,
        'lastPulledAt': lastPulledAt?.millisecondsSinceEpoch,
        'lastScannedAt': lastScannedAt?.millisecondsSinceEpoch,
        'lastMessage': lastMessage,
        'scanError': scanError,
      };

  static DateTime? _dt(dynamic v) =>
      v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;

  factory GitProject.fromJson(Map<String, dynamic> json) {
    final error = json['scanError'] as String?;
    return GitProject(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      scanRoot: json['scanRoot'] as String?,
      currentBranch: json['currentBranch'] as String?,
      defaultBranch: json['defaultBranch'] as String?,
      isDirty: json['isDirty'] as bool? ?? false,
      ahead: json['ahead'] as int? ?? 0,
      behind: json['behind'] as int? ?? 0,
      remoteBehindCount: json['remoteBehindCount'] as int? ?? 0,
      targetRemote: json['targetRemote'] as String?,
      originUrl: json['originUrl'] as String?,
      commitCount: json['commitCount'] as int?,
      sizeBytes: json['sizeBytes'] as int?,
      lastCommitAt: _dt(json['lastCommitAt']),
      lastPulledAt: _dt(json['lastPulledAt']),
      lastScannedAt: _dt(json['lastScannedAt']),
      lastMessage: json['lastMessage'] as String?,
      scanError: error,
      status: error != null ? GitProjectStatus.error : GitProjectStatus.idle,
    );
  }
}

/// Приводит git-remote URL к веб-ссылке (https) для открытия в браузере.
///
/// Поддерживает форматы:
/// - `https://host/path.git`      → `https://host/path`
/// - `http://host/path`           → как есть
/// - `git@host:group/repo.git`    → `https://host/group/repo` (scp-подобный)
/// - `ssh://git@host:22/path.git` → `https://host/path`
/// - `git://host/path.git`        → `https://host/path`
///
/// Токен/пароль из userinfo (`user:pass@host`) отбрасывается. Возвращает
/// `null`, если ссылку нельзя привести к веб-адресу.
String? gitRemoteToWebUrl(String? remote) {
  final raw = remote?.trim();
  if (raw == null || raw.isEmpty) return null;

  String stripGitSuffix(String s) =>
      s.endsWith('.git') ? s.substring(0, s.length - 4) : s;

  String dropUserInfo(String host) {
    final at = host.lastIndexOf('@');
    return at >= 0 ? host.substring(at + 1) : host;
  }

  // Уже http(s) — только чистим суффикс и userinfo.
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    final host = uri.host;
    if (host.isEmpty) return null;
    final path = stripGitSuffix(uri.path);
    final portPart =
        (uri.hasPort && uri.port != 80 && uri.port != 443) ? ':${uri.port}' : '';
    return '${uri.scheme}://$host$portPart$path';
  }

  // ssh:// или git:// — разбираем как URI, порт отбрасываем.
  if (raw.startsWith('ssh://') || raw.startsWith('git://')) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) return null;
    return 'https://${uri.host}${stripGitSuffix(uri.path)}';
  }

  // scp-подобный: [user@]host:group/repo(.git)
  final scp = RegExp(r'^([^@/]+@)?([^:/]+):(.+)$').firstMatch(raw);
  if (scp != null) {
    final host = dropUserInfo('${scp.group(1) ?? ''}${scp.group(2)}');
    final path = stripGitSuffix(scp.group(3)!);
    if (host.isEmpty || path.isEmpty) return null;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return 'https://$host$normalizedPath';
  }

  return null;
}

/// Выводит имя директории репозитория из git-URL (как это делает `git clone`).
///
/// Примеры:
/// - `https://host/group/repo.git`   → `repo`
/// - `git@host:group/repo.git`       → `repo`
/// - `ssh://git@host/path/repo`      → `repo`
///
/// Возвращает `null`, если имя нельзя определить.
String? gitRepoNameFromUrl(String? url) {
  var raw = url?.trim();
  if (raw == null || raw.isEmpty) return null;

  // Отбрасываем завершающий слэш.
  raw = raw.replaceAll(RegExp(r'/+$'), '');

  // Последний сегмент после '/' или ':' (для scp-подобных URL).
  final match = RegExp(r'[/:]([^/:]+)$').firstMatch(raw);
  var name = match != null ? match.group(1)! : raw;

  if (name.endsWith('.git')) name = name.substring(0, name.length - 4);
  name = name.trim();
  return name.isEmpty ? null : name;
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
