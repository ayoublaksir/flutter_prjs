import 'package:flutter/material.dart';

/// App color palette following Material Design 3.0 with feminine, luxurious aesthetic
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Brand Colors
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color softRose = Color(0xFFFCE4EC);

  // Semantic Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningAmber = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);

  // Neutral Palette
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color dividerGray = Color(0xFFE0E0E0);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPink, primaryPurple],
    stops: [0.0, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cardWhite, softRose],
    stops: [0.0, 1.0],
  );

  static const LinearGradient achievementGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGold, Color(0xFFFFA500)],
    stops: [0.0, 1.0],
  );

  // Shadow Colors
  static Color shadowColor = Colors.black.withOpacity(0.1);
  static Color shadowColorLight = Colors.black.withOpacity(0.05);

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'skincare': Color(0xFFFFE0EC),
    'makeup': Color(0xFFF8BBD0),
    'haircare': Color(0xFFE1BEE7),
    'fragrance': Color(0xFFD1C4E9),
    'bodycare': Color(0xFFC5CAE9),
  };

  // Achievement Badge Colors
  static const Map<String, Color> achievementColors = {
    'bronze': Color(0xFFCD7F32),
    'silver': Color(0xFFC0C0C0),
    'gold': accentGold,
    'platinum': Color(0xFFE5E4E2),
  };
}
