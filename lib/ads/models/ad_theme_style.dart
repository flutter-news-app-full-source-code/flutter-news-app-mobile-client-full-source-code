import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template ad_theme_style}
/// A UI-agnostic data model representing the theme properties required for
/// styling native advertisements.
///
/// This class decouples ad styling logic from Flutter's [ThemeData],
/// allowing theme-related values to be passed to service layers without
/// direct UI context dependencies.
/// {@endtemplate}
class AdThemeStyle extends Equatable {
  /// {@macro ad_theme_style}
  const AdThemeStyle({
    required this.mainBackgroundColor,
    required this.cornerRadius,
    required this.callToActionTextColor,
    required this.callToActionBackgroundColor,
    required this.callToActionTextSize,
    required this.primaryTextColor,
    required this.primaryBackgroundColor,
    required this.primaryTextSize,
    required this.secondaryTextColor,
    required this.secondaryBackgroundColor,
    required this.secondaryTextSize,
    required this.tertiaryTextColor,
    required this.tertiaryBackgroundColor,
    required this.tertiaryTextSize,
  });

  /// Factory constructor to create an [AdThemeStyle] from a Flutter [ThemeData].
  ///
  /// This method acts as an adapter, extracting the relevant styling properties
  /// from the UI's theme and mapping them to the UI-agnostic [AdThemeStyle] model.
  factory AdThemeStyle.fromTheme(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AdThemeStyle(
      mainBackgroundColor: colorScheme.surface,
      cornerRadius: AppSpacing.sm, 
      callToActionTextColor: colorScheme.onPrimary,
      callToActionBackgroundColor: colorScheme.primary,
      callToActionTextSize: textTheme.labelLarge?.fontSize,
      primaryTextColor: colorScheme.onSurface,
      primaryBackgroundColor: colorScheme.surface,
      primaryTextSize: textTheme.titleMedium?.fontSize,
      secondaryTextColor: colorScheme.onSurfaceVariant,
      secondaryBackgroundColor: colorScheme.surface,
      secondaryTextSize: textTheme.bodyMedium?.fontSize,
      tertiaryTextColor: colorScheme.onSurfaceVariant,
      tertiaryBackgroundColor: colorScheme.surface,
      tertiaryTextSize: textTheme.labelSmall?.fontSize,
    );
  }

  /// The background color for the main ad container.
  final Color mainBackgroundColor;

  /// The corner radius for the ad container.
  final double cornerRadius;

  /// The text color for the call-to-action button.
  final Color callToActionTextColor;

  /// The background color for the call-to-action button.
  final Color callToActionBackgroundColor;

  /// The font size for the call-to-action text.
  final double? callToActionTextSize;

  /// The text color for the primary text (e.g., ad headline).
  final Color primaryTextColor;

  /// The background color for the primary text.
  final Color primaryBackgroundColor;

  /// The font size for the primary text.
  final double? primaryTextSize;

  /// The text color for the secondary text (e.g., ad body).
  final Color secondaryTextColor;

  /// The background color for the secondary text.
  final Color secondaryBackgroundColor;

  /// The font size for the secondary text.
  final double? secondaryTextSize;

  /// The text color for the tertiary text (e.g., ad attribution).
  final Color tertiaryTextColor;

  /// The background color for the tertiary text.
  final Color tertiaryBackgroundColor;

  /// The font size for the tertiary text.
  final double? tertiaryTextSize;

  @override
  List<Object?> get props => [
        mainBackgroundColor,
        cornerRadius,
        callToActionTextColor,
        callToActionBackgroundColor,
        callToActionTextSize,
        primaryTextColor,
        primaryBackgroundColor,
        primaryTextSize,
        secondaryTextColor,
        secondaryBackgroundColor,
        secondaryTextSize,
        tertiaryTextColor,
        tertiaryBackgroundColor,
        tertiaryTextSize,
      ];
}
