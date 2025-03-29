//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Common Sub-theme Settings ---
// Defines customizations for various components, shared between light/dark themes.
const FlexSubThemesData _commonSubThemesData = FlexSubThemesData(
  // --- Card Theme ---
  // Slightly rounded corners for cards (headline items)
  cardRadius: 8,
  // Use default elevation or specify if needed: cardElevation: 2.0,

  // --- AppBar Theme ---
  // Example: Use scheme surface color for app bar (often less distracting)
  appBarBackgroundSchemeColor: SchemeColor.surface,
  // Or keep default: appBarBackgroundSchemeColor: SchemeColor.primary,
  // Example: Center title? appBarCenterTitle: true,

  // --- Input Decorator (for Search TextField) ---
  // Example: Add a border radius
  inputDecoratorRadius: 8, // Corrected parameter name
  // Example: Use outline border (common modern style)
  inputDecoratorIsFilled: false, // Set to false if using outline border
  inputDecoratorBorderType: FlexInputBorderType.outline,

  // Add other component themes as needed (Buttons, Dialogs, etc.)
);

// Helper function to apply common text theme customizations
TextTheme _customizeTextTheme(TextTheme baseTextTheme) {
  return baseTextTheme.copyWith(
    // --- Headline/Title Styles ---
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontSize: 28, // Example size for main article title on details page
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontSize: 24, // Slightly smaller alternative for details page title
      fontWeight: FontWeight.bold,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontSize: 18, // For Headline.title in lists (Feed, Search)
      fontWeight: FontWeight.w600, // Semi-bold
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontSize: 16, // Alternative for list titles
      fontWeight: FontWeight.w600,
    ),

    // --- Body/Content Styles ---
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontSize: 16, // For main article content paragraphs
      height: 1.5, // Improve readability with line height
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontSize: 14, // For Headline.description in lists
      height: 1.4,
    ),

    // --- Metadata/Caption Styles ---
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontSize: 12, // For metadata (date, source, category)
      fontWeight: FontWeight.normal,
      // Consider a slightly muted color via ColorScheme if needed
    ),

    // --- Button Style (Usually default is fine) ---
    // labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
  );
}

/// Defines the application's light theme using FlexColorScheme.
ThemeData lightTheme() {
  // Generate base text theme using GoogleFonts
  final baseTextTheme = GoogleFonts.notoSansTextTheme();

  return FlexThemeData.light(
    scheme: FlexScheme.material,
    // Use Noto Sans font from Google Fonts.
    fontFamily:
        baseTextTheme.bodyLarge?.fontFamily, // Use font family from base
    textTheme: _customizeTextTheme(baseTextTheme), // Use helper function
    subThemesData: _commonSubThemesData, // Use the common sub-theme data
  );
}

/// Defines the application's dark theme using FlexColorScheme.
ThemeData darkTheme() {
  // Generate base text theme using GoogleFonts
  final baseTextTheme = GoogleFonts.notoSansTextTheme(
    // Ensure dark theme uses appropriate brightness for text colors
    ThemeData(brightness: Brightness.dark).textTheme,
  );

  return FlexThemeData.dark(
    scheme: FlexScheme.material,
    // Use Noto Sans font from Google Fonts.
    fontFamily:
        baseTextTheme.bodyLarge?.fontFamily, // Use font family from base
    textTheme: _customizeTextTheme(baseTextTheme), // Use helper function
    subThemesData: _commonSubThemesData, // Use the common sub-theme data
  );
}
