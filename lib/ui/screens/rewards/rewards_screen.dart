import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/report.dart';
import '../../../providers.dart';
import '../../../services/rewards/points_rules.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final reports = ref.watch(reportsProvider).valueOrNull ?? const <Report>[];
    final rules = ref.watch(pointsRulesProvider).valueOrNull ?? const PointsRules();
    final redCount =
        reports.where((r) => r.riskLevel == RiskLevel.red).length;
    final earned = badgesFor(
      reportCount: profile?.reportCount ?? 0,
      totalPoints: profile?.totalPoints ?? 0,
      redCount: redCount,
      streak: profile?.currentStreak ?? 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile?.totalPoints ?? 0}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Text(
                  'Local points (instant, on-device)',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  '${profile?.verifiedPoints ?? 0} verified after sync  ·  '
                  '${profile?.reportCount ?? 0} reports  ·  '
                  'streak ${profile?.currentStreak ?? 0}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('How points are earned', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SectionCard(
            child: Column(
              children: [
                for (final row in rules.documented)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(row.key)),
                        Text(
                          row.value,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Stored in the local config table (AppConfig). Tune values later without changing UI code. Provisional points appear immediately; they become verified when sync succeeds.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Badges', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...earned.map(
            (badge) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SectionCard(
                child: Row(
                  children: [
                    Icon(
                      badge.earned ? Icons.verified_outlined : Icons.lock_outline,
                      color: badge.earned
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            badge.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            badge.description,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
