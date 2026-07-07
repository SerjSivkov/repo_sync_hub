import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Глобальный переключатель языка. Меняется из настроек/кнопки,
/// слушается в [MaterialApp]. По образцу [appThemeMode].
final ValueNotifier<Locale> appLocale =
    ValueNotifier<Locale>(const Locale('ru'));

/// Локализация для кода без [BuildContext] (сервисы, форматтеры).
/// Использует текущий выбранный язык из [appLocale].
AppLocalizations get l10n => lookupAppLocalizations(appLocale.value);
