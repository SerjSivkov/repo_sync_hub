import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_settings.dart';
import 'core/app_theme.dart';
import 'core/locale_controller.dart';
import 'core/theme_controller.dart';
import 'features/splash_screen.dart';
import 'l10n/app_localizations.dart';
import 'utils/update_checker.dart';
import 'widgets/update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = await AppSettings.load();
  appThemeMode.value = settings.themeMode;
  appLocale.value = Locale(settings.languageCode);
  runApp(RepoSyncHubApp(prefs: prefs));
}

class RepoSyncHubApp extends StatefulWidget {
  const RepoSyncHubApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<RepoSyncHubApp> createState() => _RepoSyncHubAppState();
}

class _RepoSyncHubAppState extends State<RepoSyncHubApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final result = await checkForUpdateWithCache(widget.prefs);
    if (!mounted) return;
    if (result.info != null) {
      showDialog(
        context: context,
        builder: (_) => UpdateDialog(update: result.info!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: appLocale,
          builder: (context, locale, _) {
            return MaterialApp(
              onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
