/// Defines standard spacing constants used throughout the application.
///
/// Consistent spacing is crucial for a clean and professional UI.
/// Using these constants ensures uniformity and makes global
/// adjustments easier.
abstract final class AppSpacing {
  /// Extra small spacing value (e.g., 4.0).
  static const double xs = 4;

  /// Small spacing value (e.g., 8.0).
  static const double sm = 8;

  /// Medium spacing value (e.g., 12.0).
  static const double md = 12;

  /// Large spacing value (e.g., 16.0).
  static const double lg = 16;

  /// Extra large spacing value (e.g., 24.0).
  static const double xl = 24;

  /// Extra extra large spacing value (e.g., 32.0).
  static const double xxl = 32;

  // --- Padding Specific ---
  // While the above can be used for padding, specific names can
  // improve clarity.

  /// Small padding value (equivalent to sm).
  static const double paddingSmall = sm;

  /// Medium padding value (equivalent to md).
  static const double paddingMedium = md;

  /// Large padding value (equivalent to lg).
  static const double paddingLarge = lg;

  /// Extra large padding value (equivalent to xl).
  static const double paddingExtraLarge = xl;
}
