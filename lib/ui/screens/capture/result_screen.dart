import 'package:flutter/material.dart';

import '../../../data/models/enums.dart';
import '../../../providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/large_title_page.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.outcome});

  final CaptureOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    final report = outcome.report;
    return LargeTitlePage(
      title: 'Report saved',
      automaticallyImplyLeading: false,
      subtitle: report.syncStatus == SyncStatus.synced
          ? 'It’s on the map.'
          : 'It will sync to the map when you’re online.',
      bottomBar: FloatingActionBar(
        children: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
      slivers: [
        SliverList.list(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SectionCard(
                child: Row(
                  children: [
                    ReportThumbnail(report: report, size: 72, radius: 16),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reportTitle(report),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              RiskBadge(level: report.riskLevel, compact: true),
                              SyncStatusChip(status: report.syncStatus),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GroupedSection(
              children: [
                GroupedRow(
                  title: 'Confidence',
                  value:
                      '${(report.confidenceScore * 100).toStringAsFixed(0)}%',
                ),
                GroupedRow(
                  title: 'Location',
                  subtitle: report.gpsManual
                      ? 'Placed by hand'
                      : 'GPS ±${report.gpsAccuracy.toStringAsFixed(0)} m',
                  value:
                      '${report.latitude.toStringAsFixed(5)}, '
                      '${report.longitude.toStringAsFixed(5)}',
                ),
              ],
            ),
            GroupedSection(
              header: '+${report.pointsAwarded} points',
              footer: 'Points are verified once the report syncs.',
              dividerIndent: 60,
              children: [
                for (final line in outcome.breakdown)
                  GroupedRow(
                    leading: const IconTile(
                      icon: Icons.star_rounded,
                      color: AppColors.amber,
                    ),
                    title: line,
                  ),
              ],
            ),
            if (!outcome.usedOnDeviceModel)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'This result came from a test model and may be inaccurate.',
                  style: TextStyle(color: p.secondaryInk, fontSize: 13),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
