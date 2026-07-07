// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Repo Sync Hub';

  @override
  String get splashSubtitle => 'Git-репозитории · pull · GitLab';

  @override
  String get actionScan => 'Сканировать';

  @override
  String get actionStop => 'Остановить';

  @override
  String get actionPull => 'Pull';

  @override
  String get actionPush => 'Push';

  @override
  String get actionSync => 'Sync';

  @override
  String get actionSave => 'Сохранить';

  @override
  String get actionDirectories => 'Директории';

  @override
  String get tooltipScanStart =>
      'Просканировать директории и обновить статусы репозиториев';

  @override
  String get tooltipScanStop => 'Прервать текущее сканирование';

  @override
  String get tooltipPull =>
      'Стянуть обновления (pull main/master) для выбранных репозиториев';

  @override
  String get tooltipPush =>
      'Отправить (push) выбранные репозитории в систему-приёмник';

  @override
  String get tooltipSync => 'Синхронизировать: pull, затем push для выбранных';

  @override
  String get tooltipDirectories =>
      'Открыть настройки и выбрать директории сканирования';

  @override
  String get tooltipSettings =>
      'Настройки: директории, приёмник, тема, расписание';

  @override
  String tooltipThemeCycle(String theme) {
    return 'Тема: $theme (нажмите для переключения)';
  }

  @override
  String get tooltipShowTree => 'Показать деревом';

  @override
  String get tooltipShowList => 'Показать построчно';

  @override
  String get tooltipLastScan => 'Последнее сканирование';

  @override
  String tooltipLanguageCycle(String lang) {
    return 'Язык: $lang (нажмите для переключения)';
  }

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get themeSystem => 'системная';

  @override
  String get themeLight => 'светлая';

  @override
  String get themeDark => 'тёмная';

  @override
  String get selectAll => 'Выбрать все';

  @override
  String get selectWithUpdatesTooltip =>
      'Выбрать только репозитории с обновлениями';

  @override
  String get menuActions => 'Действия с репозиторием';

  @override
  String get menuPull => 'Pull main/master';

  @override
  String get menuPush => 'Push в приёмник';

  @override
  String get menuSync => 'Sync (pull + push)';

  @override
  String get menuOpenRemote => 'Открыть origin в браузере';

  @override
  String get menuShortcut => 'Создать ярлык на Рабочем столе';

  @override
  String get menuFinder => 'Показать в Finder';

  @override
  String get menuTerminal => 'Открыть в Терминале';

  @override
  String tooltipOpenRemote(String url) {
    return 'Открыть origin в браузере: $url';
  }

  @override
  String get tooltipNoRemote => 'У репозитория нет origin-ссылки';

  @override
  String get tooltipCommitCount => 'Количество коммитов';

  @override
  String get tooltipRepoSize => 'Размер репозитория на диске';

  @override
  String get tooltipLastPullNever =>
      'Обновления через приложение ещё не стягивались';

  @override
  String tooltipLastPull(String date) {
    return 'Последнее стягивание: $date';
  }

  @override
  String get tooltipHasUpdates => 'Доступны обновления на remote';

  @override
  String get tooltipReceived => 'Обновления успешно подтянуты';

  @override
  String get tooltipAbandoned => 'Не обновлялся больше года';

  @override
  String get badgeUpdatesShort => 'обновления';

  @override
  String get badgeReceived => 'получены';

  @override
  String get labelAbandoned => 'заброшен';

  @override
  String get labelDirty => 'dirty';

  @override
  String get unknownBranch => '?';

  @override
  String branchLine(String current, String defaultBranch) {
    return '$current · default $defaultBranch';
  }

  @override
  String get groupErrors => '⚠ Ошибки';

  @override
  String get groupNoGroup => '(без группы)';

  @override
  String get groupRoot => '(в корне)';

  @override
  String groupUpdatesBadge(int count) {
    return '↓$count';
  }

  @override
  String get tooltipGroupUpdates => 'Доступно обновлений в группе';

  @override
  String groupAbandonedBadge(int count) {
    return 'заброшено: $count';
  }

  @override
  String get tooltipGroupAbandoned => 'Репозитории без обновлений больше года';

  @override
  String get tooltipCollapseGroup => 'Свернуть группу — скрыть репозитории';

  @override
  String get tooltipExpandGroup => 'Развернуть группу';

  @override
  String updatesBadgeCount(int count) {
    return 'обновлений: $count';
  }

  @override
  String get rootsNone => 'Директории не заданы';

  @override
  String rootsMultiple(int count, String roots) {
    return '$count директорий: $roots';
  }

  @override
  String scanRelative(String date) {
    return 'скан: $date';
  }

  @override
  String counter(int selected, int total) {
    return '$selected / $total';
  }

  @override
  String get progressStopping => 'Остановка…';

  @override
  String progressScanningName(String name) {
    return 'Сканирование: $name';
  }

  @override
  String get progressSearching => 'Поиск репозиториев…';

  @override
  String get progressScanning => 'Сканирование…';

  @override
  String progressOkErrors(int ok, int errors) {
    return 'OK: $ok · ошибок: $errors';
  }

  @override
  String doneStopped(int ok, int errors, int done, int total) {
    return 'Остановлено: OK $ok, ошибок $errors, просканировано $done/$total';
  }

  @override
  String doneScan(int ok, int errors) {
    return 'Сканирование: OK $ok, ошибок $errors';
  }

  @override
  String get emptyNoRoots => 'Выберите директории с git-проектами в настройках';

  @override
  String get emptyNotFound => 'Репозитории не найдены — запустите сканирование';

  @override
  String get logTitle => 'Лог';

  @override
  String get logClear => 'Очистить';

  @override
  String logCacheLoaded(int count) {
    return 'Загружено из кэша: $count репозиториев (сканирование при запуске отключено)';
  }

  @override
  String get logScheduledScan => 'Плановое сканирование (по расписанию)…';

  @override
  String logScheduleEnabled(int minutes) {
    return 'Расписание включено: каждые $minutes мин';
  }

  @override
  String get logStoppingScan => 'Остановка сканирования…';

  @override
  String get logNoRoots => 'Укажите директории с проектами в настройках';

  @override
  String get logNoSelection => 'Нет выбранных проектов';

  @override
  String logScanStart(String roots) {
    return 'Сканирование: $roots…';
  }

  @override
  String logScanDone(int count, int ok, int errors) {
    return 'Готово: $count репозиториев, OK $ok, ошибок $errors';
  }

  @override
  String logScanDoneUpdates(int count, int ok, int errors, int updates) {
    return 'Готово: $count репозиториев, OK $ok, ошибок $errors, обновлений доступно: $updates';
  }

  @override
  String logScanStopped(int done, int total, int ok, int errors) {
    return 'Сканирование остановлено: $done из $total, OK $ok, ошибок $errors';
  }

  @override
  String logScanError(String error) {
    return 'Ошибка сканирования: $error';
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
    return '[$name] ошибка: $error';
  }

  @override
  String logSelectedWithUpdates(int count) {
    return 'Выбрано репозиториев с обновлениями: $count';
  }

  @override
  String logShortcutCreated(String name, String path) {
    return '[$name] ярлык создан: $path';
  }

  @override
  String logShortcutFailed(String name, String error) {
    return '[$name] не удалось создать ярлык: $error';
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
    return '[$name] нет ссылки origin для открытия';
  }

  @override
  String logOpenedRemote(String name, String url) {
    return '[$name] открыт в браузере: $url';
  }

  @override
  String logOpenRemoteFailed(String name, String error) {
    return '[$name] не удалось открыть ссылку: $error';
  }

  @override
  String get snackShortcutCreated => 'Ярлык создан на Рабочем столе';

  @override
  String snackShortcutFailed(String error) {
    return 'Не удалось создать ярлык: $error';
  }

  @override
  String get snackNoRemote => 'У репозитория нет origin-ссылки';

  @override
  String snackOpenRemoteFailed(String error) {
    return 'Не удалось открыть ссылку: $error';
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
  String get settingsTitle => 'Настройки';

  @override
  String get settingsScanDirs => 'Директории сканирования';

  @override
  String get settingsAddDir => 'Добавить';

  @override
  String get settingsAddDirTooltip =>
      'Добавить директорию для поиска git-репозиториев';

  @override
  String get settingsNoDirs => 'Не выбрано ни одной директории';

  @override
  String get settingsRemoveDir => 'Убрать директорию из списка';

  @override
  String get settingsAppearance => 'Внешний вид';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeSystem => 'Система';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsViewMode => 'Вид списка';

  @override
  String get settingsViewList => 'Построчно';

  @override
  String get settingsViewTree => 'Дерево';

  @override
  String get settingsRemoteSection => 'Система-приёмник (push)';

  @override
  String get settingsHost => 'Хост';

  @override
  String get settingsHostHint => 'gitlab.com / gitea.local / git.company.ru';

  @override
  String get settingsHostHelper =>
      'Любая git-система: GitLab, Gitea, Bitbucket, самописный сервер';

  @override
  String get settingsGroup => 'Группа / namespace';

  @override
  String get settingsRemoteName => 'Имя remote для push';

  @override
  String get settingsToken => 'Токен (опционально)';

  @override
  String get settingsTokenHelper =>
      'Для URL remote при push; хранится локально';

  @override
  String get settingsScanSection => 'Сканирование';

  @override
  String get settingsRecursive => 'Рекурсивное сканирование';

  @override
  String get settingsRecursiveSub => 'Искать .git во вложенных папках';

  @override
  String get settingsAutoScan => 'Сканировать при запуске';

  @override
  String get settingsAutoScanSub => 'Иначе — показ из кэша прошлого скана';

  @override
  String get settingsCacheTtl => 'Кэш скана, мин';

  @override
  String get settingsCacheTtlHelper =>
      'Свежие (в пределах этого срока) репозитории не пересканируются. 0 — всегда сканировать';

  @override
  String get settingsConcurrency => 'Параллелизм скана';

  @override
  String get settingsConcurrencyHelper =>
      'Сколько репозиториев сканировать одновременно (1–16)';

  @override
  String get settingsFetch => 'fetch перед pull';

  @override
  String get settingsStash => 'stash перед checkout';

  @override
  String get settingsStashSub => 'Если есть незакоммиченные изменения';

  @override
  String get settingsPushTags => 'Push тегов';

  @override
  String get settingsScheduleSection => 'Сканирование по расписанию';

  @override
  String get settingsScheduleEnabled => 'Запускать автоматически';

  @override
  String get settingsScheduleEnabledSub => 'Периодический повтор сканирования';

  @override
  String get settingsInterval => 'Интервал, мин';

  @override
  String get settingsIntervalHelper => 'Как часто повторять сканирование';

  @override
  String get fmtNever => 'никогда';

  @override
  String get fmtJustNow => 'только что';

  @override
  String fmtMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мин назад',
      many: '$count мин назад',
      few: '$count мин назад',
      one: '$count мин назад',
    );
    return '$_temp0';
  }

  @override
  String fmtHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ч назад',
      many: '$count ч назад',
      few: '$count ч назад',
      one: '$count ч назад',
    );
    return '$_temp0';
  }

  @override
  String fmtDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дн назад',
      many: '$count дн назад',
      few: '$count дн назад',
      one: '$count дн назад',
    );
    return '$_temp0';
  }

  @override
  String fmtWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count нед назад',
      many: '$count нед назад',
      few: '$count нед назад',
      one: '$count нед назад',
    );
    return '$_temp0';
  }

  @override
  String fmtMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мес назад',
      many: '$count мес назад',
      few: '$count мес назад',
      one: '$count мес назад',
    );
    return '$_temp0';
  }

  @override
  String fmtYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count лет назад',
      many: '$count лет назад',
      few: '$count года назад',
      one: '$count год назад',
    );
    return '$_temp0';
  }

  @override
  String get unitB => 'Б';

  @override
  String get unitKB => 'КБ';

  @override
  String get unitMB => 'МБ';

  @override
  String get unitGB => 'ГБ';

  @override
  String get unitTB => 'ТБ';

  @override
  String get opNoDefaultBranch => 'Не найдена ветка main/master';

  @override
  String get opUpdatesReceived => 'получены обновления';

  @override
  String get opUpToDate => 'уже актуально';

  @override
  String get opNoBranchPush => 'Нет ветки main/master для push';

  @override
  String get opPushOk => 'push ok';

  @override
  String opRemoteAlready(String name) {
    return 'remote $name уже указывает на систему-приёмник';
  }

  @override
  String opLogPull(String name, String branch) {
    return '[$name] pull $branch';
  }

  @override
  String opLogPush(String name) {
    return '[$name] push → приёмник';
  }

  @override
  String opLogSync(String name) {
    return '[$name] sync (pull + push)';
  }

  @override
  String get scanErrorShort => 'Ошибка сканирования';

  @override
  String scanErrorPrefix(String error) {
    return 'Ошибка: $error';
  }

  @override
  String statusBranch(String branch) {
    return 'ветка $branch';
  }

  @override
  String statusDefault(String branch) {
    return 'default $branch';
  }

  @override
  String get statusDirty => 'есть изменения';

  @override
  String statusUpdates(int count) {
    return 'обновлений: $count';
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
  String get errNoHomeDir => 'Не удалось определить домашнюю директорию';

  @override
  String errNoDesktop(String path) {
    return 'Папка «Рабочий стол» не найдена: $path';
  }

  @override
  String errOpenFailed(String error) {
    return 'open завершился с ошибкой: $error';
  }

  @override
  String errOpenTerminalFailed(String error) {
    return 'open -a Terminal завершился с ошибкой: $error';
  }

  @override
  String get exceptionScanCancelled => 'Сканирование остановлено';
}
