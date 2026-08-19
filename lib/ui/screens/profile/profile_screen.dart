import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/report.dart';
import '../../../data/repositories/config_repository.dart';
import '../../../providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
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

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final reports = ref.watch(reportsProvider).valueOrNull ?? const <Report>[];
    final online = ref.watch(isOnlineProvider);
    if (profile != null && !_nameReady) {
      _name.text = profile.displayName;
      _nameReady = true;
    }
    final matrix = ref.watch(evaluationExportProvider).matrix(reports);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OfflineBanner(online: online),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Display name'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: profile == null
                      ? null
                      : () async {
                          profile.displayName = _name.text.trim().isEmpty
                              ? profile.displayName
                              : _name.text.trim();
                          await ref.read(userRepositoryProvider).save(profile);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Name saved on this device.')),
                          );
                        },
                  child: const Text('Save name'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Device ID: ${profile?.id ?? '—'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.divider),
            ),
            leading: const Icon(Icons.stars_outlined, color: AppColors.secondary),
            title: const Text('Rewards & points'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RewardsScreen()),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Photo hosting (Cloudinary, free)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Firebase Storage is not used. Create a free Cloudinary account (no credit card), add an Unsigned upload preset, then paste the cloud name and preset here. Photos still save on-device first.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cloudName,
                  decoration: const InputDecoration(
                    labelText: 'Cloud name',
                    hintText: 'dhoi760j1',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _uploadPreset,
                  decoration: const InputDecoration(
                    labelText: 'Unsigned upload preset',
                    hintText: 'arid_unsigned',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    await ref.read(configRepositoryProvider).set(
                      ConfigKeys.cloudinaryCloudName,
                      _cloudName.text.trim(),
                    );
                    await ref.read(configRepositoryProvider).set(
                      ConfigKeys.cloudinaryUploadPreset,
                      _uploadPreset.text.trim().isEmpty
                          ? 'arid_unsigned'
                          : _uploadPreset.text.trim(),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cloudinary settings saved on this device.'),
                      ),
                    );
                  },
                  child: const Text('Save Cloudinary settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cloud sync',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sync never blocks capture or map. Metadata goes to Firestore; photos go to Cloudinary. If either is missing, reports stay queued locally.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    final result =
                        await ref.read(syncServiceProvider).syncPending();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.message ??
                              'Uploaded ${result.uploaded}, failed ${result.failed}',
                        ),
                      ),
                    );
                  },
                  child: const Text('Sync now'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Evaluation export (Chapter III)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Labeled ${matrix.labeled}  ·  TP ${matrix.tp}  TN ${matrix.tn}  FP ${matrix.fp}  FN ${matrix.fn}\n'
                  'Accuracy ${(matrix.accuracy * 100).toStringAsFixed(1)}%  ·  unlabeled ${matrix.unlabeled}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _export(reports, json: false),
                  child: const Text('Export CSV'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _export(reports, json: true),
                  child: const Text('Export JSON'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
