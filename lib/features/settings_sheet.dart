import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/app_settings.dart';
import '../l10n/app_localizations.dart';

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
  late final TextEditingController _concurrencyCtrl;

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
    _concurrencyCtrl = TextEditingController(text: '${s.scanConcurrency}');
    _recursive = s.recursiveScan;
    _autoStash = s.autoStashBeforePull;
    _fetchBeforePull = s.fetchBeforePull;
    _pushTags = s.pushTags;
    _themeMode = s.themeMode;
    _viewMode = s.viewMode;
    _languageCode = s.languageCode;
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
    _concurrencyCtrl.dispose();
    super.dispose();
  }

  late String _languageCode;

  Future<void> _addDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: AppLocalizations.of(context).settingsAddDirTooltip,
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
      languageCode: _languageCode,
      autoScanOnStartup: _autoScanOnStartup,
      scanCacheTtlMinutes: _intOr(_cacheTtlCtrl, 60, min: 0),
      scanConcurrency: _intOr(_concurrencyCtrl, 4, min: 1).clamp(1, 16).toInt(),
      scheduleEnabled: _scheduleEnabled,
      scheduleIntervalMinutes: _intOr(_intervalCtrl, 60, min: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
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
            Text(l10n.settingsTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            // --- Директории сканирования (несколько) ---
            Row(
              children: [
                Expanded(
                  child: Text(l10n.settingsScanDirs,
                      style: theme.textTheme.titleSmall),
                ),
                Tooltip(
                  message: l10n.settingsAddDirTooltip,
                  child: TextButton.icon(
                    onPressed: _addDirectory,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.settingsAddDir),
                  ),
                ),
              ],
            ),
            if (_roots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.settingsNoDirs,
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
                    message: l10n.settingsRemoveDir,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _roots.remove(root)),
                    ),
                  ),
                ),
              ),

            const Divider(height: 24),

            // --- Внешний вид ---
            Text(l10n.settingsAppearance, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _LabeledRow(
              label: l10n.settingsLanguage,
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'ru',
                    label: Text(l10n.languageRussian),
                  ),
                  ButtonSegment(
                    value: 'en',
                    label: Text(l10n.languageEnglish),
                  ),
                ],
                selected: {_languageCode},
                onSelectionChanged: (s) =>
                    setState(() => _languageCode = s.first),
              ),
            ),
            const SizedBox(height: 12),
            _LabeledRow(
              label: l10n.settingsTheme,
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.settingsThemeSystem),
                    icon: const Icon(Icons.brightness_auto),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.settingsThemeLight),
                    icon: const Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.settingsThemeDark),
                    icon: const Icon(Icons.dark_mode),
                  ),
                ],
                selected: {_themeMode},
                onSelectionChanged: (s) => setState(() => _themeMode = s.first),
              ),
            ),
            const SizedBox(height: 12),
            _LabeledRow(
              label: l10n.settingsViewMode,
              child: SegmentedButton<RepoViewMode>(
                segments: [
                  ButtonSegment(
                    value: RepoViewMode.list,
                    label: Text(l10n.settingsViewList),
                    icon: const Icon(Icons.view_list),
                  ),
                  ButtonSegment(
                    value: RepoViewMode.tree,
                    label: Text(l10n.settingsViewTree),
                    icon: const Icon(Icons.account_tree),
                  ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (s) => setState(() => _viewMode = s.first),
              ),
            ),

            const Divider(height: 24),

            // --- Система-приёмник (не только GitLab) ---
            Text(l10n.settingsRemoteSection, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _hostCtrl,
              decoration: InputDecoration(
                labelText: l10n.settingsHost,
                hintText: l10n.settingsHostHint,
                helperText: l10n.settingsHostHelper,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _groupCtrl,
              decoration: InputDecoration(
                labelText: l10n.settingsGroup,
                hintText: 'mobile',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remoteCtrl,
              decoration: InputDecoration(
                labelText: l10n.settingsRemoteName,
                hintText: 'origin',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.settingsToken,
                helperText: l10n.settingsTokenHelper,
              ),
            ),

            const Divider(height: 24),

            // --- Сканирование ---
            Text(l10n.settingsScanSection, style: theme.textTheme.titleSmall),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsRecursive),
              subtitle: Text(l10n.settingsRecursiveSub),
              value: _recursive,
              onChanged: (v) => setState(() => _recursive = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsAutoScan),
              subtitle: Text(l10n.settingsAutoScanSub),
              value: _autoScanOnStartup,
              onChanged: (v) => setState(() => _autoScanOnStartup = v),
            ),
            TextField(
              controller: _cacheTtlCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.settingsCacheTtl,
                helperText: l10n.settingsCacheTtlHelper,
              ),
            ),
            TextField(
              controller: _concurrencyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.settingsConcurrency,
                helperText: l10n.settingsConcurrencyHelper,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsFetch),
              value: _fetchBeforePull,
              onChanged: (v) => setState(() => _fetchBeforePull = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsStash),
              subtitle: Text(l10n.settingsStashSub),
              value: _autoStash,
              onChanged: (v) => setState(() => _autoStash = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsPushTags),
              value: _pushTags,
              onChanged: (v) => setState(() => _pushTags = v),
            ),

            const Divider(height: 24),

            // --- Расписание ---
            Text(l10n.settingsScheduleSection,
                style: theme.textTheme.titleSmall),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsScheduleEnabled),
              subtitle: Text(l10n.settingsScheduleEnabledSub),
              value: _scheduleEnabled,
              onChanged: (v) => setState(() => _scheduleEnabled = v),
            ),
            TextField(
              controller: _intervalCtrl,
              enabled: _scheduleEnabled,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.settingsInterval,
                helperText: l10n.settingsIntervalHelper,
              ),
            ),

            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context, _buildSettings()),
              child: Text(l10n.actionSave),
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
