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
    final p = context.arid;
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
            _SectionHeader(title: 'Your activity'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: _StatGrid(
                children: [
                  _StatCard(
                    icon: Icons.star_rounded,
                    tone: p.points,
                    label: 'Points',
                    value: '${profile?.totalPoints ?? 0}',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RewardsScreen()),
                    ),
                  ),
                  _StatCard(
                    icon: Icons.bolt_rounded,
                    tone: p.streak,
                    label: 'Streak',
                    value: streak == 1 ? '1 day' : '$streak days',
                  ),
                  _StatCard(
                    icon: Icons.cloud_upload_rounded,
                    tone: p.sync,
                    label: 'Pending',
                    value: '$pending',
                    onTap: onOpenHistory,
                  ),
                ],
              ),
            ),
            _SectionHeader(
              title: 'Recent reports',
              trailing: reports.isEmpty || onOpenHistory == null
                  ? null
                  : TextButton(
                      onPressed: onOpenHistory,
                      child: const Text('See all'),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: reports.isEmpty
                  ? const SectionCard(
                      child: EmptyState(
                        icon: Icons.photo_camera_outlined,
                        title: 'No reports yet',
                        message:
                            'Photograph a possible breeding site to add your '
                            'first report. It saves on this device.',
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final report in reports.take(5))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RecentReportCard(
                              report: report,
                              onTap: () => showReportDetail(context, report),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// The one prominent action on Home. A soft accent wash sets it apart from
/// the neutral cards below.
class _ReportPrompt extends StatelessWidget {
  const _ReportPrompt({required this.onCapture});

  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: p.highContrast
              ? p.separator
              : p.accent.withValues(alpha: 0.22),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.accentTint, p.surface],
        ),
      ),
      child: Padding(
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
                    color: p.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.water_drop_rounded,
                    color: p.onAccent,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: 'Reported sites',
            trailing: onOpenMap == null
                ? null
                : TextButton(onPressed: onOpenMap, child: const Text('Map')),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        height: 10,
                        child: total == 0
                            ? DecoratedBox(
                                decoration: BoxDecoration(
                                  color: p.fill,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final level in levels) ...[
                    _RiskRow(level: level, count: counts[level]!),
                    if (level != levels.last) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One risk level as a tinted pill: glyph, label, count chip.
class _RiskRow extends StatelessWidget {
  const _RiskRow({required this.level, required this.count});

  final RiskLevel level;
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    final tone = p.risk(level);
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: tone.tint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.highContrast ? tone.fill : tone.fill.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          RiskGlyph(level: level, size: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              riskLabel(level),
              style: TextStyle(
                color: p.ink,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 34),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: p.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tone.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three stat cards side by side; a vertical stack once text is too large
/// or the screen too narrow for them to fit.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = scale > 1.3 || constraints.maxWidth < 300;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final child in children)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: child,
                ),
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i != children.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final RiskTone tone;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    return Semantics(
      container: true,
      button: onTap != null,
      onTap: onTap,
      label: '$label, $value',
      excludeSemantics: true,
      child: _TintedCard(
        tint: tone.tint,
        edge: tone.fill,
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tone.fill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: p.surface, size: 24),
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: p.secondaryInk, fontSize: 13)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  color: p.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentReportCard extends StatelessWidget {
  const _RecentReportCard({required this.report, required this.onTap});

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    final tone = p.risk(report.riskLevel);
    return _TintedCard(
      tint: tone.tint,
      edge: tone.fill,
      begin: Alignment.centerLeft,
      end: const Alignment(0.2, 0),
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ReportThumbnail(report: report, size: 56, radius: 14, tinted: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      reportTitle(report),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    RiskBadge(level: report.riskLevel, compact: true),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _relativeTime(report.capturedAt),
                      style: TextStyle(color: p.secondaryInk, fontSize: 13),
                    ),
                    Text('·', style: TextStyle(color: p.tertiaryInk)),
                    SyncStatusChip(status: report.syncStatus),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A card washed with a tone: the tint fades into the surface, with a faint
/// tone-colored edge. Increased contrast falls back to a plain card.
class _TintedCard extends StatelessWidget {
  const _TintedCard({
    required this.tint,
    required this.edge,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  final Color tint;
  final Color edge;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Alignment begin;
  final Alignment end;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    if (p.highContrast) {
      return SectionCard(onTap: onTap, padding: padding, child: child);
    }
    final radius = BorderRadius.circular(22);
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: edge.withValues(alpha: 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: [tint, p.surface],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

String _relativeTime(DateTime at) {
  final now = DateTime.now();
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) {
    return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
  }
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final days = today.difference(day).inDays;
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  return DateFormat('MMM d').format(at);
}
