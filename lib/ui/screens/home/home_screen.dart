import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/report.dart';
import '../../../providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/arid_logo.dart';
import '../../widgets/common.dart';
import '../../widgets/theme_mode_button.dart';
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
    final high = reports.where((r) => r.riskLevel == RiskLevel.red).length;
    final moderate = reports
        .where((r) => r.riskLevel == RiskLevel.yellow)
        .length;
    final low = reports.where((r) => r.riskLevel == RiskLevel.green).length;

    return Scaffold(
      appBar: AppBar(
        title: const AridBrandTitle(),
        actions: const [ThemeModeButton()],
      ),
      body: Column(
        children: [
          OfflineBanner(online: online),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'FIELD OVERVIEW',
                  style: TextStyle(
                    color: context.aridMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Local activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Reports, classification, GPS tags, and points remain available without a connection.',
                  style: TextStyle(color: context.aridMuted),
                ),
                const SizedBox(height: 16),
                _RiskSnapshot(
                  total: reports.length,
                  high: high,
                  moderate: moderate,
                  low: low,
                ),
                const SizedBox(height: 12),
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
                              style: TextStyle(color: context.aridMuted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: context.aridMuted),
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
                const _SectionLabel('Recent reports'),
                const SizedBox(height: 8),
                if (reports.isEmpty)
                  SectionCard(
                    child: Text(
                      'No reports yet. Open Capture to photograph a possible breeding site. Classification, GPS, and points all save on this device.',
                      style: TextStyle(color: context.aridMuted),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.aridInk,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _RiskSnapshot extends StatelessWidget {
  const _RiskSnapshot({
    required this.total,
    required this.high,
    required this.moderate,
    required this.low,
  });

  final int total;
  final int high;
  final int moderate;
  final int low;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$total', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            'reports on this device',
            style: TextStyle(color: context.aridMuted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 6,
              child: total == 0
                  ? ColoredBox(color: context.aridSunken)
                  : Row(
                      children: [
                        if (high > 0)
                          Expanded(
                            flex: high,
                            child: const ColoredBox(color: AppColors.riskRed),
                          ),
                        if (moderate > 0)
                          Expanded(
                            flex: moderate,
                            child: const ColoredBox(
                              color: AppColors.riskYellow,
                            ),
                          ),
                        if (low > 0)
                          Expanded(
                            flex: low,
                            child: const ColoredBox(color: AppColors.riskGreen),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          _RiskRow(label: 'High risk', value: high, color: AppColors.riskRed),
          const SizedBox(height: 8),
          _RiskRow(
            label: 'Moderate',
            value: moderate,
            color: AppColors.riskYellow,
          ),
          const SizedBox(height: 8),
          _RiskRow(label: 'Low risk', value: low, color: AppColors.riskGreen),
        ],
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  const _RiskRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: context.aridMuted, fontSize: 13),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
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
          Text(label, style: TextStyle(color: context.aridMuted)),
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
                    style: TextStyle(color: context.aridMuted, fontSize: 12),
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
