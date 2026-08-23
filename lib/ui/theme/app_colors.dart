import 'package:flutter/material.dart';

/// Canonical palette. Widgets must use these constants — never hardcode hex.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4A7A8C);
  static const Color primaryDark = Color(0xFF356273);
  static const Color primaryTint = Color(0xFFEDF5F7);
  static const Color primaryEdge = Color(0xFFB8D3DC);
  static const Color secondary = Color(0xFF6B9080);
  static const Color riskRed = Color(0xFFB5555A);
  static const Color riskYellow = Color(0xFFC9A66B);
  static const Color riskGreen = Color(0xFF7C9C7C);
  static const Color riskRedTint = Color(0xFFFBEDEF);
  static const Color riskRedEdge = Color(0xFFE5ADB1);
  static const Color riskRedInk = Color(0xFF853D43);
  static const Color riskYellowTint = Color(0xFFFAF2E5);
  static const Color riskYellowEdge = Color(0xFFE3C58F);
  static const Color riskYellowInk = Color(0xFF765A2D);
  static const Color riskGreenTint = Color(0xFFEDF5ED);
  static const Color riskGreenEdge = Color(0xFFB7CFB7);
  static const Color riskGreenInk = Color(0xFF466B4B);

  // Dashboard surface register: sunken < background < panel < surface.
  static const Color background = Color(0xFFF3F6F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color panel = Color(0xFFF8FAFB);
  static const Color sunken = Color(0xFFEDF1F2);
  static const Color textPrimary = Color(0xFF293438);
  static const Color textSecondary = Color(0xFF59676C);
  static const Color muted = Color(0xFF6E7C81);
  static const Color divider = Color(0xFFDCE3E5);
  static const Color borderStrong = Color(0xFF87979D);
  static const Color darkBackground = Color(0xFF0F181E);
  static const Color darkSurface = Color(0xFF17232B);
  static const Color darkPanel = Color(0xFF111C22);
  static const Color darkSunken = Color(0xFF22323A);
  static const Color darkTextPrimary = Color(0xFFF2F6F7);
  static const Color darkTextSecondary = Color(0xFFAAB7BC);
  static const Color darkDivider = Color(0xFF2D3B43);
  static const Color darkBorderStrong = Color(0xFF51616A);
  static const Color mapBackground = Color(0xFF0B0D0F);
  static const Color mapChrome = Color(0xFF1C2226);

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

extension AridThemeColors on BuildContext {
  Color get aridInk => Theme.of(this).colorScheme.onSurface;
  Color get aridMuted => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get aridSurface => Theme.of(this).colorScheme.surface;
  Color get aridPanel => Theme.of(this).colorScheme.surfaceContainerLow;
  Color get aridSunken => Theme.of(this).colorScheme.surfaceContainer;
  Color get aridBorder => Theme.of(this).colorScheme.outlineVariant;
}
