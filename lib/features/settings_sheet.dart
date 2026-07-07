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
  late final TextEditingController _hostCtrl;
  late final TextEditingController _groupCtrl;
  late final TextEditingController _tokenCtrl;
  late final TextEditingController _remoteCtrl;
  late final TextEditingController _intervalCtrl;
  late final TextEditingController _cacheTtlCtrl;

  late List<String> _roots;
  late bool _recursive;
  late bool _autoStash;
  late bool _fetchBeforePull;
  late bool _pushTags;
  late ThemeMode _themeMode;
  late RepoViewMode _viewMode;
  late bool _autoScanOnStartup;
  late bool _scheduleEnabled;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _roots = List.of(s.projectsRoots);
    _hostCtrl = TextEditingController(text: s.remoteHost);
    _groupCtrl = TextEditingController(text: s.remoteGroup);
    _tokenCtrl = TextEditingController(text: s.remoteToken);
    _remoteCtrl = TextEditingController(text: s.remoteName);
    _intervalCtrl =
        TextEditingController(text: '${s.scheduleIntervalMinutes}');
    _cacheTtlCtrl = TextEditingController(text: '${s.scanCacheTtlMinutes}');
    _recursive = s.recursiveScan;
    _autoStash = s.autoStashBeforePull;
    _fetchBeforePull = s.fetchBeforePull;
    _pushTags = s.pushTags;
    _themeMode = s.themeMode;
    _viewMode = s.viewMode;
    _autoScanOnStartup = s.autoScanOnStartup;
    _scheduleEnabled = s.scheduleEnabled;
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _groupCtrl.dispose();
    _tokenCtrl.dispose();
    _remoteCtrl.dispose();
    _intervalCtrl.dispose();
    _cacheTtlCtrl.dispose();
    super.dispose();
  }

  Future<void> _addDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Директория с git-проектами',
    );
    if (path != null && !_roots.contains(path)) {
      setState(() => _roots.add(path));
    }
  }

  int _intOr(TextEditingController ctrl, int fallback, {int min = 1}) {
    final v = int.tryParse(ctrl.text.trim());
    if (v == null || v < min) return fallback;
    return v;
  }

  AppSettings _buildSettings() {
    return AppSettings(
      projectsRoots: _roots,
      remoteHost: _hostCtrl.text.trim(),
      remoteGroup: _groupCtrl.text.trim(),
      remoteToken: _tokenCtrl.text.trim(),
      remoteName:
          _remoteCtrl.text.trim().isEmpty ? 'origin' : _remoteCtrl.text.trim(),
      recursiveScan: _recursive,
      autoStashBeforePull: _autoStash,
      fetchBeforePull: _fetchBeforePull,
      pushTags: _pushTags,
      themeMode: _themeMode,
      viewMode: _viewMode,
      autoScanOnStartup: _autoScanOnStartup,
      scanCacheTtlMinutes: _intOr(_cacheTtlCtrl, 60, min: 0),
      scheduleEnabled: _scheduleEnabled,
      scheduleIntervalMinutes: _intOr(_intervalCtrl, 60, min: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            Text('Настройки', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            // --- Директории сканирования (несколько) ---
            Row(
              children: [
                Expanded(
                  child: Text('Директории сканирования',
                      style: theme.textTheme.titleSmall),
                ),
                Tooltip(
                  message: 'Добавить директорию для поиска git-репозиториев',
                  child: TextButton.icon(
                    onPressed: _addDirectory,
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить'),
                  ),
                ),
              ],
            ),
            if (_roots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Не выбрано ни одной директории',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ..._roots.map(
                (root) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(root, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Tooltip(
                    message: 'Убрать директорию из списка',
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _roots.remove(root)),
                    ),
                  ),
                ),
              ),

            const Divider(height: 24),

            // --- Внешний вид ---
            Text('Внешний вид', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _LabeledRow(
              label: 'Тема',
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Система'),
                    icon: Icon(Icons.brightness_auto),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Светлая'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Тёмная'),
                    icon: Icon(Icons.dark_mode),
                  ),
                ],
                selected: {_themeMode},
                onSelectionChanged: (s) => setState(() => _themeMode = s.first),
              ),
            ),
            const SizedBox(height: 12),
            _LabeledRow(
              label: 'Вид списка',
              child: SegmentedButton<RepoViewMode>(
                segments: const [
                  ButtonSegment(
                    value: RepoViewMode.list,
                    label: Text('Построчно'),
                    icon: Icon(Icons.view_list),
                  ),
                  ButtonSegment(
                    value: RepoViewMode.tree,
                    label: Text('Дерево'),
                    icon: Icon(Icons.account_tree),
                  ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (s) => setState(() => _viewMode = s.first),
              ),
            ),

            const Divider(height: 24),

            // --- Система-приёмник (не только GitLab) ---
            Text('Система-приёмник (push)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _hostCtrl,
              decoration: const InputDecoration(
                labelText: 'Хост',
                hintText: 'gitlab.com / gitea.local / git.company.ru',
                helperText:
                    'Любая git-система: GitLab, Gitea, Bitbucket, самописный сервер',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _groupCtrl,
              decoration: const InputDecoration(
                labelText: 'Группа / namespace',
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
                labelText: 'Токен (опционально)',
                helperText: 'Для URL remote при push; хранится локально',
              ),
            ),

            const Divider(height: 24),

            // --- Сканирование ---
            Text('Сканирование', style: theme.textTheme.titleSmall),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Рекурсивное сканирование'),
              subtitle: const Text('Искать .git во вложенных папках'),
              value: _recursive,
              onChanged: (v) => setState(() => _recursive = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Сканировать при запуске'),
              subtitle: const Text('Иначе — показ из кэша прошлого скана'),
              value: _autoScanOnStartup,
              onChanged: (v) => setState(() => _autoScanOnStartup = v),
            ),
            TextField(
              controller: _cacheTtlCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Кэш скана, мин',
                helperText:
                    'Свежие (в пределах этого срока) репозитории не пересканируются. 0 — всегда сканировать',
              ),
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

            const Divider(height: 24),

            // --- Расписание ---
            Text('Сканирование по расписанию',
                style: theme.textTheme.titleSmall),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Запускать автоматически'),
              subtitle: const Text('Периодический повтор сканирования'),
              value: _scheduleEnabled,
              onChanged: (v) => setState(() => _scheduleEnabled = v),
            ),
            TextField(
              controller: _intervalCtrl,
              enabled: _scheduleEnabled,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Интервал, мин',
                helperText: 'Как часто повторять сканирование',
              ),
            ),

            const SizedBox(height: 20),
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

class _LabeledRow extends StatelessWidget {
  const _LabeledRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 96, child: Text(label)),
        Expanded(child: Align(alignment: Alignment.centerLeft, child: child)),
      ],
    );
  }
}
