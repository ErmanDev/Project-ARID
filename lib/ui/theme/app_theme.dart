import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Type scale follows the iOS text styles (large title 34, title 2 22,
/// title 3 20, headline 17, body 17, subheadline 15, footnote 13, caption 12).
/// Body and controls use the platform font; Montserrat carries the brand in
/// large titles only.
class AppTheme {
  AppTheme._();

  static const displayFont = 'Montserrat';

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get highContrastLight =>
      _build(Brightness.light, highContrast: true);
  static ThemeData get highContrastDark =>
      _build(Brightness.dark, highContrast: true);

  static ThemeData _build(Brightness brightness, {bool highContrast = false}) {
    final dark = brightness == Brightness.dark;
    final p = AridPalette.of(brightness, highContrast: highContrast);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      primaryContainer: p.accentTint,
      onPrimaryContainer: p.accentInk,
      secondary: p.accent,
      onSecondary: p.onAccent,
      secondaryContainer: p.accentTint,
      onSecondaryContainer: p.accentInk,
      tertiary: p.low.fill,
      onTertiary: dark ? const Color(0xFF0E2415) : Colors.white,
      tertiaryContainer: p.low.tint,
      onTertiaryContainer: p.low.ink,
      error: p.high.fill,
      onError: dark ? const Color(0xFF3A0B0E) : Colors.white,
      errorContainer: p.high.tint,
      onErrorContainer: p.high.ink,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.secondaryInk,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.elevated,
      surfaceContainer: p.fill,
      surfaceContainerHigh: p.fill,
      surfaceContainerHighest: p.fill,
      outline: p.tertiaryInk,
      outlineVariant: p.separator,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: dark ? AppColors.surface : AppColors.ink,
      onInverseSurface: dark ? AppColors.ink : Colors.white,
      inversePrimary: dark ? AppColors.primary : AppColors.primaryDarkMode,
    );

    final text = TextTheme(
      // Large title. Used by LargeTitlePage and onboarding.
      headlineMedium: TextStyle(
        color: p.ink,
        fontFamily: displayFont,
        fontWeight: FontWeight.w700,
        fontSize: 34,
        height: 1.15,
        letterSpacing: -0.6,
      ),
      headlineSmall: TextStyle(
        color: p.ink,
        fontWeight: FontWeight.w700,
        fontSize: 22,
        height: 1.2,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        color: p.ink,
        fontWeight: FontWeight.w600,
        fontSize: 20,
        height: 1.25,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        color: p.ink,
        fontWeight: FontWeight.w600,
        fontSize: 17,
        height: 1.3,
      ),
      titleSmall: TextStyle(
        color: p.ink,
        fontWeight: FontWeight.w600,
        fontSize: 15,
        height: 1.3,
      ),
      bodyLarge: TextStyle(color: p.ink, fontSize: 17, height: 1.35),
      bodyMedium: TextStyle(color: p.ink, fontSize: 17, height: 1.35),
      bodySmall: TextStyle(color: p.secondaryInk, fontSize: 13, height: 1.35),
      labelLarge: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(
        color: p.secondaryInk,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        color: p.secondaryInk,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );

    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [p],
      scaffoldBackgroundColor: p.groupedBackground,
      canvasColor: p.groupedBackground,
      dividerColor: p.separator,
      splashFactory: InkSparkle.splashFactory,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: p.groupedBackground,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: p.ink,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        actionsIconTheme: IconThemeData(color: p.accent),
        iconTheme: IconThemeData(color: p.accent),
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: highContrast ? BorderSide(color: p.separator) : BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.fill,
          disabledForegroundColor: p.tertiaryInk,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          shape: pill,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        // Rendered as a tinted "gray" button, the iOS secondary style.
        style: OutlinedButton.styleFrom(
          foregroundColor: p.accent,
          backgroundColor: p.fill,
          minimumSize: const Size(64, 52),
          side: highContrast ? BorderSide(color: p.separator) : BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          shape: pill,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          shape: pill,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: p.accent,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.secondaryInk,
        textColor: p.ink,
        minVerticalPadding: 12,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: p.accentTint,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? p.accentInk
                : p.secondaryInk,
            size: 24,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? p.accent
                : p.secondaryInk,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.accentTint,
        selectedIconTheme: IconThemeData(color: p.accentInk),
        unselectedIconTheme: IconThemeData(color: p.secondaryInk),
        selectedLabelTextStyle: TextStyle(
          color: p.accent,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(color: p.secondaryInk),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.accent,
        checkmarkColor: p.onAccent,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: p.ink,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: p.onAccent,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        side: highContrast ? BorderSide(color: p.separator) : BorderSide.none,
        shape: const StadiumBorder(),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: p.fill,
          selectedBackgroundColor: p.surface,
          selectedForegroundColor: p.ink,
          foregroundColor: p.secondaryInk,
          side: BorderSide.none,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.fill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        labelStyle: TextStyle(color: p.secondaryInk),
        hintStyle: TextStyle(color: p.tertiaryInk),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: highContrast
              ? BorderSide(color: p.secondaryInk)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: highContrast
              ? BorderSide(color: p.secondaryInk)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.accent, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.low.fill : p.fill,
        ),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? AppColors.darkElevated : AppColors.ink,
        contentTextStyle: TextStyle(
          color: dark ? AppColors.darkInk : Colors.white,
          fontSize: 15,
        ),
        actionTextColor: dark
            ? AppColors.primaryDarkMode
            : AppColors.accentTint,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: text.bodyLarge,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.fill,
        circularTrackColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: p.separator,
        space: 1,
        thickness: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? p.elevated : p.groupedBackground,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.tertiaryInk,
        dragHandleSize: const Size(36, 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? p.elevated : p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: text.titleMedium,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: p.secondaryInk,
          fontSize: 15,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? AppColors.darkElevated : AppColors.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          color: dark ? AppColors.darkInk : Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }
}
