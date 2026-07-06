import 'package:flutter/material.dart';

import 'features/home_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFC6D26)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
