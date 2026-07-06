import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/app_settings.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key, required this.initial});

  final AppSettings initial;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late final TextEditingController _rootCtrl;
  late final TextEditingController _hostCtrl;
  late final TextEditingController _groupCtrl;
  late final TextEditingController _tokenCtrl;
  late final TextEditingController _remoteCtrl;
  late bool _recursive;
  late bool _autoStash;
  late bool _fetchBeforePull;
  late bool _pushTags;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _rootCtrl = TextEditingController(text: s.projectsRoot);
    _hostCtrl = TextEditingController(text: s.gitlabHost);
    _groupCtrl = TextEditingController(text: s.gitlabGroup);
    _tokenCtrl = TextEditingController(text: s.gitlabToken);
    _remoteCtrl = TextEditingController(text: s.gitlabRemoteName);
    _recursive = s.recursiveScan;
    _autoStash = s.autoStashBeforePull;
    _fetchBeforePull = s.fetchBeforePull;
    _pushTags = s.pushTags;
  }

  @override
  void dispose() {
    _rootCtrl.dispose();
    _hostCtrl.dispose();
    _groupCtrl.dispose();
    _tokenCtrl.dispose();
    _remoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Директория с git-проектами',
    );
    if (path != null) setState(() => _rootCtrl.text = path);
  }

  AppSettings _buildSettings() {
    return AppSettings(
      projectsRoot: _rootCtrl.text.trim(),
      gitlabHost: _hostCtrl.text.trim(),
      gitlabGroup: _groupCtrl.text.trim(),
      gitlabToken: _tokenCtrl.text.trim(),
      gitlabRemoteName: _remoteCtrl.text.trim().isEmpty ? 'origin' : _remoteCtrl.text.trim(),
      recursiveScan: _recursive,
      autoStashBeforePull: _autoStash,
      fetchBeforePull: _fetchBeforePull,
      pushTags: _pushTags,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Настройки', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _rootCtrl,
              decoration: InputDecoration(
                labelText: 'Директория проектов',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _pickDirectory,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hostCtrl,
              decoration: const InputDecoration(
                labelText: 'GitLab host',
                hintText: 'gitlab.com',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _groupCtrl,
              decoration: const InputDecoration(
                labelText: 'GitLab group',
                hintText: 'mobile',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remoteCtrl,
              decoration: const InputDecoration(
                labelText: 'Имя remote для push',
                hintText: 'origin',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'GitLab token (опционально)',
                helperText: 'Для настройки URL remote при push; хранится локально',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Рекурсивное сканирование'),
              subtitle: const Text('Искать .git во вложенных папках'),
              value: _recursive,
              onChanged: (v) => setState(() => _recursive = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('fetch перед pull'),
              value: _fetchBeforePull,
              onChanged: (v) => setState(() => _fetchBeforePull = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('stash перед checkout'),
              subtitle: const Text('Если есть незакоммиченные изменения'),
              value: _autoStash,
              onChanged: (v) => setState(() => _autoStash = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Push тегов'),
              value: _pushTags,
              onChanged: (v) => setState(() => _pushTags = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, _buildSettings()),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
