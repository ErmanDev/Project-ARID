import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/enums.dart';
import '../../data/models/report.dart';
import '../../providers.dart';
import '../theme/app_colors.dart';
import 'common.dart';

Future<void> showReportDetail(BuildContext context, Report report) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => ReportDetailSheet(report: report),
  );
}

String groundTruthLabel(GroundTruth truth) => switch (truth) {
  GroundTruth.breeding => 'Breeding',
  GroundTruth.nonBreeding => 'Not breeding',
  GroundTruth.unlabeled => 'Not labeled',
};

class ReportDetailSheet extends ConsumerStatefulWidget {
  const ReportDetailSheet({super.key, required this.report});

  final Report report;

  @override
  ConsumerState<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends ConsumerState<ReportDetailSheet> {
  late GroundTruth _truth = widget.report.groundTruth;

  Future<void> _setTruth(GroundTruth truth) async {
    setState(() => _truth = truth);
    widget.report.groundTruth = truth;
    await ref.read(reportRepositoryProvider).update(widget.report);
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final p = context.arid;
    final photo = File(report.imagePath);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photo.existsSync()) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Image.file(
                          photo,
                          fit: BoxFit.cover,
                          semanticLabel: 'Report photo',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Semantics(
                    header: true,
                    child: Text(
                      reportTitle(report),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RiskBadge(level: report.riskLevel),
                ],
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
                  title: 'Captured',
                  value: DateFormat(
                    'MMM d, y · h:mm a',
                  ).format(report.capturedAt),
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
                GroupedRow(
                  title: 'Sync',
                  trailing: SyncStatusChip(status: report.syncStatus),
                ),
              ],
            ),
            GroupedSection(
              footer:
                  'After checking the site in person, record what you found. '
                  'This measures how well the photo check performs.',
              children: [
                PopupMenuButton<GroundTruth>(
                  tooltip: 'Label actual result',
                  initialValue: _truth,
                  position: PopupMenuPosition.under,
                  onSelected: _setTruth,
                  itemBuilder: (context) => [
                    for (final truth in [
                      GroundTruth.breeding,
                      GroundTruth.nonBreeding,
                      GroundTruth.unlabeled,
                    ])
                      CheckedPopupMenuItem(
                        value: truth,
                        checked: truth == _truth,
                        child: Text(groundTruthLabel(truth)),
                      ),
                  ],
                  child: GroupedRow(
                    title: 'Actual result',
                    value: groundTruthLabel(_truth),
                    trailing: Icon(
                      Icons.unfold_more_rounded,
                      size: 20,
                      color: p.tertiaryInk,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
