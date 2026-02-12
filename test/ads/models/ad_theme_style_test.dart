import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('AdThemeStyle', () {
    test('fromTheme factory correctly extracts properties from ThemeData', () {
      // Arrange
      final testTheme = ThemeData(
        colorScheme: const ColorScheme.light(
          surface: Colors.white,
          onSurface: Colors.black,
          primary: Colors.blue,
          onPrimary: Colors.white,
          onSurfaceVariant: Colors.grey,
        ),
        textTheme: const TextTheme(
          labelLarge: TextStyle(fontSize: 16),
          titleMedium: TextStyle(fontSize: 20),
          bodyMedium: TextStyle(fontSize: 14),
          labelSmall: TextStyle(fontSize: 12),
        ),
      );

      // Act
      final adThemeStyle = AdThemeStyle.fromTheme(testTheme);

      // Assert
      expect(adThemeStyle.mainBackgroundColor, equals(Colors.white));
      expect(adThemeStyle.cornerRadius, equals(AppSpacing.sm));
      expect(adThemeStyle.callToActionTextColor, equals(Colors.white));
      expect(adThemeStyle.callToActionBackgroundColor, equals(Colors.blue));
      expect(adThemeStyle.callToActionTextSize, equals(16));
      expect(adThemeStyle.primaryTextColor, equals(Colors.black));
      expect(adThemeStyle.primaryBackgroundColor, equals(Colors.white));
      expect(adThemeStyle.primaryTextSize, equals(20));
      expect(adThemeStyle.secondaryTextColor, equals(Colors.grey));
      expect(adThemeStyle.secondaryBackgroundColor, equals(Colors.white));
      expect(adThemeStyle.secondaryTextSize, equals(14));
      expect(adThemeStyle.tertiaryTextColor, equals(Colors.grey));
      expect(adThemeStyle.tertiaryBackgroundColor, equals(Colors.white));
      expect(adThemeStyle.tertiaryTextSize, equals(12));
    });

    test('props are correct', () {
      const style = AdThemeStyle(
        mainBackgroundColor: Colors.red,
        cornerRadius: 8,
        callToActionTextColor: Colors.white,
        callToActionBackgroundColor: Colors.blue,
        callToActionTextSize: 16,
        primaryTextColor: Colors.black,
        primaryBackgroundColor: Colors.white,
        primaryTextSize: 20,
        secondaryTextColor: Colors.grey,
        secondaryBackgroundColor: Colors.white,
        secondaryTextSize: 14,
        tertiaryTextColor: Colors.grey,
        tertiaryBackgroundColor: Colors.white,
        tertiaryTextSize: 12,
      );

      expect(style.props.length, 14);
    });
  });
}
