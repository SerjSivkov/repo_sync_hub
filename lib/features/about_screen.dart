import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/update_checker.dart';
import '../widgets/update_dialog.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _info = info);
  }

  String get _versionLabel {
    final info = _info;
    if (info == null) return '…';
    return '${info.version} (${info.buildNumber})';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAssetText({
    required String title,
    required String assetPath,
  }) async {
    final text = await rootBundle.loadString(assetPath);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _LegalTextScreen(title: title, body: text),
      ),
    );
  }

  Future<void> _checkUpdate() async {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Проверка обновлений…'),
          ],
        ),
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final result = await checkForUpdateWithCache(prefs, ignoreCache: true);
    if (!mounted) return;
    Navigator.of(context).pop();

    if (result.hasError) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось проверить обновления')),
      );
      return;
    }

    if (result.info == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Установлена последняя версия')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => UpdateDialog(update: result.info!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('О приложении')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Repo Sync Hub',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Версия $_versionLabel',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'macOS-инструмент для массового обслуживания git-репозиториев',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Юридическое',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: const Text('Лицензия'),
                  subtitle: const Text('MIT License'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openAssetText(
                    title: 'Лицензия',
                    assetPath: 'LICENSE',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.library_books_outlined),
                  title: const Text('Лицензии открытого ПО'),
                  subtitle: const Text('Flutter и зависимости'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Repo Sync Hub',
                      applicationVersion: _versionLabel,
                      applicationIcon: Padding(
                        padding: const EdgeInsets.all(8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 48,
                            height: 48,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ссылки',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.system_update_alt_rounded),
                  title: const Text('Проверить обновления'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _checkUpdate,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code_rounded),
                  title: const Text('Проект на GitHub'),
                  subtitle: Text(
                    'github.com/SerjSivkov/repo_sync_hub',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                  onTap: () => _openUrl(
                    'https://github.com/SerjSivkov/repo_sync_hub',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openUrl('https://pay.cloudtips.ru/p/e57334e4'),
            icon: const Icon(Icons.favorite_rounded),
            label: const Text('Пожертвовать'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Поддержка разработки через CloudTips',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _LegalTextScreen extends StatelessWidget {
  const _LegalTextScreen({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: SelectableText(
          body.trim(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.45,
              ),
        ),
      ),
    );
  }
}
