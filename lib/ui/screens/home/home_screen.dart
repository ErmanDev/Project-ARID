import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/report.dart';
import '../../../providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/large_title_page.dart';
import '../../widgets/report_detail_sheet.dart';
import '../rewards/rewards_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    this.onCapture,
    this.onOpenMap,
    this.onOpenHistory,
  });

  final VoidCallback? onCapture;
  final VoidCallback? onOpenMap;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsProvider).valueOrNull ?? const <Report>[];
    final profile = ref.watch(profileProvider).valueOrNull;
    final online = ref.watch(isOnlineProvider);
    final pending = reports
        .where((r) => r.syncStatus != SyncStatus.synced)
        .length;
    final name = profile?.displayName.trim() ?? '';
    final streak = profile?.currentStreak ?? 0;

    return LargeTitlePage(
      title: 'Home',
      subtitle: name.isEmpty ? null : 'Welcome back, $name',
      slivers: [
        SliverList.list(
          children: [
            if (!online)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: OfflineBanner(online: online),
              ),
            if (onCapture != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                child: _ReportPrompt(onCapture: onCapture!),
              ),
            _RiskSummary(reports: reports, onOpenMap: onOpenMap),
            GroupedSection(
              header: 'Your activity',
              dividerIndent: 60,
              children: [
                GroupedRow(
                  leading: const IconTile(
                    icon: Icons.star_rounded,
                    color: AppColors.amber,
                  ),
                  title: 'Points',
                  value: '${profile?.totalPoints ?? 0}',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RewardsScreen()),
                  ),
                ),
                GroupedRow(
                  leading: const IconTile(
                    icon: Icons.bolt_rounded,
                    color: AppColors.indigo,
                  ),
                  title: 'Reporting streak',
                  value: streak == 1 ? '1 day' : '$streak days',
                ),
                GroupedRow(
                  leading: const IconTile(
                    icon: Icons.cloud_upload_rounded,
                    color: AppColors.slate,
                  ),
                  title: 'Waiting to sync',
                  value: '$pending',
                  onTap: onOpenHistory,
                ),
              ],
            ),
            GroupedSection(
              header: 'Recent reports',
              headerTrailing: reports.isEmpty || onOpenHistory == null
                  ? null
                  : TextButton(
                      onPressed: onOpenHistory,
                      child: const Text('See all'),
                    ),
              dividerIndent: 86,
              children: reports.isEmpty
                  ? [
                      const EmptyState(
                        icon: Icons.photo_camera_outlined,
                        title: 'No reports yet',
                        message:
                            'Photograph a possible breeding site to add your '
                            'first report. It saves on this device.',
                      ),
                    ]
                  : [
                      for (final report in reports.take(5))
                        ReportRow(
                          report: report,
                          meta: DateFormat(
                            'MMM d · h:mm a',
                          ).format(report.capturedAt),
                          onTap: () => showReportDetail(context, report),
                        ),
                    ],
            ),
          ],
        ),
      ],
    );
  }
}

/// The one prominent action on Home.
class _ReportPrompt extends StatelessWidget {
  const _ReportPrompt({required this.onCapture});

  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    return SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: p.accentTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  color: p.accentInk,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seen standing water?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Take a photo and A.R.I.D. checks it for mosquito '
                      'breeding. It works without internet.',
                      style: TextStyle(color: p.secondaryInk, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCapture,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Report a breeding site'),
          ),
        ],
      ),
    );
  }
}

/// The product's signature: every reported site, broken down by risk, in
/// the same shape-and-color language the map uses.
class _RiskSummary extends StatelessWidget {
  const _RiskSummary({required this.reports, this.onOpenMap});

  final List<Report> reports;
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    int count(RiskLevel level) =>
        reports.where((r) => r.riskLevel == level).length;
    final levels = [RiskLevel.red, RiskLevel.yellow, RiskLevel.green];
    final counts = {for (final level in levels) level: count(level)};
    final total = reports.length;

    return GroupedSection(
      header: 'Reported sites',
      headerTrailing: onOpenMap == null
          ? null
          : TextButton(onPressed: onOpenMap, child: const Text('Map')),
      dividerIndent: 44,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                total == 1
                    ? '1 site on this device'
                    : '$total sites on this device',
                style: TextStyle(color: p.secondaryInk, fontSize: 15),
              ),
              const SizedBox(height: 12),
              Semantics(
                label:
                    '${counts[RiskLevel.red]} high risk, '
                    '${counts[RiskLevel.yellow]} moderate, '
                    '${counts[RiskLevel.green]} non-breeding',
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: 12,
                    child: total == 0
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              color: p.fill,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          )
                        : Row(
                            children: [
                              for (final level in levels)
                                if (counts[level]! > 0)
                                  Expanded(
                                    flex: counts[level]!,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 1.5,
                                      ),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: p.risk(level).fill,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final level in levels)
          GroupedRow(
            leading: SizedBox(
              width: 14,
              child: Center(child: RiskGlyph(level: level, size: 13)),
            ),
            title: riskLabel(level),
            value: '${counts[level]}',
          ),
      ],
    );
  }
}
