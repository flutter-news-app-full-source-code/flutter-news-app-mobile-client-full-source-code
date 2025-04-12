//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ht_preferences_client/ht_preferences_client.dart'; // Added for FontSize

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
TextTheme _customizeTextTheme(
  TextTheme baseTextTheme, {
  required FontSize appFontSize, // Added parameter
}) {
  // Define font size factors
  double factor;
  switch (appFontSize) {
    case FontSize.small:
      factor = 0.85;
    case FontSize.large:
      factor = 1.15;
    case FontSize.medium:
      factor = 1.0;
  }

  // Helper to apply factor safely
  double? applyFactor(double? baseSize) =>
      baseSize != null ? (baseSize * factor).roundToDouble() : null;

  return baseTextTheme.copyWith(
    // --- Headline/Title Styles ---
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontSize: applyFactor(28), // Apply factor
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontSize: applyFactor(24), // Apply factor
      fontWeight: FontWeight.bold,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontSize: applyFactor(18), // Apply factor
      fontWeight: FontWeight.w600,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontSize: applyFactor(16), // Apply factor
      fontWeight: FontWeight.w600,
    ),

    // --- Body/Content Styles ---
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontSize: applyFactor(16), // Apply factor
      height: 1.5,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontSize: applyFactor(14), // Apply factor
      height: 1.4,
    ),

    // --- Metadata/Caption Styles ---
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontSize: applyFactor(12), // Apply factor
      fontWeight: FontWeight.normal,
    ),

    // --- Button Style (Usually default is fine) ---
    // labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
  );
}

// Helper function to get the appropriate GoogleFonts text theme function
// based on the provided font family name.
// Corrected return type to match GoogleFonts functions (positional optional)
TextTheme Function([TextTheme?]) _getGoogleFontTextTheme(String? fontFamily) {
  // Map font family names (as used in AppBloc mapping) to GoogleFonts functions
  if (fontFamily == GoogleFonts.roboto().fontFamily) {
    return GoogleFonts.robotoTextTheme;
  }
  if (fontFamily == GoogleFonts.openSans().fontFamily) {
    return GoogleFonts.openSansTextTheme;
  }
  if (fontFamily == GoogleFonts.lato().fontFamily) {
    return GoogleFonts.latoTextTheme;
  }
  if (fontFamily == GoogleFonts.montserrat().fontFamily) {
    return GoogleFonts.montserratTextTheme;
  }
  if (fontFamily == GoogleFonts.merriweather().fontFamily) {
    return GoogleFonts.merriweatherTextTheme;
  }
  // Add mappings for other AppFontType values if needed

  // Default fallback if fontFamily is null or not recognized
  return GoogleFonts.notoSansTextTheme;
}

/// Defines the application's light theme using FlexColorScheme.
///
/// Takes the active [scheme], [appFontSize], and optional [fontFamily].
ThemeData lightTheme({
  required FlexScheme scheme,
  required FontSize appFontSize, // Added parameter
  String? fontFamily,
}) {
  final textThemeGetter = _getGoogleFontTextTheme(fontFamily);
  final baseTextTheme = textThemeGetter();

  return FlexThemeData.light(
    scheme: scheme,
    fontFamily: fontFamily,
    // Pass appFontSize to customizeTextTheme
    textTheme: _customizeTextTheme(baseTextTheme, appFontSize: appFontSize),
    subThemesData: _commonSubThemesData,
  );
}

/// Defines the application's dark theme using FlexColorScheme.
///
/// Takes the active [scheme], [appFontSize], and optional [fontFamily].
ThemeData darkTheme({
  required FlexScheme scheme,
  required FontSize appFontSize, // Added parameter
  String? fontFamily,
}) {
  final textThemeGetter = _getGoogleFontTextTheme(fontFamily);
  final baseTextTheme = textThemeGetter(
    ThemeData(brightness: Brightness.dark).textTheme,
  );

  return FlexThemeData.dark(
    scheme: scheme,
    fontFamily: fontFamily,
    // Pass appFontSize to customizeTextTheme
    textTheme: _customizeTextTheme(baseTextTheme, appFontSize: appFontSize),
    subThemesData: _commonSubThemesData,
  );
}
