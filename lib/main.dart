import 'package:flutter/material.dart';

import 'core/app_settings.dart';
import 'core/app_theme.dart';
import 'core/theme_controller.dart';
import 'features/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  appThemeMode.value = settings.themeMode;
  runApp(const RepoSyncHubApp());
}

class RepoSyncHubApp extends StatelessWidget {
  const RepoSyncHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Repo Sync Hub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
