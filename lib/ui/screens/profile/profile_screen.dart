import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/report.dart';
import '../../../data/repositories/config_repository.dart';
import '../../../providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/large_title_page.dart';
import '../rewards/rewards_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _cloudName = TextEditingController();
  final _uploadPreset = TextEditingController();
  bool _nameReady = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadCloudinary);
  }

  Future<void> _loadCloudinary() async {
    final config = ref.read(configRepositoryProvider);
    final name = await config.get(ConfigKeys.cloudinaryCloudName);
    final preset = await config.get(ConfigKeys.cloudinaryUploadPreset);
    if (!mounted) return;
    setState(() {
      if (name.isNotEmpty) _cloudName.text = name;
      _uploadPreset.text = preset.isNotEmpty ? preset : 'arid_unsigned';
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _cloudName.dispose();
    _uploadPreset.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveName() async {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      _name.text = profile.displayName;
      return;
    }
    profile.displayName = name;
    await ref.read(userRepositoryProvider).save(profile);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    _toast('Name saved.');
  }

  Future<void> _savePhotoSettings() async {
    final config = ref.read(configRepositoryProvider);
    await config.set(ConfigKeys.cloudinaryCloudName, _cloudName.text.trim());
    await config.set(
      ConfigKeys.cloudinaryUploadPreset,
      _uploadPreset.text.trim().isEmpty
          ? 'arid_unsigned'
          : _uploadPreset.text.trim(),
    );
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    _toast('Photo upload settings saved.');
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final result = await ref.read(syncServiceProvider).syncPending();
      if (!mounted) return;
      _toast(
        result.message ??
            (result.failed == 0
                ? 'Synced ${result.uploaded} reports.'
                : 'Synced ${result.uploaded}. ${result.failed} failed — '
                      'they’ll retry automatically.'),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    final profile = ref.watch(profileProvider).valueOrNull;
    final reports = ref.watch(reportsProvider).valueOrNull ?? const <Report>[];
    final online = ref.watch(isOnlineProvider);
    final themeMode = ref.watch(themeModeProvider);
    if (profile != null && !_nameReady) {
      _name.text = profile.displayName;
      _nameReady = true;
    }
    final matrix = ref.watch(evaluationExportProvider).matrix(reports);
    final displayName = (profile?.displayName.trim().isNotEmpty ?? false)
        ? profile!.displayName.trim()
        : 'Reporter';

    return LargeTitlePage(
      title: 'Profile',
      slivers: [
        SliverList.list(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SectionCard(
                child: Row(
                  children: [
                    _Avatar(name: displayName),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${profile?.reportCount ?? 0} reports · '
                            '${profile?.totalPoints ?? 0} points',
                            style: TextStyle(
                              color: p.secondaryInk,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GroupedSection(
              header: 'Name',
              footer: 'Stored on this device and attached to your reports.',
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveName(),
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                    ),
                  ),
                ),
                GroupedRow(
                  title: 'Save name',
                  accent: true,
                  onTap: profile == null ? null : _saveName,
                ),
              ],
            ),
            GroupedSection(
              dividerIndent: 60,
              children: [
                GroupedRow(
                  leading: const IconTile(
                    icon: Icons.star_rounded,
                    color: AppColors.amber,
                  ),
                  title: 'Rewards',
                  value: '${profile?.totalPoints ?? 0} pts',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RewardsScreen()),
                  ),
                ),
                PopupMenuButton<ThemeMode>(
                  tooltip: 'Appearance',
                  initialValue: themeMode,
                  position: PopupMenuPosition.under,
                  onSelected: ref.read(themeModeProvider.notifier).setMode,
                  itemBuilder: (context) => [
                    for (final mode in [
                      ThemeMode.system,
                      ThemeMode.light,
                      ThemeMode.dark,
                    ])
                      CheckedPopupMenuItem(
                        value: mode,
                        checked: mode == themeMode,
                        child: Text(_modeLabel(mode)),
                      ),
                  ],
                  child: GroupedRow(
                    leading: const IconTile(
                      icon: Icons.contrast_rounded,
                      color: AppColors.slate,
                    ),
                    title: 'Appearance',
                    value: _modeLabel(themeMode),
                    trailing: Icon(
                      Icons.unfold_more_rounded,
                      size: 20,
                      color: p.tertiaryInk,
                    ),
                  ),
                ),
              ],
            ),
            GroupedSection(
              header: 'Sync',
              footer:
                  'Reports upload when you’re online. You can keep capturing '
                  'while they wait.',
              children: [
                GroupedRow(
                  title: 'Connection',
                  value: online ? 'Online' : 'Offline',
                  leading: Icon(
                    online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                    color: online ? p.low.fill : p.moderate.fill,
                  ),
                ),
                GroupedRow(
                  title: _syncing ? 'Syncing…' : 'Sync now',
                  accent: true,
                  onTap: _syncing ? null : _sync,
                  trailing: _syncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : null,
                ),
              ],
            ),
            GroupedSection(
              header: 'Photo upload',
              footer:
                  'Use the Cloudinary details from your project '
                  'administrator. Photos stay on this device until they sync.',
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: TextField(
                    controller: _cloudName,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Cloud name',
                      hintText: 'dhoi760j1',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: TextField(
                    controller: _uploadPreset,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Unsigned upload preset',
                      hintText: 'arid_unsigned',
                    ),
                  ),
                ),
                GroupedRow(
                  title: 'Save upload settings',
                  accent: true,
                  onTap: _savePhotoSettings,
                ),
              ],
            ),
            GroupedSection(
              header: 'Model evaluation',
              footer:
                  'Compares photo results with what you found on site '
                  '(Chapter III). Label actual results from History.',
              children: [
                GroupedRow(
                  title: 'Labeled reports',
                  value: '${matrix.labeled}',
                ),
                GroupedRow(
                  title: 'Accuracy',
                  value: matrix.labeled == 0
                      ? '—'
                      : '${(matrix.accuracy * 100).toStringAsFixed(1)}%',
                ),
                GroupedRow(
                  title: 'TP · TN · FP · FN',
                  value:
                      '${matrix.tp} · ${matrix.tn} · ${matrix.fp} · ${matrix.fn}',
                ),
                GroupedRow(
                  title: 'Export as CSV',
                  accent: true,
                  onTap: () => _export(reports, json: false),
                  trailing: Icon(
                    Icons.ios_share_rounded,
                    size: 20,
                    color: p.accent,
                  ),
                ),
                GroupedRow(
                  title: 'Export as JSON',
                  accent: true,
                  onTap: () => _export(reports, json: true),
                  trailing: Icon(
                    Icons.ios_share_rounded,
                    size: 20,
                    color: p.accent,
                  ),
                ),
              ],
            ),
            GroupedSection(
              header: 'About',
              children: [
                GroupedRow(title: 'Device ID', subtitle: profile?.id ?? '—'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static String _modeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Match device',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  Future<void> _export(List<Report> reports, {required bool json}) async {
    final service = ref.read(evaluationExportProvider);
    final contents = json ? service.toJson(reports) : service.toCsv(reports);
    final file = await service.writeFile(
      contents: contents,
      extension: json ? 'json' : 'csv',
    );
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final size = MediaQuery.textScalerOf(context).scale(56).clamp(56.0, 80.0);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: p.accentTint, shape: BoxShape.circle),
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: TextStyle(
            color: p.accentInk,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
