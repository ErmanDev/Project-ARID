import 'dart:io';

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
import 'edit_report_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  SyncStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(reportsProvider).valueOrNull ?? const <Report>[];
    final visible = _statusFilter == null
        ? reports
        : reports
              .where((report) => report.syncStatus == _statusFilter)
              .toList();
    final synced = reports
        .where((report) => report.syncStatus == SyncStatus.synced)
        .length;
    final pending = reports
        .where((report) => report.syncStatus == SyncStatus.pendingUpload)
        .length;
    final failed = reports
        .where((report) => report.syncStatus == SyncStatus.failed)
        .length;
    final grouped = <DateTime, List<Report>>{};
    for (final report in visible) {
      final day = DateTime(
        report.capturedAt.year,
        report.capturedAt.month,
        report.capturedAt.day,
      );
      grouped.putIfAbsent(day, () => []).add(report);
    }
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const AridBrandTitle(subtitle: 'Adaptive Field Journal'),
        actions: const [ThemeModeButton()],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: colors.surface,
            padding: const EdgeInsets.fromLTRB(16, 18, 8, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'History',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${reports.length} reports · '
                        '${reports.isNotEmpty && synced == reports.length ? 'all synced' : '$synced synced'}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sync now',
                  onPressed: _sync,
                  icon: Icon(
                    Icons.sync_rounded,
                    color: colors.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _FilterButton(
                      label: 'All',
                      count: reports.length,
                      selected: _statusFilter == null,
                      onTap: () => setState(() => _statusFilter = null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterButton(
                      label: 'Pending',
                      count: pending,
                      selected: _statusFilter == SyncStatus.pendingUpload,
                      onTap: () => setState(
                        () => _statusFilter = SyncStatus.pendingUpload,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterButton(
                      label: 'Failed',
                      count: failed,
                      selected: _statusFilter == SyncStatus.failed,
                      onTap: () =>
                          setState(() => _statusFilter = SyncStatus.failed),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterButton(
                      label: 'Synced',
                      count: synced,
                      selected: _statusFilter == SyncStatus.synced,
                      onTap: () =>
                          setState(() => _statusFilter = SyncStatus.synced),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? _EmptyHistory(filterActive: _statusFilter != null)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    itemCount: days.length,
                    itemBuilder: (context, dayIndex) {
                      final day = days[dayIndex];
                      final dayReports = grouped[day]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _DayGroup(day: day, reports: dayReports),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _sync() async {
    final result = await ref.read(syncServiceProvider).syncPending();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ??
              'Uploaded ${result.uploaded}, failed ${result.failed}',
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primaryContainer : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                  fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.day, required this.reports});

  final DateTime day;
  final List<Report> reports;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final label = day == today
        ? 'Today · ${DateFormat.yMMMd().format(day)}'
        : DateFormat.yMMMMd().format(day);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 9),
          child: Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < reports.length; index++) ...[
                _HistoryRow(report: reports[index]),
                if (index != reports.length - 1)
                  Divider(height: 1, indent: 88, color: colors.outlineVariant),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends ConsumerWidget {
  const _HistoryRow({required this.report});

  final Report report;

  Color _riskColor() => switch (report.riskLevel) {
    RiskLevel.red => AppColors.riskRed,
    RiskLevel.yellow => AppColors.riskYellow,
    RiskLevel.green => AppColors.riskGreen,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, color: _riskColor()),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 13, 8, 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: File(report.imagePath).existsSync()
                        ? Image.file(
                            File(report.imagePath),
                            width: 64,
                            height: 76,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 64,
                            height: 76,
                            color: colors.surfaceContainerLow,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            RiskBadge(level: report.riskLevel, compact: true),
                            const Spacer(),
                            SyncStatusChip(status: report.syncStatus),
                            if (report.syncStatus != SyncStatus.synced)
                              _ReportMenu(report: report),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          report.classification == Classification.breeding
                              ? 'Breeding site'
                              : 'Non-breeding',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat('h:mm a').format(report.capturedAt),
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _labelGroundTruth(context, ref),
                              child: Text(
                                report.groundTruth == GroundTruth.unlabeled
                                    ? 'Label truth'
                                    : 'Truth: ${_truthLabel(report.groundTruth)}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _truthLabel(GroundTruth truth) => switch (truth) {
    GroundTruth.breeding => 'breeding',
    GroundTruth.nonBreeding => 'not breeding',
    GroundTruth.unlabeled => 'unlabeled',
  };

  Future<void> _labelGroundTruth(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<GroundTruth>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Breeding (actual)'),
              onTap: () => Navigator.pop(context, GroundTruth.breeding),
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined),
              title: const Text('Non-breeding (actual)'),
              onTap: () => Navigator.pop(context, GroundTruth.nonBreeding),
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Unlabeled'),
              onTap: () => Navigator.pop(context, GroundTruth.unlabeled),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    report.groundTruth = choice;
    await ref.read(reportRepositoryProvider).update(report);
  }
}

enum _ReportAction { retry, editPin, delete }

class _ReportMenu extends ConsumerWidget {
  const _ReportMenu({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_ReportAction>(
      tooltip: 'Report actions',
      padding: EdgeInsets.zero,
      iconSize: 19,
      onSelected: (action) => _handle(action, context, ref),
      itemBuilder: (context) => const [
        PopupMenuItem(value: _ReportAction.retry, child: Text('Retry sync')),
        PopupMenuItem(value: _ReportAction.editPin, child: Text('Edit pin')),
        PopupMenuItem(value: _ReportAction.delete, child: Text('Delete')),
      ],
    );
  }

  Future<void> _handle(
    _ReportAction action,
    BuildContext context,
    WidgetRef ref,
  ) async {
    switch (action) {
      case _ReportAction.retry:
        await ref.read(syncQueueRepositoryProvider).enqueue(report.id);
        final result = await ref.read(syncServiceProvider).syncPending();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'Retry finished: ${result.uploaded} uploaded',
            ),
          ),
        );
      case _ReportAction.editPin:
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EditReportScreen(reportId: report.id),
          ),
        );
      case _ReportAction.delete:
        await ref.read(reportRepositoryProvider).deleteLocal(report.id);
    }
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.filterActive});

  final bool filterActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              color: colors.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              filterActive ? 'No reports in this filter' : 'No reports yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              filterActive
                  ? 'Choose another status to see more activity.'
                  : 'Captured reports will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
