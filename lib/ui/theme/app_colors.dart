import 'package:flutter/material.dart';

/// Canonical palette. Widgets must use these constants — never hardcode hex.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4A7A8C);
  static const Color secondary = Color(0xFF6B9080);
  static const Color riskRed = Color(0xFFB5555A);
  static const Color riskYellow = Color(0xFFC9A66B);
  static const Color riskGreen = Color(0xFF7C9C7C);
  static const Color background = Color(0xFFF5F5F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2E3438);
  static const Color textSecondary = Color(0xFF6E7477);
  static const Color divider = Color(0xFFE2E2E0);
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
