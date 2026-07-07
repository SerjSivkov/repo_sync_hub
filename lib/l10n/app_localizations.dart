import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Repo Sync Hub'**
  String get appTitle;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Git repositories · pull · GitLab'**
  String get splashSubtitle;

  /// No description provided for @actionScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get actionScan;

  /// No description provided for @actionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// No description provided for @actionPull.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get actionPull;

  /// No description provided for @actionPush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get actionPush;

  /// No description provided for @actionSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get actionSync;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDirectories.
  ///
  /// In en, this message translates to:
  /// **'Directories'**
  String get actionDirectories;

  /// No description provided for @actionAddRepo.
  ///
  /// In en, this message translates to:
  /// **'Add repository'**
  String get actionAddRepo;

  /// No description provided for @actionClone.
  ///
  /// In en, this message translates to:
  /// **'Clone'**
  String get actionClone;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @tooltipScanStart.
  ///
  /// In en, this message translates to:
  /// **'Scan directories and refresh repository statuses'**
  String get tooltipScanStart;

  /// No description provided for @tooltipScanStop.
  ///
  /// In en, this message translates to:
  /// **'Cancel the current scan'**
  String get tooltipScanStop;

  /// No description provided for @tooltipPull.
  ///
  /// In en, this message translates to:
  /// **'Pull updates (pull main/master) for selected repositories'**
  String get tooltipPull;

  /// No description provided for @tooltipPush.
  ///
  /// In en, this message translates to:
  /// **'Push selected repositories to the remote'**
  String get tooltipPush;

  /// No description provided for @tooltipSync.
  ///
  /// In en, this message translates to:
  /// **'Sync: pull, then push for selected'**
  String get tooltipSync;

  /// No description provided for @tooltipDirectories.
  ///
  /// In en, this message translates to:
  /// **'Open settings and choose scan directories'**
  String get tooltipDirectories;

  /// No description provided for @tooltipAddRepo.
  ///
  /// In en, this message translates to:
  /// **'Clone a repository into a scan directory'**
  String get tooltipAddRepo;

  /// No description provided for @tooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings: directories, remote, theme, schedule'**
  String get tooltipSettings;

  /// No description provided for @tooltipThemeCycle.
  ///
  /// In en, this message translates to:
  /// **'Theme: {theme} (tap to switch)'**
  String tooltipThemeCycle(String theme);

  /// No description provided for @tooltipShowTree.
  ///
  /// In en, this message translates to:
  /// **'Show as tree'**
  String get tooltipShowTree;

  /// No description provided for @tooltipShowList.
  ///
  /// In en, this message translates to:
  /// **'Show as list'**
  String get tooltipShowList;

  /// No description provided for @tooltipLastScan.
  ///
  /// In en, this message translates to:
  /// **'Last scan'**
  String get tooltipLastScan;

  /// No description provided for @tooltipLanguageCycle.
  ///
  /// In en, this message translates to:
  /// **'Language: {lang} (tap to switch)'**
  String tooltipLanguageCycle(String lang);

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'system'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'dark'**
  String get themeDark;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @selectWithUpdatesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select only repositories with updates'**
  String get selectWithUpdatesTooltip;

  /// No description provided for @menuActions.
  ///
  /// In en, this message translates to:
  /// **'Repository actions'**
  String get menuActions;

  /// No description provided for @menuPull.
  ///
  /// In en, this message translates to:
  /// **'Pull main/master'**
  String get menuPull;

  /// No description provided for @menuPush.
  ///
  /// In en, this message translates to:
  /// **'Push to remote'**
  String get menuPush;

  /// No description provided for @menuSync.
  ///
  /// In en, this message translates to:
  /// **'Sync (pull + push)'**
  String get menuSync;

  /// No description provided for @menuOpenRemote.
  ///
  /// In en, this message translates to:
  /// **'Open origin in browser'**
  String get menuOpenRemote;

  /// No description provided for @menuShortcut.
  ///
  /// In en, this message translates to:
  /// **'Create desktop shortcut'**
  String get menuShortcut;

  /// No description provided for @menuFinder.
  ///
  /// In en, this message translates to:
  /// **'Reveal in Finder'**
  String get menuFinder;

  /// No description provided for @menuTerminal.
  ///
  /// In en, this message translates to:
  /// **'Open in Terminal'**
  String get menuTerminal;

  /// No description provided for @menuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete from disk…'**
  String get menuDelete;

  /// No description provided for @tooltipOpenRemote.
  ///
  /// In en, this message translates to:
  /// **'Open origin in browser: {url}'**
  String tooltipOpenRemote(String url);

  /// No description provided for @tooltipNoRemote.
  ///
  /// In en, this message translates to:
  /// **'Repository has no origin URL'**
  String get tooltipNoRemote;

  /// No description provided for @tooltipCommitCount.
  ///
  /// In en, this message translates to:
  /// **'Number of commits'**
  String get tooltipCommitCount;

  /// No description provided for @tooltipRepoSize.
  ///
  /// In en, this message translates to:
  /// **'Repository size on disk'**
  String get tooltipRepoSize;

  /// No description provided for @tooltipLastPullNever.
  ///
  /// In en, this message translates to:
  /// **'Not pulled through the app yet'**
  String get tooltipLastPullNever;

  /// No description provided for @tooltipLastPull.
  ///
  /// In en, this message translates to:
  /// **'Last pull: {date}'**
  String tooltipLastPull(String date);

  /// No description provided for @tooltipHasUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates available on the remote'**
  String get tooltipHasUpdates;

  /// No description provided for @tooltipReceived.
  ///
  /// In en, this message translates to:
  /// **'Updates pulled successfully'**
  String get tooltipReceived;

  /// No description provided for @tooltipAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Not updated for over a year'**
  String get tooltipAbandoned;

  /// No description provided for @badgeUpdatesShort.
  ///
  /// In en, this message translates to:
  /// **'updates'**
  String get badgeUpdatesShort;

  /// No description provided for @badgeReceived.
  ///
  /// In en, this message translates to:
  /// **'received'**
  String get badgeReceived;

  /// No description provided for @labelAbandoned.
  ///
  /// In en, this message translates to:
  /// **'abandoned'**
  String get labelAbandoned;

  /// No description provided for @labelDirty.
  ///
  /// In en, this message translates to:
  /// **'dirty'**
  String get labelDirty;

  /// No description provided for @unknownBranch.
  ///
  /// In en, this message translates to:
  /// **'?'**
  String get unknownBranch;

  /// No description provided for @branchLine.
  ///
  /// In en, this message translates to:
  /// **'{current} · default {defaultBranch}'**
  String branchLine(String current, String defaultBranch);

  /// No description provided for @groupErrors.
  ///
  /// In en, this message translates to:
  /// **'⚠ Errors'**
  String get groupErrors;

  /// No description provided for @groupNoGroup.
  ///
  /// In en, this message translates to:
  /// **'(no group)'**
  String get groupNoGroup;

  /// No description provided for @groupRoot.
  ///
  /// In en, this message translates to:
  /// **'(root)'**
  String get groupRoot;

  /// No description provided for @groupUpdatesBadge.
  ///
  /// In en, this message translates to:
  /// **'↓{count}'**
  String groupUpdatesBadge(int count);

  /// No description provided for @tooltipGroupUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates available in the group'**
  String get tooltipGroupUpdates;

  /// No description provided for @groupAbandonedBadge.
  ///
  /// In en, this message translates to:
  /// **'abandoned: {count}'**
  String groupAbandonedBadge(int count);

  /// No description provided for @tooltipGroupAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Repositories with no updates for over a year'**
  String get tooltipGroupAbandoned;

  /// No description provided for @tooltipCollapseGroup.
  ///
  /// In en, this message translates to:
  /// **'Collapse the group — hide repositories'**
  String get tooltipCollapseGroup;

  /// No description provided for @tooltipExpandGroup.
  ///
  /// In en, this message translates to:
  /// **'Expand the group'**
  String get tooltipExpandGroup;

  /// No description provided for @updatesBadgeCount.
  ///
  /// In en, this message translates to:
  /// **'updates: {count}'**
  String updatesBadgeCount(int count);

  /// No description provided for @rootsNone.
  ///
  /// In en, this message translates to:
  /// **'No directories set'**
  String get rootsNone;

  /// No description provided for @rootsMultiple.
  ///
  /// In en, this message translates to:
  /// **'{count} directories: {roots}'**
  String rootsMultiple(int count, String roots);

  /// No description provided for @scanRelative.
  ///
  /// In en, this message translates to:
  /// **'scan: {date}'**
  String scanRelative(String date);

  /// No description provided for @counter.
  ///
  /// In en, this message translates to:
  /// **'{selected} / {total}'**
  String counter(int selected, int total);

  /// No description provided for @progressStopping.
  ///
  /// In en, this message translates to:
  /// **'Stopping…'**
  String get progressStopping;

  /// No description provided for @progressScanningName.
  ///
  /// In en, this message translates to:
  /// **'Scanning: {name}'**
  String progressScanningName(String name);

  /// No description provided for @progressSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching for repositories…'**
  String get progressSearching;

  /// No description provided for @progressScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get progressScanning;

  /// No description provided for @progressOkErrors.
  ///
  /// In en, this message translates to:
  /// **'OK: {ok} · errors: {errors}'**
  String progressOkErrors(int ok, int errors);

  /// No description provided for @doneStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped: OK {ok}, errors {errors}, scanned {done}/{total}'**
  String doneStopped(int ok, int errors, int done, int total);

  /// No description provided for @doneScan.
  ///
  /// In en, this message translates to:
  /// **'Scan: OK {ok}, errors {errors}'**
  String doneScan(int ok, int errors);

  /// No description provided for @emptyNoRoots.
  ///
  /// In en, this message translates to:
  /// **'Choose directories with git projects in settings'**
  String get emptyNoRoots;

  /// No description provided for @emptyNotFound.
  ///
  /// In en, this message translates to:
  /// **'No repositories found — start a scan'**
  String get emptyNotFound;

  /// No description provided for @logTitle.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get logTitle;

  /// No description provided for @logClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get logClear;

  /// No description provided for @logCacheLoaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded from cache: {count} repositories (scan on startup is off)'**
  String logCacheLoaded(int count);

  /// No description provided for @logScheduledScan.
  ///
  /// In en, this message translates to:
  /// **'Scheduled scan…'**
  String get logScheduledScan;

  /// No description provided for @logScheduleEnabled.
  ///
  /// In en, this message translates to:
  /// **'Schedule enabled: every {minutes} min'**
  String logScheduleEnabled(int minutes);

  /// No description provided for @logStoppingScan.
  ///
  /// In en, this message translates to:
  /// **'Stopping the scan…'**
  String get logStoppingScan;

  /// No description provided for @logNoRoots.
  ///
  /// In en, this message translates to:
  /// **'Set project directories in settings'**
  String get logNoRoots;

  /// No description provided for @logNoSelection.
  ///
  /// In en, this message translates to:
  /// **'No projects selected'**
  String get logNoSelection;

  /// No description provided for @logScanStart.
  ///
  /// In en, this message translates to:
  /// **'Scanning: {roots}…'**
  String logScanStart(String roots);

  /// No description provided for @logScanDone.
  ///
  /// In en, this message translates to:
  /// **'Done: {count} repositories, OK {ok}, errors {errors}'**
  String logScanDone(int count, int ok, int errors);

  /// No description provided for @logScanDoneUpdates.
  ///
  /// In en, this message translates to:
  /// **'Done: {count} repositories, OK {ok}, errors {errors}, updates available: {updates}'**
  String logScanDoneUpdates(int count, int ok, int errors, int updates);

  /// No description provided for @logScanStopped.
  ///
  /// In en, this message translates to:
  /// **'Scan stopped: {done} of {total}, OK {ok}, errors {errors}'**
  String logScanStopped(int done, int total, int ok, int errors);

  /// No description provided for @logScanError.
  ///
  /// In en, this message translates to:
  /// **'Scan error: {error}'**
  String logScanError(String error);

  /// No description provided for @logOperationHeader.
  ///
  /// In en, this message translates to:
  /// **'=== {label} ({count}) ==='**
  String logOperationHeader(String label, int count);

  /// No description provided for @logProjectMessage.
  ///
  /// In en, this message translates to:
  /// **'[{name}] {message}'**
  String logProjectMessage(String name, String message);

  /// No description provided for @logProjectError.
  ///
  /// In en, this message translates to:
  /// **'[{name}] error: {error}'**
  String logProjectError(String name, String error);

  /// No description provided for @logSelectedWithUpdates.
  ///
  /// In en, this message translates to:
  /// **'Repositories with updates selected: {count}'**
  String logSelectedWithUpdates(int count);

  /// No description provided for @logShortcutCreated.
  ///
  /// In en, this message translates to:
  /// **'[{name}] shortcut created: {path}'**
  String logShortcutCreated(String name, String path);

  /// No description provided for @logShortcutFailed.
  ///
  /// In en, this message translates to:
  /// **'[{name}] failed to create shortcut: {error}'**
  String logShortcutFailed(String name, String error);

  /// No description provided for @logFinderError.
  ///
  /// In en, this message translates to:
  /// **'[{name}] Finder: {error}'**
  String logFinderError(String name, String error);

  /// No description provided for @logTerminalError.
  ///
  /// In en, this message translates to:
  /// **'[{name}] Terminal: {error}'**
  String logTerminalError(String name, String error);

  /// No description provided for @logNoRemoteLink.
  ///
  /// In en, this message translates to:
  /// **'[{name}] no origin link to open'**
  String logNoRemoteLink(String name);

  /// No description provided for @logOpenedRemote.
  ///
  /// In en, this message translates to:
  /// **'[{name}] opened in browser: {url}'**
  String logOpenedRemote(String name, String url);

  /// No description provided for @logOpenRemoteFailed.
  ///
  /// In en, this message translates to:
  /// **'[{name}] failed to open the link: {error}'**
  String logOpenRemoteFailed(String name, String error);

  /// No description provided for @deleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete repository?'**
  String get deleteDialogTitle;

  /// No description provided for @deleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'The «{name}» repository folder will be moved to the Trash. You can restore it from the Trash later.'**
  String deleteDialogBody(String name);

  /// No description provided for @deleteDialogDirtyWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: the repository has uncommitted changes — they will be moved to the Trash too.'**
  String get deleteDialogDirtyWarning;

  /// No description provided for @deleteDialogPath.
  ///
  /// In en, this message translates to:
  /// **'Path: {path}'**
  String deleteDialogPath(String path);

  /// No description provided for @cloneDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clone repository'**
  String get cloneDialogTitle;

  /// No description provided for @cloneDialogUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Repository URL'**
  String get cloneDialogUrlLabel;

  /// No description provided for @cloneDialogUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://host/group/repo.git or git@host:group/repo.git'**
  String get cloneDialogUrlHint;

  /// No description provided for @cloneDialogTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target directory'**
  String get cloneDialogTargetLabel;

  /// No description provided for @cloneDialogNoRoots.
  ///
  /// In en, this message translates to:
  /// **'Add a scan directory in settings first'**
  String get cloneDialogNoRoots;

  /// No description provided for @logDeleting.
  ///
  /// In en, this message translates to:
  /// **'[{name}] moving to Trash: {path}'**
  String logDeleting(String name, String path);

  /// No description provided for @logDeleted.
  ///
  /// In en, this message translates to:
  /// **'[{name}] moved to Trash'**
  String logDeleted(String name);

  /// No description provided for @logDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'[{name}] failed to delete: {error}'**
  String logDeleteFailed(String name, String error);

  /// No description provided for @logCloneStart.
  ///
  /// In en, this message translates to:
  /// **'Cloning {url} into {dir}…'**
  String logCloneStart(String url, String dir);

  /// No description provided for @logCloneDone.
  ///
  /// In en, this message translates to:
  /// **'Cloned: {name}'**
  String logCloneDone(String name);

  /// No description provided for @logCloneFailed.
  ///
  /// In en, this message translates to:
  /// **'Clone failed: {error}'**
  String logCloneFailed(String error);

  /// No description provided for @snackDeleted.
  ///
  /// In en, this message translates to:
  /// **'Repository moved to the Trash'**
  String get snackDeleted;

  /// No description provided for @snackDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String snackDeleteFailed(String error);

  /// No description provided for @snackCloneDone.
  ///
  /// In en, this message translates to:
  /// **'Repository cloned'**
  String get snackCloneDone;

  /// No description provided for @snackCloneFailed.
  ///
  /// In en, this message translates to:
  /// **'Clone failed: {error}'**
  String snackCloneFailed(String error);

  /// No description provided for @snackCloneInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not determine repository name from the URL'**
  String get snackCloneInvalidUrl;

  /// No description provided for @snackCloneExists.
  ///
  /// In en, this message translates to:
  /// **'A «{name}» folder already exists in the target directory'**
  String snackCloneExists(String name);

  /// No description provided for @snackShortcutCreated.
  ///
  /// In en, this message translates to:
  /// **'Shortcut created on the Desktop'**
  String get snackShortcutCreated;

  /// No description provided for @snackShortcutFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create shortcut: {error}'**
  String snackShortcutFailed(String error);

  /// No description provided for @snackNoRemote.
  ///
  /// In en, this message translates to:
  /// **'Repository has no origin URL'**
  String get snackNoRemote;

  /// No description provided for @snackOpenRemoteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open the link: {error}'**
  String snackOpenRemoteFailed(String error);

  /// No description provided for @labelPullMasterMain.
  ///
  /// In en, this message translates to:
  /// **'Pull main/master'**
  String get labelPullMasterMain;

  /// No description provided for @labelPull.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get labelPull;

  /// No description provided for @labelPush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get labelPush;

  /// No description provided for @labelSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get labelSync;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsScanDirs.
  ///
  /// In en, this message translates to:
  /// **'Scan directories'**
  String get settingsScanDirs;

  /// No description provided for @settingsAddDir.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get settingsAddDir;

  /// No description provided for @settingsAddDirTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add a directory to search for git repositories'**
  String get settingsAddDirTooltip;

  /// No description provided for @settingsNoDirs.
  ///
  /// In en, this message translates to:
  /// **'No directories selected'**
  String get settingsNoDirs;

  /// No description provided for @settingsRemoveDir.
  ///
  /// In en, this message translates to:
  /// **'Remove directory from the list'**
  String get settingsRemoveDir;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsViewMode.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get settingsViewMode;

  /// No description provided for @settingsViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get settingsViewList;

  /// No description provided for @settingsViewTree.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get settingsViewTree;

  /// No description provided for @settingsRemoteSection.
  ///
  /// In en, this message translates to:
  /// **'Remote (push)'**
  String get settingsRemoteSection;

  /// No description provided for @settingsHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get settingsHost;

  /// No description provided for @settingsHostHint.
  ///
  /// In en, this message translates to:
  /// **'gitlab.com / gitea.local / git.company.ru'**
  String get settingsHostHint;

  /// No description provided for @settingsHostHelper.
  ///
  /// In en, this message translates to:
  /// **'Any git system: GitLab, Gitea, Bitbucket, custom server'**
  String get settingsHostHelper;

  /// No description provided for @settingsGroup.
  ///
  /// In en, this message translates to:
  /// **'Group / namespace'**
  String get settingsGroup;

  /// No description provided for @settingsRemoteName.
  ///
  /// In en, this message translates to:
  /// **'Remote name for push'**
  String get settingsRemoteName;

  /// No description provided for @settingsToken.
  ///
  /// In en, this message translates to:
  /// **'Token (optional)'**
  String get settingsToken;

  /// No description provided for @settingsTokenHelper.
  ///
  /// In en, this message translates to:
  /// **'For the remote URL on push; stored locally'**
  String get settingsTokenHelper;

  /// No description provided for @settingsScanSection.
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get settingsScanSection;

  /// No description provided for @settingsRecursive.
  ///
  /// In en, this message translates to:
  /// **'Recursive scan'**
  String get settingsRecursive;

  /// No description provided for @settingsRecursiveSub.
  ///
  /// In en, this message translates to:
  /// **'Search for .git in nested folders'**
  String get settingsRecursiveSub;

  /// No description provided for @settingsAutoScan.
  ///
  /// In en, this message translates to:
  /// **'Scan on startup'**
  String get settingsAutoScan;

  /// No description provided for @settingsAutoScanSub.
  ///
  /// In en, this message translates to:
  /// **'Otherwise show data from the last scan cache'**
  String get settingsAutoScanSub;

  /// No description provided for @settingsCacheTtl.
  ///
  /// In en, this message translates to:
  /// **'Scan cache, min'**
  String get settingsCacheTtl;

  /// No description provided for @settingsCacheTtlHelper.
  ///
  /// In en, this message translates to:
  /// **'Fresh repositories (within this period) are not rescanned. 0 — always scan'**
  String get settingsCacheTtlHelper;

  /// No description provided for @settingsConcurrency.
  ///
  /// In en, this message translates to:
  /// **'Scan concurrency'**
  String get settingsConcurrency;

  /// No description provided for @settingsConcurrencyHelper.
  ///
  /// In en, this message translates to:
  /// **'How many repositories to scan at once (1–16)'**
  String get settingsConcurrencyHelper;

  /// No description provided for @settingsFetch.
  ///
  /// In en, this message translates to:
  /// **'fetch before pull'**
  String get settingsFetch;

  /// No description provided for @settingsStash.
  ///
  /// In en, this message translates to:
  /// **'stash before checkout'**
  String get settingsStash;

  /// No description provided for @settingsStashSub.
  ///
  /// In en, this message translates to:
  /// **'If there are uncommitted changes'**
  String get settingsStashSub;

  /// No description provided for @settingsPushTags.
  ///
  /// In en, this message translates to:
  /// **'Push tags'**
  String get settingsPushTags;

  /// No description provided for @settingsScheduleSection.
  ///
  /// In en, this message translates to:
  /// **'Scheduled scan'**
  String get settingsScheduleSection;

  /// No description provided for @settingsScheduleEnabled.
  ///
  /// In en, this message translates to:
  /// **'Run automatically'**
  String get settingsScheduleEnabled;

  /// No description provided for @settingsScheduleEnabledSub.
  ///
  /// In en, this message translates to:
  /// **'Periodically repeat the scan'**
  String get settingsScheduleEnabledSub;

  /// No description provided for @settingsInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval, min'**
  String get settingsInterval;

  /// No description provided for @settingsIntervalHelper.
  ///
  /// In en, this message translates to:
  /// **'How often to repeat the scan'**
  String get settingsIntervalHelper;

  /// No description provided for @fmtNever.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get fmtNever;

  /// No description provided for @fmtJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get fmtJustNow;

  /// No description provided for @fmtMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{{count} minute ago} other{{count} minutes ago}}'**
  String fmtMinutesAgo(int count);

  /// No description provided for @fmtHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{{count} hour ago} other{{count} hours ago}}'**
  String fmtHoursAgo(int count);

  /// No description provided for @fmtDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{{count} day ago} other{{count} days ago}}'**
  String fmtDaysAgo(int count);

  /// No description provided for @fmtWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{{count} week ago} other{{count} weeks ago}}'**
  String fmtWeeksAgo(int count);

  /// No description provided for @fmtMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{{count} month ago} other{{count} months ago}}'**
  String fmtMonthsAgo(int count);

  /// No description provided for @fmtYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{{count} year ago} other{{count} years ago}}'**
  String fmtYearsAgo(int count);

  /// No description provided for @unitB.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get unitB;

  /// No description provided for @unitKB.
  ///
  /// In en, this message translates to:
  /// **'KB'**
  String get unitKB;

  /// No description provided for @unitMB.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get unitMB;

  /// No description provided for @unitGB.
  ///
  /// In en, this message translates to:
  /// **'GB'**
  String get unitGB;

  /// No description provided for @unitTB.
  ///
  /// In en, this message translates to:
  /// **'TB'**
  String get unitTB;

  /// No description provided for @opNoDefaultBranch.
  ///
  /// In en, this message translates to:
  /// **'main/master branch not found'**
  String get opNoDefaultBranch;

  /// No description provided for @opUpdatesReceived.
  ///
  /// In en, this message translates to:
  /// **'updates received'**
  String get opUpdatesReceived;

  /// No description provided for @opUpToDate.
  ///
  /// In en, this message translates to:
  /// **'up to date'**
  String get opUpToDate;

  /// No description provided for @opNoBranchPush.
  ///
  /// In en, this message translates to:
  /// **'No main/master branch to push'**
  String get opNoBranchPush;

  /// No description provided for @opPushOk.
  ///
  /// In en, this message translates to:
  /// **'push ok'**
  String get opPushOk;

  /// No description provided for @opRemoteAlready.
  ///
  /// In en, this message translates to:
  /// **'remote {name} already points to the target system'**
  String opRemoteAlready(String name);

  /// No description provided for @opLogPull.
  ///
  /// In en, this message translates to:
  /// **'[{name}] pull {branch}'**
  String opLogPull(String name, String branch);

  /// No description provided for @opLogPush.
  ///
  /// In en, this message translates to:
  /// **'[{name}] push → remote'**
  String opLogPush(String name);

  /// No description provided for @opLogSync.
  ///
  /// In en, this message translates to:
  /// **'[{name}] sync (pull + push)'**
  String opLogSync(String name);

  /// No description provided for @scanErrorShort.
  ///
  /// In en, this message translates to:
  /// **'Scan error'**
  String get scanErrorShort;

  /// No description provided for @scanErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String scanErrorPrefix(String error);

  /// No description provided for @statusBranch.
  ///
  /// In en, this message translates to:
  /// **'branch {branch}'**
  String statusBranch(String branch);

  /// No description provided for @statusDefault.
  ///
  /// In en, this message translates to:
  /// **'default {branch}'**
  String statusDefault(String branch);

  /// No description provided for @statusDirty.
  ///
  /// In en, this message translates to:
  /// **'has changes'**
  String get statusDirty;

  /// No description provided for @statusUpdates.
  ///
  /// In en, this message translates to:
  /// **'updates: {count}'**
  String statusUpdates(int count);

  /// No description provided for @statusAhead.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String statusAhead(int count);

  /// No description provided for @statusBehind.
  ///
  /// In en, this message translates to:
  /// **'-{count}'**
  String statusBehind(int count);

  /// No description provided for @statusOk.
  ///
  /// In en, this message translates to:
  /// **'ok'**
  String get statusOk;

  /// No description provided for @errNoHomeDir.
  ///
  /// In en, this message translates to:
  /// **'Could not determine the home directory'**
  String get errNoHomeDir;

  /// No description provided for @errNoDesktop.
  ///
  /// In en, this message translates to:
  /// **'Desktop folder not found: {path}'**
  String errNoDesktop(String path);

  /// No description provided for @errOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'open failed with an error: {error}'**
  String errOpenFailed(String error);

  /// No description provided for @errOpenTerminalFailed.
  ///
  /// In en, this message translates to:
  /// **'open -a Terminal failed with an error: {error}'**
  String errOpenTerminalFailed(String error);

  /// No description provided for @errRepoNotFound.
  ///
  /// In en, this message translates to:
  /// **'Repository folder not found: {path}'**
  String errRepoNotFound(String path);

  /// No description provided for @errTrashFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not move to Trash: {error}'**
  String errTrashFailed(String error);

  /// No description provided for @exceptionScanCancelled.
  ///
  /// In en, this message translates to:
  /// **'Scan stopped'**
  String get exceptionScanCancelled;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
