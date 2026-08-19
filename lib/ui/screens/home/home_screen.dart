import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/report.dart';
import '../../../providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/arid_logo.dart';
import '../../widgets/common.dart';
import '../rewards/rewards_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsProvider).valueOrNull ?? const <Report>[];
    final profile = ref.watch(profileProvider).valueOrNull;
    final online = ref.watch(isOnlineProvider);
    final pending = reports
        .where((r) => r.syncStatus != SyncStatus.synced)
        .length;

    return Scaffold(
      appBar: AppBar(title: const AridBrandTitle()),
      body: Column(
        children: [
          OfflineBanner(online: online),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Autonomous Risk Identification',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'On-device dengue vector breeding-site mapping. Everything on this screen is local.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RewardsScreen()),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.stars_outlined,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${profile?.totalPoints ?? 0} points',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              '${profile?.reportCount ?? 0} reports  ·  ${profile?.verifiedPoints ?? 0} verified',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Pending sync',
                        value: '$pending',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        label: 'Streak',
                        value: '${profile?.currentStreak ?? 0}d',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Recent reports',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (reports.isEmpty)
                  const SectionCard(
                    child: Text(
                      'No reports yet. Open Capture to photograph a possible breeding site. Classification, GPS, and points all save on this device.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...reports.take(8).map(_HomeReportTile.new),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _HomeReportTile extends StatelessWidget {
  const _HomeReportTile(this.report);

  final Report report;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            RiskBadge(level: report.riskLevel, compact: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.classification == Classification.breeding
                        ? 'Breeding site'
                        : 'Non-breeding',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    DateFormat('MMM d, h:mm a').format(report.capturedAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SyncStatusChip(status: report.syncStatus),
          ],
        ),
      ),
    );
  }
}
