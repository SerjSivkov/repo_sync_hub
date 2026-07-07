// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Repo Sync Hub';

  @override
  String get splashSubtitle => 'Git repositories · pull · GitLab';

  @override
  String get actionScan => 'Scan';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionPull => 'Pull';

  @override
  String get actionPush => 'Push';

  @override
  String get actionSync => 'Sync';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDirectories => 'Directories';

  @override
  String get tooltipScanStart =>
      'Scan directories and refresh repository statuses';

  @override
  String get tooltipScanStop => 'Cancel the current scan';

  @override
  String get tooltipPull =>
      'Pull updates (pull main/master) for selected repositories';

  @override
  String get tooltipPush => 'Push selected repositories to the remote';

  @override
  String get tooltipSync => 'Sync: pull, then push for selected';

  @override
  String get tooltipDirectories => 'Open settings and choose scan directories';

  @override
  String get tooltipSettings =>
      'Settings: directories, remote, theme, schedule';

  @override
  String tooltipThemeCycle(String theme) {
    return 'Theme: $theme (tap to switch)';
  }

  @override
  String get tooltipShowTree => 'Show as tree';

  @override
  String get tooltipShowList => 'Show as list';

  @override
  String get tooltipLastScan => 'Last scan';

  @override
  String tooltipLanguageCycle(String lang) {
    return 'Language: $lang (tap to switch)';
  }

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get themeSystem => 'system';

  @override
  String get themeLight => 'light';

  @override
  String get themeDark => 'dark';

  @override
  String get selectAll => 'Select all';

  @override
  String get selectWithUpdatesTooltip =>
      'Select only repositories with updates';

  @override
  String get menuActions => 'Repository actions';

  @override
  String get menuPull => 'Pull main/master';

  @override
  String get menuPush => 'Push to remote';

  @override
  String get menuSync => 'Sync (pull + push)';

  @override
  String get menuOpenRemote => 'Open origin in browser';

  @override
  String get menuShortcut => 'Create desktop shortcut';

  @override
  String get menuFinder => 'Reveal in Finder';

  @override
  String get menuTerminal => 'Open in Terminal';

  @override
  String tooltipOpenRemote(String url) {
    return 'Open origin in browser: $url';
  }

  @override
  String get tooltipNoRemote => 'Repository has no origin URL';

  @override
  String get tooltipCommitCount => 'Number of commits';

  @override
  String get tooltipRepoSize => 'Repository size on disk';

  @override
  String get tooltipLastPullNever => 'Not pulled through the app yet';

  @override
  String tooltipLastPull(String date) {
    return 'Last pull: $date';
  }

  @override
  String get tooltipHasUpdates => 'Updates available on the remote';

  @override
  String get tooltipReceived => 'Updates pulled successfully';

  @override
  String get tooltipAbandoned => 'Not updated for over a year';

  @override
  String get badgeUpdatesShort => 'updates';

  @override
  String get badgeReceived => 'received';

  @override
  String get labelAbandoned => 'abandoned';

  @override
  String get labelDirty => 'dirty';

  @override
  String get unknownBranch => '?';

  @override
  String branchLine(String current, String defaultBranch) {
    return '$current · default $defaultBranch';
  }

  @override
  String get groupErrors => '⚠ Errors';

  @override
  String get groupNoGroup => '(no group)';

  @override
  String get groupRoot => '(root)';

  @override
  String groupUpdatesBadge(int count) {
    return '↓$count';
  }

  @override
  String get tooltipGroupUpdates => 'Updates available in the group';

  @override
  String groupAbandonedBadge(int count) {
    return 'abandoned: $count';
  }

  @override
  String get tooltipGroupAbandoned =>
      'Repositories with no updates for over a year';

  @override
  String get tooltipCollapseGroup => 'Collapse the group — hide repositories';

  @override
  String get tooltipExpandGroup => 'Expand the group';

  @override
  String updatesBadgeCount(int count) {
    return 'updates: $count';
  }

  @override
  String get rootsNone => 'No directories set';

  @override
  String rootsMultiple(int count, String roots) {
    return '$count directories: $roots';
  }

  @override
  String scanRelative(String date) {
    return 'scan: $date';
  }

  @override
  String counter(int selected, int total) {
    return '$selected / $total';
  }

  @override
  String get progressStopping => 'Stopping…';

  @override
  String progressScanningName(String name) {
    return 'Scanning: $name';
  }

  @override
  String get progressSearching => 'Searching for repositories…';

  @override
  String get progressScanning => 'Scanning…';

  @override
  String progressOkErrors(int ok, int errors) {
    return 'OK: $ok · errors: $errors';
  }

  @override
  String doneStopped(int ok, int errors, int done, int total) {
    return 'Stopped: OK $ok, errors $errors, scanned $done/$total';
  }

  @override
  String doneScan(int ok, int errors) {
    return 'Scan: OK $ok, errors $errors';
  }

  @override
  String get emptyNoRoots => 'Choose directories with git projects in settings';

  @override
  String get emptyNotFound => 'No repositories found — start a scan';

  @override
  String get logTitle => 'Log';

  @override
  String get logClear => 'Clear';

  @override
  String logCacheLoaded(int count) {
    return 'Loaded from cache: $count repositories (scan on startup is off)';
  }

  @override
  String get logScheduledScan => 'Scheduled scan…';

  @override
  String logScheduleEnabled(int minutes) {
    return 'Schedule enabled: every $minutes min';
  }

  @override
  String get logStoppingScan => 'Stopping the scan…';

  @override
  String get logNoRoots => 'Set project directories in settings';

  @override
  String get logNoSelection => 'No projects selected';

  @override
  String logScanStart(String roots) {
    return 'Scanning: $roots…';
  }

  @override
  String logScanDone(int count, int ok, int errors) {
    return 'Done: $count repositories, OK $ok, errors $errors';
  }

  @override
  String logScanDoneUpdates(int count, int ok, int errors, int updates) {
    return 'Done: $count repositories, OK $ok, errors $errors, updates available: $updates';
  }

  @override
  String logScanStopped(int done, int total, int ok, int errors) {
    return 'Scan stopped: $done of $total, OK $ok, errors $errors';
  }

  @override
  String logScanError(String error) {
    return 'Scan error: $error';
  }

  @override
  String logOperationHeader(String label, int count) {
    return '=== $label ($count) ===';
  }

  @override
  String logProjectMessage(String name, String message) {
    return '[$name] $message';
  }

  @override
  String logProjectError(String name, String error) {
    return '[$name] error: $error';
  }

  @override
  String logSelectedWithUpdates(int count) {
    return 'Repositories with updates selected: $count';
  }

  @override
  String logShortcutCreated(String name, String path) {
    return '[$name] shortcut created: $path';
  }

  @override
  String logShortcutFailed(String name, String error) {
    return '[$name] failed to create shortcut: $error';
  }

  @override
  String logFinderError(String name, String error) {
    return '[$name] Finder: $error';
  }

  @override
  String logTerminalError(String name, String error) {
    return '[$name] Terminal: $error';
  }

  @override
  String logNoRemoteLink(String name) {
    return '[$name] no origin link to open';
  }

  @override
  String logOpenedRemote(String name, String url) {
    return '[$name] opened in browser: $url';
  }

  @override
  String logOpenRemoteFailed(String name, String error) {
    return '[$name] failed to open the link: $error';
  }

  @override
  String get snackShortcutCreated => 'Shortcut created on the Desktop';

  @override
  String snackShortcutFailed(String error) {
    return 'Failed to create shortcut: $error';
  }

  @override
  String get snackNoRemote => 'Repository has no origin URL';

  @override
  String snackOpenRemoteFailed(String error) {
    return 'Failed to open the link: $error';
  }

  @override
  String get labelPullMasterMain => 'Pull main/master';

  @override
  String get labelPull => 'Pull';

  @override
  String get labelPush => 'Push';

  @override
  String get labelSync => 'Sync';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsScanDirs => 'Scan directories';

  @override
  String get settingsAddDir => 'Add';

  @override
  String get settingsAddDirTooltip =>
      'Add a directory to search for git repositories';

  @override
  String get settingsNoDirs => 'No directories selected';

  @override
  String get settingsRemoveDir => 'Remove directory from the list';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsViewMode => 'List view';

  @override
  String get settingsViewList => 'List';

  @override
  String get settingsViewTree => 'Tree';

  @override
  String get settingsRemoteSection => 'Remote (push)';

  @override
  String get settingsHost => 'Host';

  @override
  String get settingsHostHint => 'gitlab.com / gitea.local / git.company.ru';

  @override
  String get settingsHostHelper =>
      'Any git system: GitLab, Gitea, Bitbucket, custom server';

  @override
  String get settingsGroup => 'Group / namespace';

  @override
  String get settingsRemoteName => 'Remote name for push';

  @override
  String get settingsToken => 'Token (optional)';

  @override
  String get settingsTokenHelper =>
      'For the remote URL on push; stored locally';

  @override
  String get settingsScanSection => 'Scanning';

  @override
  String get settingsRecursive => 'Recursive scan';

  @override
  String get settingsRecursiveSub => 'Search for .git in nested folders';

  @override
  String get settingsAutoScan => 'Scan on startup';

  @override
  String get settingsAutoScanSub =>
      'Otherwise show data from the last scan cache';

  @override
  String get settingsCacheTtl => 'Scan cache, min';

  @override
  String get settingsCacheTtlHelper =>
      'Fresh repositories (within this period) are not rescanned. 0 — always scan';

  @override
  String get settingsConcurrency => 'Scan concurrency';

  @override
  String get settingsConcurrencyHelper =>
      'How many repositories to scan at once (1–16)';

  @override
  String get settingsFetch => 'fetch before pull';

  @override
  String get settingsStash => 'stash before checkout';

  @override
  String get settingsStashSub => 'If there are uncommitted changes';

  @override
  String get settingsPushTags => 'Push tags';

  @override
  String get settingsScheduleSection => 'Scheduled scan';

  @override
  String get settingsScheduleEnabled => 'Run automatically';

  @override
  String get settingsScheduleEnabledSub => 'Periodically repeat the scan';

  @override
  String get settingsInterval => 'Interval, min';

  @override
  String get settingsIntervalHelper => 'How often to repeat the scan';

  @override
  String get fmtNever => 'never';

  @override
  String get fmtJustNow => 'just now';

  @override
  String fmtMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '$count minute ago',
    );
    return '$_temp0';
  }

  @override
  String fmtHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '$count hour ago',
    );
    return '$_temp0';
  }

  @override
  String fmtDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '$count day ago',
    );
    return '$_temp0';
  }

  @override
  String fmtWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '$count week ago',
    );
    return '$_temp0';
  }

  @override
  String fmtMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '$count month ago',
    );
    return '$_temp0';
  }

  @override
  String fmtYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '$count year ago',
    );
    return '$_temp0';
  }

  @override
  String get unitB => 'B';

  @override
  String get unitKB => 'KB';

  @override
  String get unitMB => 'MB';

  @override
  String get unitGB => 'GB';

  @override
  String get unitTB => 'TB';

  @override
  String get opNoDefaultBranch => 'main/master branch not found';

  @override
  String get opUpdatesReceived => 'updates received';

  @override
  String get opUpToDate => 'up to date';

  @override
  String get opNoBranchPush => 'No main/master branch to push';

  @override
  String get opPushOk => 'push ok';

  @override
  String opRemoteAlready(String name) {
    return 'remote $name already points to the target system';
  }

  @override
  String opLogPull(String name, String branch) {
    return '[$name] pull $branch';
  }

  @override
  String opLogPush(String name) {
    return '[$name] push → remote';
  }

  @override
  String opLogSync(String name) {
    return '[$name] sync (pull + push)';
  }

  @override
  String get scanErrorShort => 'Scan error';

  @override
  String scanErrorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String statusBranch(String branch) {
    return 'branch $branch';
  }

  @override
  String statusDefault(String branch) {
    return 'default $branch';
  }

  @override
  String get statusDirty => 'has changes';

  @override
  String statusUpdates(int count) {
    return 'updates: $count';
  }

  @override
  String statusAhead(int count) {
    return '+$count';
  }

  @override
  String statusBehind(int count) {
    return '-$count';
  }

  @override
  String get statusOk => 'ok';

  @override
  String get errNoHomeDir => 'Could not determine the home directory';

  @override
  String errNoDesktop(String path) {
    return 'Desktop folder not found: $path';
  }

  @override
  String errOpenFailed(String error) {
    return 'open failed with an error: $error';
  }

  @override
  String errOpenTerminalFailed(String error) {
    return 'open -a Terminal failed with an error: $error';
  }

  @override
  String get exceptionScanCancelled => 'Scan stopped';
}
