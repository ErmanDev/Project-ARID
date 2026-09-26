import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/report.dart';
import '../../../providers.dart';
import '../../../services/rewards/points_rules.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/large_title_page.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.arid;
    final profile = ref.watch(profileProvider).valueOrNull;
    final reports = ref.watch(reportsProvider).valueOrNull ?? const <Report>[];
    final rules =
        ref.watch(pointsRulesProvider).valueOrNull ?? const PointsRules();
    final redCount = reports.where((r) => r.riskLevel == RiskLevel.red).length;
    final badges = badgesFor(
      reportCount: profile?.reportCount ?? 0,
      totalPoints: profile?.totalPoints ?? 0,
      redCount: redCount,
      streak: profile?.currentStreak ?? 0,
    );
    final earned = badges.where((b) => b.earned).length;
    final total = profile?.totalPoints ?? 0;
    final verified = profile?.verifiedPoints ?? 0;

    return LargeTitlePage(
      title: 'Rewards',
      slivers: [
        SliverList.list(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SectionCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$total',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          TextSpan(
                            text: '  points',
                            style: TextStyle(
                              color: p.secondaryInk,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : verified / total,
                        minHeight: 8,
                        color: p.low.fill,
                        semanticsLabel: 'Verified points',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$verified verified after sync · '
                      '${total - verified} waiting',
                      style: TextStyle(color: p.secondaryInk, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            GroupedSection(
              header: 'Badges',
              headerTrailing: Text(
                '$earned of ${badges.length}',
                style: TextStyle(color: p.secondaryInk, fontSize: 15),
              ),
              dividerIndent: 60,
              children: [
                for (final badge in badges)
                  GroupedRow(
                    leading: IconTile(
                      icon: badge.earned
                          ? Icons.workspace_premium_rounded
                          : Icons.lock_rounded,
                      color: badge.earned ? AppColors.amber : p.tertiaryInk,
                    ),
                    title: badge.title,
                    subtitle: badge.description,
                    trailing: badge.earned
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: p.low.fill,
                            semanticLabel: 'Earned',
                          )
                        : null,
                  ),
              ],
            ),
            GroupedSection(
              header: 'How points work',
              footer:
                  'Points appear as soon as you save a report and are '
                  'verified once it syncs.',
              children: [
                for (final row in rules.documented)
                  GroupedRow(title: row.key, value: row.value),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
