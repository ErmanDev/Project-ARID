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
import 'edit_report_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  SyncStatus? _statusFilter;
  bool _syncing = false;

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(reportsProvider).valueOrNull ?? const <Report>[];
    final visible = _statusFilter == null
        ? reports
        : reports
              .where((report) => report.syncStatus == _statusFilter)
              .toList();
    int count(SyncStatus status) =>
        reports.where((report) => report.syncStatus == status).length;
    final synced = count(SyncStatus.synced);

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

    final summary = reports.isEmpty
        ? null
        : synced == reports.length
        ? '${reports.length} reports · all synced'
        : '${reports.length} reports · ${reports.length - synced} not synced';

    return LargeTitlePage(
      title: 'History',
      subtitle: summary,
      actions: [
        IconButton(
          tooltip: 'Sync now',
          onPressed: _syncing ? null : _sync,
          icon: _syncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : const Icon(Icons.sync_rounded),
        ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'All',
                  count: reports.length,
                  selected: _statusFilter == null,
                  onTap: () => setState(() => _statusFilter = null),
                ),
                _FilterChip(
                  label: 'Waiting',
                  count: count(SyncStatus.pendingUpload),
                  selected: _statusFilter == SyncStatus.pendingUpload,
                  onTap: () =>
                      setState(() => _statusFilter = SyncStatus.pendingUpload),
                ),
                _FilterChip(
                  label: 'Failed',
                  count: count(SyncStatus.failed),
                  selected: _statusFilter == SyncStatus.failed,
                  onTap: () =>
                      setState(() => _statusFilter = SyncStatus.failed),
                ),
                _FilterChip(
                  label: 'Synced',
                  count: synced,
                  selected: _statusFilter == SyncStatus.synced,
                  onTap: () =>
                      setState(() => _statusFilter = SyncStatus.synced),
                ),
              ],
            ),
          ),
        ),
        if (visible.isEmpty)
          SliverToBoxAdapter(
            child: _statusFilter == null
                ? const EmptyState(
                    icon: Icons.photo_camera_outlined,
                    title: 'No reports yet',
                    message: 'Reports you capture appear here, grouped by day.',
                  )
                : const EmptyState(
                    icon: Icons.filter_list_rounded,
                    title: 'Nothing here',
                    message: 'No reports match this filter.',
                  ),
          )
        else
          SliverList.builder(
            itemCount: days.length,
            itemBuilder: (context, index) =>
                _DayGroup(day: days[index], reports: grouped[days[index]]!),
          ),
      ],
    );
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final result = await ref.read(syncServiceProvider).syncPending();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                (result.failed == 0
                    ? 'Synced ${result.uploaded} reports.'
                    : 'Synced ${result.uploaded}. ${result.failed} failed — '
                          'they’ll retry automatically.'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
    return ChoiceChip(
      label: Text('$label $count'),
      selected: selected,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      onSelected: (_) => onTap(),
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
        ? 'Today'
        : day == today.subtract(const Duration(days: 1))
        ? 'Yesterday'
        : DateFormat.yMMMMEEEEd().format(day);
    return GroupedSection(
      header: label,
      smallHeader: true,
      dividerIndent: 86,
      children: [
        for (final report in reports)
          ReportRow(
            report: report,
            meta: DateFormat('h:mm a').format(report.capturedAt),
            onTap: () => showReportDetail(context, report),
            trailing: _ReportMenu(report: report),
          ),
      ],
    );
  }
}

enum _ReportAction { details, retry, editPin, delete }

class _ReportMenu extends ConsumerWidget {
  const _ReportMenu({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = report.syncStatus != SyncStatus.synced;
    final danger = context.arid.high.ink;
    return PopupMenuButton<_ReportAction>(
      tooltip: 'Report actions',
      icon: Icon(Icons.more_horiz_rounded, color: context.arid.secondaryInk),
      position: PopupMenuPosition.under,
      onSelected: (action) => _handle(action, context, ref),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _ReportAction.details,
          child: _MenuLabel(Icons.fact_check_outlined, 'Label actual result'),
        ),
        if (local) ...[
          const PopupMenuItem(
            value: _ReportAction.retry,
            child: _MenuLabel(Icons.sync_rounded, 'Retry sync'),
          ),
          const PopupMenuItem(
            value: _ReportAction.editPin,
            child: _MenuLabel(Icons.edit_location_alt_outlined, 'Move pin'),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _ReportAction.delete,
            child: _MenuLabel(
              Icons.delete_outline_rounded,
              'Delete',
              color: danger,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handle(
    _ReportAction action,
    BuildContext context,
    WidgetRef ref,
  ) async {
    switch (action) {
      case _ReportAction.details:
        await showReportDetail(context, report);
      case _ReportAction.retry:
        await ref.read(syncQueueRepositoryProvider).enqueue(report.id);
        final result = await ref.read(syncServiceProvider).syncPending();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ??
                  (result.uploaded > 0
                      ? 'Report synced.'
                      : 'Still not synced. It will retry automatically.'),
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
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete this report?'),
            content: const Text(
              'It hasn’t synced yet, so deleting removes it for good.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: context.arid.high.ink,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete report'),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        try {
          await ref.read(reportRepositoryProvider).deleteLocal(report.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Report deleted.')));
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Couldn’t delete this report — it may have just synced.',
              ),
            ),
          );
        }
    }
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel(this.icon, this.label, {this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.arid.ink;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: c, fontSize: 17)),
        ),
        const SizedBox(width: 16),
        Icon(icon, size: 20, color: c),
      ],
    );
  }
}
