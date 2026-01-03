// theme.dart
// Global theme configuration for the app

import 'package:flutter/material.dart';

// Colors
const Color primaryColor = Color(0xFF2E5BFF);
const Color secondaryColor = Color(0xFF03A9F4);
const Color accentColor = Color(0xFF4CAF50);
const Color errorColor = Color(0xFFE53935);
const Color backgroundColor = Color(0xFFF8F9FB);
const Color surfaceColor = Colors.white;
const Color textPrimaryColor = Color(0xFF333333);
const Color textSecondaryColor = Color(0xFF757575);
const Color borderColor = Color(0xFFEEEEEE);

// Text Styles
const TextStyle headingStyle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.bold,
  color: textPrimaryColor,
);

const TextStyle subheadingStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: textPrimaryColor,
);

const TextStyle bodyStyle = TextStyle(fontSize: 16, color: textPrimaryColor);

const TextStyle captionStyle = TextStyle(
  fontSize: 14,
  color: textSecondaryColor,
);

// App Theme
final ThemeData appTheme = ThemeData(
  primaryColor: primaryColor,
  colorScheme: ColorScheme.light(
    primary: primaryColor,
    secondary: secondaryColor,
    surface: surfaceColor,
    background: backgroundColor,
    error: errorColor,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: textPrimaryColor,
    onBackground: textPrimaryColor,
    onError: Colors.white,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: backgroundColor,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: textPrimaryColor,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: textPrimaryColor,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: primaryColor),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      side: const BorderSide(color: primaryColor, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: primaryColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: errorColor),
    ),
    hintStyle: const TextStyle(color: textSecondaryColor),
    labelStyle: const TextStyle(color: textSecondaryColor),
  ),
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: primaryColor,
    unselectedItemColor: textSecondaryColor,
    selectedLabelStyle: TextStyle(fontSize: 12),
    unselectedLabelStyle: TextStyle(fontSize: 12),
    elevation: 8,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: backgroundColor,
    disabledColor: backgroundColor,
    selectedColor: primaryColor.withOpacity(0.1),
    secondarySelectedColor: primaryColor.withOpacity(0.1),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    labelStyle: const TextStyle(color: textPrimaryColor),
    secondaryLabelStyle: const TextStyle(color: primaryColor),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(50),
      side: const BorderSide(color: borderColor),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: borderColor,
    thickness: 1,
    space: 24,
  ),
  // Use Material 3 features
  useMaterial3: true,
);
