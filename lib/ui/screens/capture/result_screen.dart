import 'dart:io';

import 'package:flutter/material.dart';

import '../../../data/models/enums.dart';
import '../../../providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.outcome});

  final CaptureOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final report = outcome.report;
    return Scaffold(
      appBar: AppBar(title: const Text('Report saved')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(report.imagePath),
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              RiskBadge(level: report.riskLevel),
              const SizedBox(width: 8),
              SyncStatusChip(status: report.syncStatus),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.classification == Classification.breeding
                      ? 'Breeding site detected'
                      : 'Non-breeding',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Confidence ${(report.confidenceScore * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}'
                  '${report.gpsManual ? '  ·  manual pin' : '  ·  ±${report.gpsAccuracy.toStringAsFixed(0)} m'}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (!outcome.usedOnDeviceModel) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Development classifier is active. Place your Teachable Machine export at assets/models/arid_model.tflite for production inference.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+${report.pointsAwarded} points (provisional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...outcome.breakdown.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const Text(
                  'Verified after a successful cloud sync. The total is already on this device.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
