
/// Defines standardized layout constants for the application.
abstract final class AppLayout {
  /// The maximum width for primary content containers to ensure readability on
  /// wide screens.
  static const double maxContentWidth = 960;

  /// The maximum width for content inside dialogs or secondary pages.
  static const double maxDialogContentWidth = 720;

  /// The maximum width for authentication forms to maintain focus and readability.
  static const double maxAuthFormWidth = 500;

  /// The breakpoint for switching between phone and tablet layouts.
  static const double tabletBreakpoint = 600;

  /// The maximum cross-axis extent for items in a responsive grid.
  static const double gridMaxCrossAxisExtent = 420;

  /// The desired aspect ratio for items in the responsive grid.
  static const double gridChildAspectRatio = 0.85;
}
