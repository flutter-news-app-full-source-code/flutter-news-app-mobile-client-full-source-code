//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart'; // Import needed for ThemeData, TextTheme etc.
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
/// Takes the active [scheme] and optional [fontFamily] to allow dynamic theming.
ThemeData lightTheme({
  required FlexScheme scheme,
  String? fontFamily,
}) {
  // Get the appropriate GoogleFonts text theme function
  final textThemeGetter = _getGoogleFontTextTheme(fontFamily);
  // Generate base text theme using the selected Google Font
  final baseTextTheme = textThemeGetter();

  return FlexThemeData.light(
    scheme: scheme, // Use the provided scheme
    fontFamily: fontFamily, // Use provided font family (FlexColorScheme handles null)
    textTheme: _customizeTextTheme(baseTextTheme), // Apply custom sizes/weights
    subThemesData: _commonSubThemesData,
  );
}

/// Defines the application's dark theme using FlexColorScheme.
///
/// Takes the active [scheme] and optional [fontFamily] to allow dynamic theming.
ThemeData darkTheme({
  required FlexScheme scheme,
  String? fontFamily,
}) {
  // Get the appropriate GoogleFonts text theme function
  final textThemeGetter = _getGoogleFontTextTheme(fontFamily);
  // Generate base text theme for dark mode, passing the base dark theme
  // as a positional argument.
  final baseTextTheme = textThemeGetter(
    ThemeData(brightness: Brightness.dark).textTheme,
  );

  return FlexThemeData.dark(
    scheme: scheme, // Use the provided scheme
    fontFamily: fontFamily, // Use provided font family
    textTheme: _customizeTextTheme(baseTextTheme), // Apply custom sizes/weights
    subThemesData: _commonSubThemesData,
  );
}
