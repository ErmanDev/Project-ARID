import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/report.dart';
import '../../../providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
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
        : reports.where((r) => r.syncStatus == _statusFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Sync now',
            onPressed: () async {
              final result = await ref.read(syncServiceProvider).syncPending();
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
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _statusFilter == null,
                  onSelected: (_) => setState(() => _statusFilter = null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pending'),
                  selected: _statusFilter == SyncStatus.pendingUpload,
                  onSelected: (_) =>
                      setState(() => _statusFilter = SyncStatus.pendingUpload),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Failed'),
                  selected: _statusFilter == SyncStatus.failed,
                  onSelected: (_) =>
                      setState(() => _statusFilter = SyncStatus.failed),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Synced'),
                  selected: _statusFilter == SyncStatus.synced,
                  onSelected: (_) =>
                      setState(() => _statusFilter = SyncStatus.synced),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const Center(
                    child: Text(
                      'No reports in this filter.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _HistoryTile(report: visible[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: File(report.imagePath).existsSync()
                ? Image.file(
                    File(report.imagePath),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: AppColors.background,
                    child: const Icon(Icons.image_not_supported_outlined),
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
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  report.classification == Classification.breeding
                      ? 'Breeding site'
                      : 'Non-breeding',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('MMM d, y · h:mm a').format(report.capturedAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (report.syncStatus == SyncStatus.failed ||
                        report.syncStatus == SyncStatus.pendingUpload)
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(syncQueueRepositoryProvider)
                              .enqueue(report.id);
                          final result =
                              await ref.read(syncServiceProvider).syncPending();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result.message ??
                                    'Retry finished: ${result.uploaded} uploaded',
                              ),
                            ),
                          );
                        },
                        child: const Text('Retry sync'),
                      ),
                    if (report.syncStatus != SyncStatus.synced)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditReportScreen(reportId: report.id),
                            ),
                          );
                        },
                        child: const Text('Edit pin'),
                      ),
                    if (report.syncStatus != SyncStatus.synced)
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(reportRepositoryProvider)
                              .deleteLocal(report.id);
                        },
                        child: const Text('Delete'),
                      ),
                    TextButton(
                      onPressed: () => _labelGroundTruth(context, ref),
                      child: Text(
                        report.groundTruth == GroundTruth.unlabeled
                            ? 'Label truth'
                            : 'Truth: ${report.groundTruth.name}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _labelGroundTruth(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<GroundTruth>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Breeding (actual)'),
              onTap: () => Navigator.pop(context, GroundTruth.breeding),
            ),
            ListTile(
              title: const Text('Non-breeding (actual)'),
              onTap: () => Navigator.pop(context, GroundTruth.nonBreeding),
            ),
            ListTile(
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
