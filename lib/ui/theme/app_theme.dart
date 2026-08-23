import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? AppColors.darkBackground : AppColors.background;
    final surface = dark ? AppColors.darkSurface : AppColors.surface;
    final panel = dark ? AppColors.darkPanel : AppColors.panel;
    final sunken = dark ? AppColors.darkSunken : AppColors.sunken;
    final ink = dark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final muted = dark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final border = dark ? AppColors.darkDivider : AppColors.divider;
    final strong = dark ? AppColors.darkBorderStrong : AppColors.borderStrong;
    final primary = dark ? const Color(0xFF6EA6B8) : AppColors.primary;
    final primaryInk = dark ? const Color(0xFFBCE4EF) : AppColors.primaryDark;
    final primaryTint = dark ? const Color(0xFF203942) : AppColors.primaryTint;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: dark ? const Color(0xFF0E2128) : Colors.white,
      secondary: dark ? const Color(0xFF83AF9B) : AppColors.secondary,
      onSecondary: dark ? const Color(0xFF10271D) : Colors.white,
      error: dark ? const Color(0xFFFFB4B8) : AppColors.riskRed,
      onError: dark ? const Color(0xFF690005) : Colors.white,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: strong,
      outlineVariant: border,
      surfaceContainerLowest: surface,
      surfaceContainerLow: panel,
      surfaceContainer: sunken,
      surfaceContainerHigh: dark
          ? const Color(0xFF293A43)
          : const Color(0xFFE7ECEE),
      surfaceContainerHighest: dark
          ? const Color(0xFF32444D)
          : const Color(0xFFDDE5E7),
      primaryContainer: primaryTint,
      onPrimaryContainer: primaryInk,
      shadow: dark ? Colors.black : const Color(0xFF293438),
      scrim: Colors.black,
      inverseSurface: dark ? AppColors.surface : const Color(0xFF263238),
      onInverseSurface: dark ? AppColors.textPrimary : Colors.white,
      inversePrimary: dark ? AppColors.primary : const Color(0xFF9ACADB),
      tertiary: dark ? const Color(0xFFA3CCB5) : AppColors.secondary,
      onTertiary: dark ? const Color(0xFF123225) : Colors.white,
      tertiaryContainer: dark
          ? const Color(0xFF244537)
          : const Color(0xFFE8F2ED),
      onTertiaryContainer: dark
          ? const Color(0xFFC1EBD4)
          : const Color(0xFF355E4C),
      errorContainer: dark ? const Color(0xFF542327) : AppColors.riskRedTint,
      onErrorContainer: dark ? const Color(0xFFFFDADB) : AppColors.riskRedInk,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Montserrat',
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        shape: Border(bottom: BorderSide(color: border)),
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
        shadowColor: dark ? Colors.black45 : const Color(0x14293438),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: strong),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primaryTint,
        checkmarkColor: primary,
        labelStyle: TextStyle(color: muted, fontSize: 13),
        secondaryLabelStyle: TextStyle(
          color: primaryInk,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: strong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: strong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? const Color(0xFFDFE7EA) : AppColors.textPrimary,
        contentTextStyle: TextStyle(
          color: dark ? AppColors.textPrimary : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      dividerTheme: DividerThemeData(color: border, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: ink,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: ink,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(color: ink, fontSize: 16),
        bodyMedium: TextStyle(color: ink, fontSize: 14),
        bodySmall: TextStyle(color: muted, fontSize: 12),
      ),
    );
  }
}
