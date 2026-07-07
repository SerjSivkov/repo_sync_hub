import 'package:flutter/material.dart';

/// Светлая и тёмная темы приложения.
class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF5B6CFF);

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );

  static ThemeData get dark => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF14151A),
      );
}
