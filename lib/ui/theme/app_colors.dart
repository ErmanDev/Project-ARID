import 'package:flutter/material.dart';

import '../../data/models/enums.dart';

/// Canonical palette. Widgets read colors through [AridPalette] so light,
/// dark and increased-contrast variants stay in one place — never hardcode hex.
///
/// Contrast (WCAG, computed from these sRGB values):
///   ink on surface          15.6 light / 14.8 dark
///   secondary on grouped bg  5.5 light /  8.4 dark
///   accent label on surface  6.0 light /  7.3 dark
///   risk glyphs on surface  ≥4.4 light / ≥6.2 dark (non-text minimum 3:1)
class AppColors {
  AppColors._();

  // Brand: a deep water teal, reserved for primary actions and selection.
  static const Color primary = Color(0xFF2C6B80);
  static const Color primaryDarkMode = Color(0xFF72B6CB);

  // Light appearance.
  static const Color groupedBackground = Color(0xFFF2F4F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color elevated = Color(0xFFF7F9FA);
  static const Color fill = Color(0xFFE9EDEF);
  static const Color ink = Color(0xFF1B2529);
  static const Color secondaryInk = Color(0xFF586569);
  static const Color tertiaryInk = Color(0xFF8A969A);
  static const Color separator = Color(0xFFDCE2E5);
  static const Color accentTint = Color(0xFFE2EEF2);
  static const Color accentInk = Color(0xFF1F5566);

  // Dark appearance: dimmer base, brighter elevated surfaces.
  static const Color darkGroupedBackground = Color(0xFF0B1114);
  static const Color darkSurface = Color(0xFF162024);
  static const Color darkElevated = Color(0xFF1D292E);
  static const Color darkFill = Color(0xFF26343A);
  static const Color darkInk = Color(0xFFEDF3F5);
  static const Color darkSecondaryInk = Color(0xFFA1AFB4);
  static const Color darkTertiaryInk = Color(0xFF6F7F85);
  static const Color darkSeparator = Color(0xFF2A373C);
  static const Color darkAccentTint = Color(0xFF1C3740);
  static const Color darkAccentInk = Color(0xFFBFE6F2);

  // Risk signal colors. Always paired with a glyph shape and a text label.
  static const Color riskRed = Color(0xFFB8434A);
  static const Color riskYellow = Color(0xFFA26F12);
  static const Color riskGreen = Color(0xFF3F8052);
  static const Color darkRiskRed = Color(0xFFF07C80);
  static const Color darkRiskYellow = Color(0xFFE6B558);
  static const Color darkRiskGreen = Color(0xFF7FC592);

  // Supporting hues for settings-style icon tiles.
  static const Color secondary = Color(0xFF3F8052);
  static const Color indigo = Color(0xFF5561B8);
  static const Color amber = Color(0xFFB9791A);
  static const Color slate = Color(0xFF5E6E75);

  static const Color mapBackground = Color(0xFF0B0D0F);

  static Color risk(RiskColor level) {
    switch (level) {
      case RiskColor.red:
        return riskRed;
      case RiskColor.yellow:
        return riskYellow;
      case RiskColor.green:
        return riskGreen;
    }
  }
}

enum RiskColor { red, yellow, green }

/// Colors for one risk level in the current appearance.
class RiskTone {
  const RiskTone({required this.fill, required this.tint, required this.ink});

  /// Glyphs, map markers and bar segments.
  final Color fill;

  /// Badge background.
  final Color tint;

  /// Text on [tint].
  final Color ink;
}

@immutable
class AridPalette extends ThemeExtension<AridPalette> {
  const AridPalette({
    required this.groupedBackground,
    required this.surface,
    required this.elevated,
    required this.fill,
    required this.ink,
    required this.secondaryInk,
    required this.tertiaryInk,
    required this.separator,
    required this.accent,
    required this.onAccent,
    required this.accentTint,
    required this.accentInk,
    required this.high,
    required this.moderate,
    required this.low,
    required this.glassFill,
    required this.glassEdge,
    required this.highContrast,
  });

