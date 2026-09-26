import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../data/models/report.dart';
import '../theme/app_colors.dart';

String riskLabel(RiskLevel level) => switch (level) {
  RiskLevel.red => 'High risk',
  RiskLevel.yellow => 'Moderate',
  RiskLevel.green => 'Non-breeding',
};

String reportTitle(Report report) =>
    report.classification == Classification.breeding
    ? 'Breeding site'
    : 'Non-breeding';

/// The app's risk signature: every risk level has its own shape as well as a
/// color, so it reads without color vision — a triangle for high risk, a
/// diamond for moderate, a circle for non-breeding. Map pins use it too.
class RiskGlyph extends StatelessWidget {
  const RiskGlyph({super.key, required this.level, this.size = 12, this.color});

  final RiskLevel level;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _RiskGlyphPainter(
          level,
          color ?? context.arid.risk(level).fill,
        ),
      ),
    );
  }
}

class _RiskGlyphPainter extends CustomPainter {
  _RiskGlyphPainter(this.level, this.color);

  final RiskLevel level;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    final w = size.width, h = size.height;
    switch (level) {
      case RiskLevel.red:
        final path = Path()
          ..moveTo(w / 2, h * 0.04)
          ..lineTo(w * 0.98, h * 0.92)
          ..lineTo(w * 0.02, h * 0.92)
          ..close();
        canvas.drawPath(
          path,
          paint
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = w * 0.12
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(path, paint..style = PaintingStyle.stroke);
      case RiskLevel.yellow:
        final path = Path()
          ..moveTo(w / 2, 0)
          ..lineTo(w, h / 2)
          ..lineTo(w / 2, h)
          ..lineTo(0, h / 2)
          ..close();
        canvas.drawPath(path, paint);
      case RiskLevel.green:
        canvas.drawCircle(Offset(w / 2, h / 2), math.min(w, h) * 0.42, paint);
    }
  }

  @override
  bool shouldRepaint(_RiskGlyphPainter old) =>
      old.level != level || old.color != color;
}

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.level, this.compact = false});

  final RiskLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tone = context.arid.risk(level);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: tone.tint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RiskGlyph(level: level, size: compact ? 9 : 10),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              riskLabel(level),
              style: TextStyle(
                color: tone.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
    final p = context.arid;
    final (label, icon, color) = switch (status) {
      SyncStatus.pendingUpload => (
        'Waiting to sync',
        Icons.schedule_rounded,
        p.secondaryInk,
      ),
      SyncStatus.uploading => ('Syncing', Icons.sync_rounded, p.accent),
      SyncStatus.synced => ('Synced', Icons.check_circle_rounded, p.low.ink),
      SyncStatus.failed => ('Sync failed', Icons.error_rounded, p.high.ink),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown only while offline: feedback belongs in the interface when something
/// differs from normal, not as a permanent banner.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    if (online) return const SizedBox.shrink();
    final p = context.arid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.moderate.tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 20, color: p.moderate.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You’re offline. Reports save on this device and sync later.',
              style: TextStyle(
                color: p.moderate.ink,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded content container on the grouped background.
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
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// An inset grouped list section: optional header, rows on a rounded
/// surface separated by inset hairlines, optional footer.
class GroupedSection extends StatelessWidget {
  const GroupedSection({
    super.key,
    this.header,
    this.headerTrailing,
    this.footer,
    required this.children,
    this.dividerIndent = 16,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 24),
    this.smallHeader = false,
  });

  final String? header;
  final Widget? headerTrailing;
  final String? footer;
  final List<Widget> children;
  final double dividerIndent;
  final EdgeInsetsGeometry margin;

  /// A quieter header for dense lists such as day groups.
  final bool smallHeader;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null || headerTrailing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        header ?? '',
                        style: smallHeader
                            ? TextStyle(
                                color: p.secondaryInk,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              )
                            : Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  ?headerTrailing,
                ],
              ),
            ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: dividerIndent,
                      color: p.separator,
                    ),
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                footer!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// A list row with the familiar iOS anatomy: leading icon, title and
/// subtitle, trailing value, and a disclosure chevron when it navigates.
class GroupedRow extends StatelessWidget {
  const GroupedRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron,
    this.destructive = false,
    this.accent = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool? showChevron;
  final bool destructive;

  /// Renders the title as a tappable action in the accent color.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    final stacked = MediaQuery.textScalerOf(context).scale(17) > 28;
    final chevron = showChevron ?? (onTap != null && !accent && !destructive);
    final titleColor = destructive
        ? p.high.ink
        : accent
        ? p.accent
        : p.ink;
    final valueText = value == null
        ? null
        : Text(
            value!,
            textAlign: stacked ? TextAlign.start : TextAlign.end,
            style: TextStyle(color: p.secondaryInk, fontSize: 17),
          );

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 17,
                        fontWeight: accent ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (stacked && valueText != null) ...[
                      const SizedBox(height: 2),
                      valueText,
                    ],
                  ],
                ),
              ),
              if (!stacked && valueText != null) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: valueText,
                  ),
                ),
              ],
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (chevron) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: p.tertiaryInk,
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A small filled square behind a white symbol, used to lead list rows.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.textScalerOf(context).scale(30).clamp(30.0, 44.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.6),
    );
  }
}

class ReportThumbnail extends StatelessWidget {
  const ReportThumbnail({
    super.key,
    required this.report,
    this.size = 56,
    this.radius = 12,
  });

  final Report report;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    final file = File(report.imagePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: file.existsSync()
          ? Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * 3).round(),
              semanticLabel: 'Report photo',
            )
          : Container(
              width: size,
              height: size,
              color: p.fill,
              child: Icon(
                Icons.image_outlined,
                color: p.tertiaryInk,
                size: size * 0.4,
              ),
            ),
    );
  }
}

/// A centered status message for empty or unavailable content.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: p.tertiaryInk),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.secondaryInk, fontSize: 15),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// A busy veil over a screen while a single task runs.
class BusyOverlay extends StatelessWidget {
  const BusyOverlay({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    return Semantics(
      liveRegion: true,
      label: label,
      child: ColoredBox(
        color: p.groupedBackground.withValues(alpha: 0.72),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 14),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One report in a grouped list: photo, what was found, when, risk and sync.
class ReportRow extends StatelessWidget {
  const ReportRow({
    super.key,
    required this.report,
    required this.meta,
    this.onTap,
    this.trailing,
  });

  final Report report;

  /// Secondary line, usually the capture date or time.
  final String meta;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportThumbnail(report: report),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reportTitle(report),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(meta, style: Theme.of(context).textTheme.bodySmall),
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
            if (trailing != null) trailing! else const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
