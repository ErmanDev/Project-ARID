import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../screens/capture/capture_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'app_navigation.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  void _go(int index) => setState(() => _index = index);

  List<Widget> get _pages => [
    HomeScreen(
      onCapture: () => _go(2),
      onOpenMap: () => _go(1),
      onOpenHistory: () => _go(3),
    ),
    const MapScreen(),
    const CaptureScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(connectivityBootstrapProvider);
    return AppNavigation(
      selectedIndex: _index,
      onSelected: _go,
      child: IndexedStack(index: _index, children: _pages),
    );
  }
}
