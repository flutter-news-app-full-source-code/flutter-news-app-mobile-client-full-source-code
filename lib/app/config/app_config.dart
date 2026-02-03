import 'dart:io' show Platform;

import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';

/// {@template app_config}
/// A centralized configuration class that provides all necessary
/// environment-specific variables for the application.
///
/// ## How It Works
/// This class uses factory constructors (`.production()`, `.development()`,
/// ) to create an immutable configuration object based on the current
/// build environment. All required values are sourced from `--dart-define`
/// variables, ensuring a clean separation of configuration from code.
///
/// ## Platform-Specific Keys
/// Some services, like Firebase and OneSignal, require unique keys for Android
/// and iOS. This class handles that complexity internally. It reads both
/// platform-specific keys (for both Android and iOS) from the environment.
///
/// It then exposes simple, platform-aware getters (e.g., `firebaseAppId`).
/// These getters automatically return the correct key based on the current
/// operating system (`Platform.isAndroid` or `Platform.isIOS`). This means the
/// rest of the application can simply use `appConfig.firebaseAppId` without
/// needing to know which platform it's running on.
///
/// ## Validation
/// The class includes a `_validateConfiguration` method that runs for
/// `development` and `production` environments. It fails fast if:
/// - A required key is missing.
/// - A key still contains a placeholder value (e.g., 'YOUR_DEV_...').
/// This prevents runtime errors and ensures a correctly configured build.
///
/// ## Handling Single-Platform Builds
/// The validation logic requires that all platform-specific keys (for both
/// Android and iOS) are provided. If you are developing for a single platform
/// (e.g., only Android), you must still provide non-placeholder values for the
/// other platform's keys to satisfy the validator.
///
/// For any unused platform keys, you can provide a simple dummy string like
/// `"unused-ios-key"`. As long as the value does not contain the "YOUR_"
/// prefix, the validation will pass. These dummy values will not be used when
/// building for your target platform.
/// {@endtemplate}
class AppConfig {
  /// {@macro app_config}
  AppConfig({
    required this.environment,
    required this.baseUrl,
    required this.oneSignalAndroidAppId,
    required this.oneSignalIosAppId,
    required this.mixpanelProjectToken,
    // Add other environment-specific configs here (e.g., analytics keys)
  });

  /// Creates an [AppConfig] for the **production** environment.
  ///
  /// This factory reads all values directly from `String.fromEnvironment`.
  /// It does **not** provide default values. If any required variable is missing,
  /// the `_validateConfiguration` method will throw a [FormatException],
  /// causing the build to fail. This is a critical safety measure.
  factory AppConfig.production() {
    final config = AppConfig(
      environment: AppEnvironment.production,
      baseUrl: const String.fromEnvironment('BASE_URL'),
      // Platform-specific
      oneSignalAndroidAppId: const String.fromEnvironment(
        'ONE_SIGNAL_ANDROID_APP_ID',
      ),
      oneSignalIosAppId: const String.fromEnvironment('ONE_SIGNAL_IOS_APP_ID'),
      mixpanelProjectToken: const String.fromEnvironment(
        'MIXPANEL_PROJECT_TOKEN',
      ),
    );
    _validateConfiguration(config);
    return config;
  }

  /// Creates an [AppConfig] for the **development** environment.
  ///
  /// This factory reads values from `String.fromEnvironment` but provides
  /// `defaultValue`s for convenience during local development. If a developer
  /// runs the app without providing a specific `--dart-define` variable, the
  /// validation will catch the placeholder value (e.g., 'YOUR_DEV_...'),
  /// and throw a helpful error, guiding them to configure their environment.
  factory AppConfig.development() {
    final config = AppConfig(
      environment: AppEnvironment.development,
      baseUrl: const String.fromEnvironment(
        'BASE_URL',
        defaultValue: 'http://localhost:8080',
      ),
      // Platform-specific
      oneSignalAndroidAppId: const String.fromEnvironment(
        'ONE_SIGNAL_ANDROID_APP_ID',
        defaultValue: 'YOUR_DEV_ONESIGNAL_ANDROID_APP_ID',
      ),
      oneSignalIosAppId: const String.fromEnvironment(
        'ONE_SIGNAL_IOS_APP_ID',
        defaultValue: 'YOUR_DEV_ONESIGNAL_IOS_APP_ID',
      ),
      mixpanelProjectToken: const String.fromEnvironment(
        'MIXPANEL_PROJECT_TOKEN',
        defaultValue: 'YOUR_DEV_MIXPANEL_PROJECT_TOKEN',
      ),
    );
    _validateConfiguration(config);
    return config;
  }

  /// The current build environment (e.g., production, development).
  final AppEnvironment environment;

  // --- Shared Configuration ---

  /// The base URL for the backend API (shared across platforms).
  final String baseUrl;

  // --- Platform-Specific Raw Values ---

  /// The OneSignal App ID for the Android platform.
  final String oneSignalAndroidAppId;

  /// The OneSignal App ID for the iOS platform.
  final String oneSignalIosAppId;

  /// The Project Token for Mixpanel Analytics.
  final String mixpanelProjectToken;

  // --- Platform-Aware Getters ---

  /// Returns the correct OneSignal App ID for the current platform.
  String get oneSignalAppId =>
      Platform.isAndroid ? oneSignalAndroidAppId : oneSignalIosAppId;

  /// A private static method to validate the loaded configuration.
  ///
  /// Throws a [FormatException] if any required environment variables are
  /// missing or still set to placeholder values. This ensures that both
  /// production and development builds fail fast with clear instructions
  /// if not configured correctly.
  ///
  /// #### Validation Checks:
  /// - Ensures `BASE_URL` is not empty or a localhost URL in production.
  /// - Checks for any placeholder values (containing 'YOUR_') in critical keys,
  ///   which indicates a misconfigured development environment.
  static void _validateConfiguration(AppConfig config) {
    final errors = <String>[];

    if (config.baseUrl.isEmpty || config.baseUrl.contains('localhost')) {
      if (config.environment == AppEnvironment.production) {
        errors.add('- BASE_URL is not set for production.');
      }
    }

    final placeholderKeys = [
      if (config.oneSignalAndroidAppId.contains('YOUR_'))
        'ONE_SIGNAL_ANDROID_APP_ID',
      if (config.oneSignalIosAppId.contains('YOUR_')) 'ONE_SIGNAL_IOS_APP_ID',
      if (config.mixpanelProjectToken.contains('YOUR_'))
        'MIXPANEL_PROJECT_TOKEN',
    ];

    if (placeholderKeys.isNotEmpty) {
      errors.add(
        '- The following keys have placeholder values: ${placeholderKeys.join(', ')}.',
      );
    }

    if (errors.isNotEmpty) {
      throw FormatException(
        'FATAL: Invalid app configuration for ${config.environment.name} environment.\n'
        'Please provide the required --dart-define values.\n'
        '${errors.join('\n')}',
      );
    }
  }
}