  final Color groupedBackground;
  final Color surface;
  final Color elevated;
  final Color fill;
  final Color ink;
  final Color secondaryInk;
  final Color tertiaryInk;
  final Color separator;
  final Color accent;
  final Color onAccent;
  final Color accentTint;
  final Color accentInk;
  final RiskTone high;
  final RiskTone moderate;
  final RiskTone low;
  final Color glassFill;
  final Color glassEdge;
  final bool highContrast;

  static AridPalette of(Brightness brightness, {bool highContrast = false}) {
    final dark = brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.ink;
    return AridPalette(
      groupedBackground: dark
          ? AppColors.darkGroupedBackground
          : AppColors.groupedBackground,
      surface: dark ? AppColors.darkSurface : AppColors.surface,
      elevated: dark ? AppColors.darkElevated : AppColors.elevated,
      fill: dark ? AppColors.darkFill : AppColors.fill,
      ink: ink,
      secondaryInk: highContrast
          ? ink
          : dark
          ? AppColors.darkSecondaryInk
          : AppColors.secondaryInk,
      tertiaryInk: highContrast
          ? (dark ? AppColors.darkSecondaryInk : AppColors.secondaryInk)
          : dark
          ? AppColors.darkTertiaryInk
          : AppColors.tertiaryInk,
      separator: highContrast
          ? (dark ? AppColors.darkTertiaryInk : AppColors.tertiaryInk)
          : dark
          ? AppColors.darkSeparator
          : AppColors.separator,
      accent: dark ? AppColors.primaryDarkMode : AppColors.primary,
      onAccent: dark ? const Color(0xFF06212A) : Colors.white,
      accentTint: dark ? AppColors.darkAccentTint : AppColors.accentTint,
      accentInk: dark ? AppColors.darkAccentInk : AppColors.accentInk,
      high: dark
          ? const RiskTone(
              fill: AppColors.darkRiskRed,
              tint: Color(0xFF3A1F22),
              ink: Color(0xFFFFB9BC),
            )
          : const RiskTone(
              fill: AppColors.riskRed,
              tint: Color(0xFFFBEAEA),
              ink: Color(0xFF8E2F36),
            ),
      moderate: dark
          ? const RiskTone(
              fill: AppColors.darkRiskYellow,
              tint: Color(0xFF382C16),
              ink: Color(0xFFF2D08C),
            )
          : const RiskTone(
              fill: AppColors.riskYellow,
              tint: Color(0xFFFAF0DC),
              ink: Color(0xFF7A5208),
            ),
      low: dark
          ? const RiskTone(
              fill: AppColors.darkRiskGreen,
              tint: Color(0xFF1B3322),
              ink: Color(0xFFB5E3C1),
            )
          : const RiskTone(
              fill: AppColors.riskGreen,
              tint: Color(0xFFE6F2E8),
              ink: Color(0xFF2E6140),
            ),
      glassFill: dark ? const Color(0xB3182226) : const Color(0xC7FFFFFF),
      glassEdge: dark ? const Color(0x33FFFFFF) : const Color(0x14000000),
      highContrast: highContrast,
    );
  }

  RiskTone risk(RiskLevel level) => switch (level) {
    RiskLevel.red => high,
    RiskLevel.yellow => moderate,
    RiskLevel.green => low,
  };

  @override
  AridPalette copyWith() => this;

  @override
  AridPalette lerp(AridPalette? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}

extension AridThemeColors on BuildContext {
  AridPalette get arid =>
      Theme.of(this).extension<AridPalette>() ??
      AridPalette.of(Theme.of(this).brightness);
  Color get aridInk => arid.ink;
  Color get aridMuted => arid.secondaryInk;
  Color get aridSurface => arid.surface;
  Color get aridPanel => arid.elevated;
  Color get aridSunken => arid.fill;
  Color get aridBorder => arid.separator;
}
