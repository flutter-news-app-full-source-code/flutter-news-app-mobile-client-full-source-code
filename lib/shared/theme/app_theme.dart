//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ht_shared/ht_shared.dart';

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
  inputDecoratorRadius: 8,
  // Example: Use outline border (common modern style)
  inputDecoratorIsFilled: false,
  inputDecoratorBorderType: FlexInputBorderType.outline,

  // Add other component themes as needed (Buttons, Dialogs, etc.)
);

// Helper function to apply common text theme customizations
TextTheme _customizeTextTheme(
  TextTheme baseTextTheme, {
  required AppTextScaleFactor appTextScaleFactor,
  required AppFontWeight appFontWeight,
}) {
  print(
    '[_customizeTextTheme] Received appFontWeight: $appFontWeight, appTextScaleFactor: $appTextScaleFactor',
  );
  // Define font size factors
  double factor;
  switch (appTextScaleFactor) {
    case AppTextScaleFactor.small:
      factor = 0.85;
    case AppTextScaleFactor.large:
      factor = 1.15;
    case AppTextScaleFactor.medium:
      factor = 1.0;
    case AppTextScaleFactor.extraLarge:
      factor = 1.3;
  }

  // Helper to apply factor safely
  double? applyFactor(double? baseSize) =>
      baseSize != null ? (baseSize * factor).roundToDouble() : null;

  // Map AppFontWeight to FontWeight
  FontWeight selectedFontWeight;
  switch (appFontWeight) {
    case AppFontWeight.light:
      selectedFontWeight = FontWeight.w300;
    case AppFontWeight.regular:
      selectedFontWeight = FontWeight.w400;
    case AppFontWeight.bold:
      selectedFontWeight = FontWeight.w700;
  }
  print(
    '[_customizeTextTheme] Mapped to selectedFontWeight: $selectedFontWeight',
  );

  return baseTextTheme.copyWith(
    // --- Headline/Title Styles ---
    // Headlines and titles often have their own explicit weights,
    // but we can make them configurable if needed. For now, let's assume
    // body text is the primary target for user-defined weight.
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontSize: applyFactor(28),
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontSize: applyFactor(24),
      fontWeight: FontWeight.bold,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontSize: applyFactor(18),
      fontWeight: FontWeight.w600,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontSize: applyFactor(16),
      fontWeight: FontWeight.w600,
    ),

    // --- Body/Content Styles ---
    // Apply user-selected font weight to body text
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontSize: applyFactor(16),
      height: 1.5,
      fontWeight: selectedFontWeight,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontSize: applyFactor(14),
      height: 1.4,
      fontWeight: selectedFontWeight,
    ),

    // --- Metadata/Caption Styles ---
    // Captions might also benefit from user-defined weight or stay regular.
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontSize: applyFactor(12),
      fontWeight: selectedFontWeight,
    ),

    // --- Button Style (Usually default is fine) ---
    // labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
  );
}

// Helper function to get the appropriate GoogleFonts text theme function
// based on the provided font family name.
// Corrected return type to match GoogleFonts functions (positional optional)
TextTheme Function([TextTheme?]) _getGoogleFontTextTheme(String? fontFamily) {
  print('[_getGoogleFontTextTheme] Received fontFamily: $fontFamily');
  switch (fontFamily) {
    case 'Roboto':
      print('[_getGoogleFontTextTheme] Returning GoogleFonts.robotoTextTheme');
      return GoogleFonts.robotoTextTheme;
    case 'OpenSans':
      print(
        '[_getGoogleFontTextTheme] Returning GoogleFonts.openSansTextTheme',
      );
      return GoogleFonts.openSansTextTheme;
    case 'Lato':
      print('[_getGoogleFontTextTheme] Returning GoogleFonts.latoTextTheme');
      return GoogleFonts.latoTextTheme;
    case 'Montserrat':
      print(
        '[_getGoogleFontTextTheme] Returning GoogleFonts.montserratTextTheme',
      );
      return GoogleFonts.montserratTextTheme;
    case 'Merriweather':
      print(
        '[_getGoogleFontTextTheme] Returning GoogleFonts.merriweatherTextTheme',
      );
      return GoogleFonts.merriweatherTextTheme;
    case 'SystemDefault':
    case null:
    default:
      print(
        '[_getGoogleFontTextTheme] Defaulting to GoogleFonts.notoSansTextTheme for input: $fontFamily',
      );
      return GoogleFonts.notoSansTextTheme;
  }
}

/// Defines the application's light theme using FlexColorScheme.
///
/// Takes the active [scheme], [appTextScaleFactor], [appFontWeight], and optional [fontFamily].
ThemeData lightTheme({
  required FlexScheme scheme,
  required AppTextScaleFactor appTextScaleFactor,
  required AppFontWeight appFontWeight,
  String? fontFamily,
}) {
  print(
    '[AppTheme.lightTheme] Received scheme: $scheme, appTextScaleFactor: $appTextScaleFactor, appFontWeight: $appFontWeight, fontFamily: $fontFamily',
  );
  final textThemeGetter = _getGoogleFontTextTheme(fontFamily);
  final baseTextTheme = textThemeGetter();

  return FlexThemeData.light(
    scheme: scheme,
    fontFamily: fontFamily,
    textTheme: _customizeTextTheme(
      baseTextTheme,
      appTextScaleFactor: appTextScaleFactor,
      appFontWeight: appFontWeight,
    ),
    subThemesData: _commonSubThemesData,
  );
}

/// Defines the application's dark theme using FlexColorScheme.
///
/// Takes the active [scheme], [appTextScaleFactor], [appFontWeight], and optional [fontFamily].
ThemeData darkTheme({
  required FlexScheme scheme,
  required AppTextScaleFactor appTextScaleFactor,
  required AppFontWeight appFontWeight,
  String? fontFamily,
}) {
  print(
    '[AppTheme.darkTheme] Received scheme: $scheme, appTextScaleFactor: $appTextScaleFactor, appFontWeight: $appFontWeight, fontFamily: $fontFamily',
  );
  final textThemeGetter = _getGoogleFontTextTheme(fontFamily);
  final baseTextTheme = textThemeGetter(
    ThemeData(brightness: Brightness.dark).textTheme,
  );

  return FlexThemeData.dark(
    scheme: scheme,
    fontFamily: fontFamily,
    textTheme: _customizeTextTheme(
      baseTextTheme,
      appTextScaleFactor: appTextScaleFactor,
      appFontWeight: appFontWeight,
    ),
    subThemesData: _commonSubThemesData,
  );
}
