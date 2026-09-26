import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/glass.dart';

/// Top-level sections. On compact widths a floating glass tab bar sits above
/// the content, which extends beneath it; Scaffold reports the bar's height to
/// pages through MediaQuery padding so nothing hides under it. At 840 logical
/// pixels and wider, a navigation rail replaces the bar with the same five
/// destinations.
class AppNavigation extends StatelessWidget {
  const AppNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget child;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.map_outlined, Icons.map_rounded, 'Map'),
    (Icons.camera_alt_outlined, Icons.camera_alt_rounded, 'Capture'),
    (Icons.history_rounded, Icons.history_rounded, 'History'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  right: false,
                  child: NavigationRail(
                    scrollable: true,
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: colors.surface,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onSelected,
                    destinations: [
                      for (final item in _items)
                        NavigationRailDestination(
                          icon: Icon(item.$1),
                          selectedIcon: Icon(item.$2),
                          label: Text(item.$3),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }
        return Scaffold(
          extendBody: true,
          body: child,
          bottomNavigationBar: _GlassTabBar(
            selectedIndex: selectedIndex,
            onSelected: onSelected,
          ),
        );
      },
    );
  }
}

class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, math.max(inset, 12)),
      child: GlassSurface(
        floating: true,
        borderRadius: BorderRadius.circular(32),
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          // Tab labels are navigation chrome: they grow a little with the
          // text size, but not so much that five labels stop fitting.
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: NavigationBar(
              animationDuration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelected,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (final item in AppNavigation._items)
                  NavigationDestination(
                    icon: Icon(item.$1),
                    selectedIcon: Icon(item.$2),
                    label: item.$3,
                    tooltip: '',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
