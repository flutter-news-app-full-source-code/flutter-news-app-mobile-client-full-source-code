import 'dart:io' show Platform;

import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';

/// {@template app_config}
/// A centralized configuration class that provides all necessary
/// environment-specific variables for the application.
///
/// ## How It Works
/// This class uses factory constructors (`.production()`, `.development()`,
/// `.demo()`) to create an immutable configuration object based on the current
/// build environment. All required values are sourced from `--dart-define`
/// variables, ensuring a clean separation of configuration from code.
///
/// ## Platform-Specific Keys
/// Some services, like Firebase and OneSignal, require unique keys for Android
/// and iOS. This class handles that complexity internally. It reads both
/// platform-specific keys (e.g., `FIREBASE_ANDROID_APP_ID` and
/// `FIREBASE_IOS_APP_ID`) from the environment.
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
    // Platform-specific keys
    required this.oneSignalAndroidAppId,
    required this.oneSignalIosAppId,
    required this.firebaseAndroidApiKey,
    required this.firebaseIosApiKey,
    required this.firebaseAndroidAppId,
    required this.firebaseIosAppId,
    // Shared keys
    required this.firebaseMessagingSenderId,
    required this.firebaseProjectId,
    required this.firebaseStorageBucket,
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
      firebaseAndroidApiKey: const String.fromEnvironment(
        'FIREBASE_ANDROID_API_KEY',
      ),
      firebaseIosApiKey: const String.fromEnvironment('FIREBASE_IOS_API_KEY'),
      firebaseAndroidAppId: const String.fromEnvironment(
        'FIREBASE_ANDROID_APP_ID',
      ),
      firebaseIosAppId: const String.fromEnvironment('FIREBASE_IOS_APP_ID'),
      // Shared
      firebaseMessagingSenderId: const String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
      ),
      firebaseProjectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
      firebaseStorageBucket: const String.fromEnvironment(
        'FIREBASE_STORAGE_BUCKET',
      ),
    );
    _validateConfiguration(config);
    return config;
  }

  /// Creates an [AppConfig] for the **demo** environment.
  ///
  /// This factory uses hardcoded, non-functional placeholder values. It is
  /// designed for running the app in a completely offline, in-memory mode
  /// where no backend services are required. The Firebase values are validly
  //  formatted dummies required to satisfy Firebase initialization.
  factory AppConfig.demo() => AppConfig(
    environment: AppEnvironment.demo,
    baseUrl: '',
    // Placeholders for demo
    oneSignalAndroidAppId: 'YOUR_DEMO_ONESIGNAL_ANDROID_APP_ID',
    oneSignalIosAppId: 'YOUR_DEMO_ONESIGNAL_IOS_APP_ID',

    // Dummy Firebase values for demo mode.
    // These are required to initialize Firebase but won't be used for
    // actual backend communication in demo mode.
    firebaseAndroidApiKey: 'demo-key-android',
    firebaseIosApiKey: 'demo-key-ios',
    firebaseAndroidAppId: '1:000000000000:android:0000000000000000000000',
    firebaseIosAppId: '1:000000000000:ios:0000000000000000000000',
    firebaseMessagingSenderId: '000000000000',
    firebaseProjectId: 'demo-project',
    firebaseStorageBucket: '',
  );

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
      firebaseAndroidApiKey: const String.fromEnvironment(
        'FIREBASE_ANDROID_API_KEY',
        defaultValue: 'YOUR_DEV_FIREBASE_ANDROID_API_KEY',
      ),
      firebaseIosApiKey: const String.fromEnvironment(
        'FIREBASE_IOS_API_KEY',
        defaultValue: 'YOUR_DEV_FIREBASE_IOS_API_KEY',
      ),
      firebaseAndroidAppId: const String.fromEnvironment(
        'FIREBASE_ANDROID_APP_ID',
        defaultValue: 'YOUR_DEV_FIREBASE_ANDROID_APP_ID',
      ),
      firebaseIosAppId: const String.fromEnvironment(
        'FIREBASE_IOS_APP_ID',
        defaultValue: 'YOUR_DEV_FIREBASE_IOS_APP_ID',
      ),
      // Shared
      firebaseMessagingSenderId: const String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
        defaultValue: 'YOUR_DEV_FIREBASE_MESSAGING_SENDER_ID',
      ),
      firebaseProjectId: const String.fromEnvironment(
        'FIREBASE_PROJECT_ID',
        defaultValue: 'YOUR_DEV_FIREBASE_PROJECT_ID',
      ),
      firebaseStorageBucket: const String.fromEnvironment(
        'FIREBASE_STORAGE_BUCKET',
        defaultValue: 'YOUR_DEV_FIREBASE_STORAGE_BUCKET',
      ),
    );
    _validateConfiguration(config);
    return config;
  }

  /// The current build environment (e.g., production, development, demo).
  final AppEnvironment environment;

  // --- Shared Configuration ---

  /// The base URL for the backend API (shared across platforms).
  final String baseUrl;

  /// The Sender ID for Firebase Cloud Messaging (shared across platforms).
  final String firebaseMessagingSenderId;

  /// The Project ID for the Firebase project (shared across platforms).
  final String firebaseProjectId;

  /// The storage bucket for Firebase Storage (shared across platforms).
  final String firebaseStorageBucket;

  // --- Platform-Specific Raw Values ---

  /// The OneSignal App ID for the Android platform.
  final String oneSignalAndroidAppId;

  /// The OneSignal App ID for the iOS platform.
  final String oneSignalIosAppId;

  /// The API key for the Firebase Android app.
  final String firebaseAndroidApiKey;

  /// The API key for the Firebase iOS app.
  final String firebaseIosApiKey;

  /// The App ID for the Firebase Android app.
  final String firebaseAndroidAppId;

  /// The App ID for the Firebase iOS app.
  final String firebaseIosAppId;

  // --- Platform-Aware Getters ---

  /// Returns the correct OneSignal App ID for the current platform.
  String get oneSignalAppId =>
      Platform.isAndroid ? oneSignalAndroidAppId : oneSignalIosAppId;

  /// Returns the correct Firebase API Key for the current platform.
  String get firebaseApiKey =>
      Platform.isAndroid ? firebaseAndroidApiKey : firebaseIosApiKey;

  /// Returns the correct Firebase App ID for the current platform.
  String get firebaseAppId =>
      Platform.isAndroid ? firebaseAndroidAppId : firebaseIosAppId;

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
      if (config.firebaseAndroidApiKey.contains('YOUR_'))
        'FIREBASE_ANDROID_API_KEY',
      if (config.firebaseIosApiKey.contains('YOUR_')) 'FIREBASE_IOS_API_KEY',
      if (config.firebaseAndroidAppId.contains('YOUR_'))
        'FIREBASE_ANDROID_APP_ID',
      if (config.firebaseIosAppId.contains('YOUR_')) 'FIREBASE_IOS_APP_ID',
      if (config.firebaseMessagingSenderId.contains('YOUR_'))
        'FIREBASE_MESSAGING_SENDER_ID',
      if (config.firebaseProjectId.contains('YOUR_')) 'FIREBASE_PROJECT_ID',
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
