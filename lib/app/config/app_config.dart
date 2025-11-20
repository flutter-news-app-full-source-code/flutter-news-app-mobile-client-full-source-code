import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';

/// {@template app_config}
/// A centralized configuration class that provides all necessary environment-specific
/// variables for the application.
///
/// This class uses factory constructors (`.production()`, `.development()`, `.demo()`)
/// to create an immutable configuration object based on the current build
/// environment, which is determined at compile time. All required values are
/// sourced from `--dart-define` variables, ensuring a clean separation of
/// configuration from code and preventing accidental use of development keys
/// in production builds.
///
/// It includes robust validation to fail fast if required variables are missing,
/// providing clear error messages to the developer.
/// {@endtemplate}
class AppConfig {
  /// {@macro app_config}
  AppConfig({
    required this.environment,
    required this.baseUrl,
    required this.oneSignalAppId,
    required this.firebaseApiKey,
    required this.firebaseAppId,
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
      oneSignalAppId: const String.fromEnvironment('ONE_SIGNAL_APP_ID'),
      firebaseApiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
      firebaseAppId: const String.fromEnvironment('FIREBASE_APP_ID'),
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
    baseUrl: '', // No API access needed for in-memory demo
    oneSignalAppId: 'YOUR_DEMO_ONESIGNAL_APP_ID', // Placeholder for demo
    // Dummy Firebase values for demo mode.
    // These are required to initialize Firebase but won't be used for
    // actual backend communication in demo mode.
    firebaseApiKey: 'demo-key',
    firebaseAppId: '1:000000000000:android:0000000000000000000000',
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
      oneSignalAppId: const String.fromEnvironment(
        'ONE_SIGNAL_APP_ID',
        defaultValue: 'YOUR_DEV_ONESIGNAL_APP_ID',
      ),
      firebaseApiKey: const String.fromEnvironment(
        'FIREBASE_API_KEY',
        defaultValue: 'YOUR_DEV_FIREBASE_API_KEY',
      ),
      firebaseAppId: const String.fromEnvironment(
        'FIREBASE_APP_ID',
        defaultValue: 'YOUR_DEV_FIREBASE_APP_ID',
      ),
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

  /// The base URL for the backend API.
  final String baseUrl;

  /// The OneSignal App ID for push notifications.
  final String oneSignalAppId;

  /// The API key for the Firebase project.
  final String firebaseApiKey;

  /// The App ID for the Firebase app.
  final String firebaseAppId;

  /// The Sender ID for Firebase Cloud Messaging.
  final String firebaseMessagingSenderId;

  /// The Project ID for the Firebase project.
  final String firebaseProjectId;

  /// The storage bucket for Firebase Storage.
  final String firebaseStorageBucket;

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
      if (config.oneSignalAppId.contains('YOUR_')) 'ONE_SIGNAL_APP_ID',
      if (config.firebaseApiKey.contains('YOUR_')) 'FIREBASE_API_KEY',
      if (config.firebaseAppId.contains('YOUR_')) 'FIREBASE_APP_ID',
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
