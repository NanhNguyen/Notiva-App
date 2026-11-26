import 'package:flutter/material.dart';

/// Color tokens from docs/design.md (Warm Studio Notebook, light mode only).
abstract final class AppColors {
  // Foundation
  static const Color bg = Color(0xFFFAF6EF);
  static const Color surface = Color(0xFFFFFDF8);
  static const Color surfaceVariant = Color(0xFFF2ECE1);
  static const Color border = Color(0xFFE4DBCB);
  static const Color textPrimary = Color(0xFF1F1B18);
  static const Color textSecondary = Color(0xFF6B625A);
  static const Color textTertiary = Color(0xFF9A9086);

  // Brand
  static const Color primary = Color(0xFF8C2F39);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFF3DFE1);
  static const Color accent = Color(0xFFB8893B);
  static const Color accentContainer = Color(0xFFF4E8CF);
  static const Color error = Color(0xFFB3261E);

  // 4-level hand status scale (0..3)
  static const Color statusNotStarted = Color(0xFFD9D0C1);
  static const Color statusLearning = Color(0xFFB8893B);
  static const Color statusSolid = Color(0xFF8FB096);
  static const Color statusMastered = Color(0xFF4F7A5A);

  static const List<Color> statusColors = [
    statusNotStarted,
    statusLearning,
    statusSolid,
    statusMastered,
  ];

  // Practice session outcome chip colors
  static const Color outcomeImprovedBg = Color(0xFFE1ECE3);
  static const Color outcomeImprovedText = Color(0xFF2F5A3A);
  static const Color outcomeSameBg = Color(0xFFF2ECE1);
  static const Color outcomeSameText = Color(0xFF6B625A);
  static const Color outcomeDifficultBg = Color(0xFFF3DFE1);
  static const Color outcomeDifficultText = Color(0xFF8C2F39);

  // Subtle shadow for bottom sheets and floating buttons only (rgba(31,27,24,0.08))
  static const Color shadow = Color(0x141F1B18);
}

