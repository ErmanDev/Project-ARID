import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../theme/app_colors.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.level, this.compact = false});

  final RiskLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (tint, edge, ink, dot) = switch (level) {
      RiskLevel.red => (
        dark ? const Color(0xFF402428) : AppColors.riskRedTint,
        dark ? const Color(0xFF75434A) : AppColors.riskRedEdge,
        dark ? const Color(0xFFFFB7BC) : AppColors.riskRedInk,
        dark ? const Color(0xFFE06A72) : AppColors.riskRed,
      ),
      RiskLevel.yellow => (
        dark ? const Color(0xFF3D3020) : AppColors.riskYellowTint,
        dark ? const Color(0xFF6D5632) : AppColors.riskYellowEdge,
        dark ? const Color(0xFFF0CB88) : AppColors.riskYellowInk,
        dark ? const Color(0xFFD6AA58) : AppColors.riskYellow,
      ),
      RiskLevel.green => (
        dark ? const Color(0xFF23372A) : AppColors.riskGreenTint,
        dark ? const Color(0xFF45654C) : AppColors.riskGreenEdge,
        dark ? const Color(0xFFB7DDBD) : AppColors.riskGreenInk,
        dark ? const Color(0xFF82B48A) : AppColors.riskGreen,
      ),
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
        color: tint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: edge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: ink,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key, required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, icon) = switch (status) {
      SyncStatus.pendingUpload => ('Pending', Icons.cloud_upload_outlined),
      SyncStatus.uploading => ('Syncing', Icons.sync),
      SyncStatus.synced => ('Synced', Icons.cloud_done_outlined),
      SyncStatus.failed => ('Failed', Icons.cloud_off_outlined),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: colors.onSurfaceVariant,
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
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: online ? AppColors.secondary : AppColors.riskYellow,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            online
                ? 'Online · ready to sync'
                : 'Offline · working from local data',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
