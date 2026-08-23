import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../screens/capture/capture_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/profile/profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    MapScreen(),
    CaptureScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(connectivityBootstrapProvider);
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 86),
            child: IndexedStack(index: _index, children: _pages),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: SafeArea(
              top: false,
              child: _FloatingNavigationDock(
                selectedIndex: _index,
                onSelected: (value) => setState(() => _index = value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavigationDock extends StatelessWidget {
  const _FloatingNavigationDock({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.map_outlined, Icons.map_rounded, 'Map'),
    (Icons.camera_alt_outlined, Icons.camera_alt_rounded, 'Capture'),
    (Icons.list_alt_outlined, Icons.list_alt_rounded, 'History'),
    (Icons.person_outline, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final captureSelected = selectedIndex == 2;
    return SizedBox(
      height: 82,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Material(
            color: colors.surface,
            elevation: 10,
            shadowColor: colors.shadow.withValues(alpha: 0.24),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: SizedBox(
              height: 68,
              child: Row(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final selected = selectedIndex == index;
                  if (index == 2) return const Expanded(child: SizedBox());
                  return Expanded(
                    child: _DockDestination(
                      icon: selected ? item.$2 : item.$1,
                      label: item.$3,
                      selected: selected,
                      onTap: () => onSelected(index),
                    ),
                  );
                }),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Semantics(
              button: true,
              selected: captureSelected,
              label: _items[2].$3,
              child: Material(
                color: colors.surface,
                shape: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: InkResponse(
                    onTap: () => onSelected(2),
                    radius: 32,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        captureSelected ? _items[2].$2 : _items[2].$1,
                        color: colors.onPrimary,
                        size: 27,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DockDestination extends StatelessWidget {
  const _DockDestination({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected ? colors.primary : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 23, color: color),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox(height: 3),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 5 : 0,
                height: selected ? 5 : 0,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
