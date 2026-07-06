import 'package:flutter/material.dart';

import 'features/splash_screen.dart';

void main() {
  runApp(const RepoSyncHubApp());
}

class RepoSyncHubApp extends StatelessWidget {
  const RepoSyncHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Repo Sync Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B6CFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
