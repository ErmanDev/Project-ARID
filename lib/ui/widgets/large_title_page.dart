import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A scrolling page with an iOS-style large title that condenses into the
/// toolbar once it scrolls away. The toolbar stays clear at rest and takes on
/// a blurred scroll-edge background only when content passes beneath it.
class LargeTitlePage extends StatefulWidget {
  const LargeTitlePage({
    super.key,
    required this.title,
    required this.slivers,
    this.subtitle,
    this.actions = const [],
    this.bottomBar,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> slivers;

  /// A floating action bar pinned above the bottom edge; content scrolls
  /// beneath it.
  final Widget? bottomBar;
  final bool automaticallyImplyLeading;

  @override
  State<LargeTitlePage> createState() => _LargeTitlePageState();
}

class _LargeTitlePageState extends State<LargeTitlePage> {
  bool _condensed = false;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final condensed = notification.metrics.pixels > 40;
    if (condensed != _condensed) setState(() => _condensed = condensed);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 160);
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: widget.bottomBar != null,
      bottomNavigationBar: widget.bottomBar,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: widget.automaticallyImplyLeading,
              backgroundColor: Colors.transparent,
              toolbarHeight: 52,
              title: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: ExcludeSemantics(
                  excluding: !_condensed,
                  child: AnimatedOpacity(
                    opacity: _condensed ? 1 : 0,
                    duration: duration,
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              actions: [...widget.actions, const SizedBox(width: 8)],
              flexibleSpace: AnimatedSwitcher(
                duration: duration,
                child: _condensed
                    ? _ScrollEdge(key: const ValueKey('edge'), palette: p)
                    : const SizedBox.expand(key: ValueKey('clear')),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Large titles scale, but less than body text, so the
                    // hierarchy survives the largest accessibility sizes.
                    MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.5,
                      child: Semantics(
                        header: true,
                        child: Text(
                          widget.title,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(color: p.secondaryInk, fontSize: 15),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            ...widget.slivers,
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).bottom + 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrollEdge extends StatelessWidget {
  const _ScrollEdge({super.key, required this.palette});

  final AridPalette palette;

  @override
  Widget build(BuildContext context) {
    final border = Border(bottom: BorderSide(color: palette.separator));
    if (palette.highContrast || MediaQuery.highContrastOf(context)) {
      return DecoratedBox(
        decoration: BoxDecoration(color: palette.surface, border: border),
      );
    }
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.groupedBackground.withValues(alpha: 0.78),
            border: border,
          ),
        ),
      ),
    );
  }
}

/// A floating bar that holds a screen's primary action(s) above the bottom
/// safe area, on the glass material.
class FloatingActionBar extends StatelessWidget {
  const FloatingActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    final inset = MediaQuery.paddingOf(context).bottom;
    final opaque = p.highContrast || MediaQuery.highContrastOf(context);
    final content = Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, inset > 0 ? inset : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
    final border = Border(top: BorderSide(color: p.separator));
    if (opaque) {
      return DecoratedBox(
        decoration: BoxDecoration(color: p.surface, border: border),
        child: content,
      );
    }
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.groupedBackground.withValues(alpha: 0.82),
            border: border,
          ),
          child: content,
        ),
      ),
    );
  }
}
