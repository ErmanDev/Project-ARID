import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../theme/app_colors.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.level, this.compact = false});

  final RiskLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      RiskLevel.red => AppColors.riskRed,
      RiskLevel.yellow => AppColors.riskYellow,
      RiskLevel.green => AppColors.riskGreen,
    };
    final label = switch (level) {
      RiskLevel.red => 'High risk',
      RiskLevel.yellow => 'Moderate',
      RiskLevel.green => 'Low risk',
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        compact ? level.name.toUpperCase() : label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key, required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (status) {
      SyncStatus.pendingUpload => ('Pending', Icons.cloud_upload_outlined),
      SyncStatus.uploading => ('Syncing', Icons.sync),
      SyncStatus.synced => ('Synced', Icons.cloud_done_outlined),
      SyncStatus.failed => ('Failed', Icons.cloud_off_outlined),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: online
          ? AppColors.secondary.withValues(alpha: 0.12)
          : AppColors.primary.withValues(alpha: 0.10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        online
            ? 'Online'
            : 'Offline',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}
