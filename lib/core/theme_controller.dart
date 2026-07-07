import 'package:flutter/material.dart';

/// Глобальный переключатель темы. Меняется из настроек, слушается в [MaterialApp].
final ValueNotifier<ThemeMode> appThemeMode =
    ValueNotifier<ThemeMode>(ThemeMode.system);
