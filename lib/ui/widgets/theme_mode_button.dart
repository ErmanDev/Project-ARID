import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;
    final icon = switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.devices_outlined,
    };

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Color theme',
      initialValue: mode,
      position: PopupMenuPosition.under,
      onSelected: ref.read(themeModeProvider.notifier).setMode,
      itemBuilder: (context) => [
        _item(ThemeMode.light, mode, Icons.light_mode_outlined, 'Light'),
        _item(ThemeMode.dark, mode, Icons.dark_mode_outlined, 'Dark'),
        _item(ThemeMode.system, mode, Icons.devices_outlined, 'System'),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            shape: BoxShape.circle,
            border: Border.all(color: colors.outlineVariant),
          ),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 19, color: colors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<ThemeMode> _item(
    ThemeMode value,
    ThemeMode selected,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (value == selected) const Icon(Icons.check, size: 18),
        ],
      ),
    );
  }
}
