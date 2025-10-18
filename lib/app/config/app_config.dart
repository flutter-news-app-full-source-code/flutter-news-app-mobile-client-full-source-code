import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';

/// A class to hold all environment-specific configurations.
///
/// This class is instantiated in `main.dart` based on the compile-time
/// environment variable. It provides a type-safe way to access
/// environment-specific values like API base URLs.
class AppConfig {
  /// Creates a new [AppConfig].
  const AppConfig({
    required this.environment,
    required this.baseUrl,
    // Add other environment-specific configs here (e.g., analytics keys)
  });

  /// A factory constructor for the production environment.
  ///
  /// Reads the `BASE_URL` from a compile-time variable. Throws an exception
  /// if the URL is not provided, ensuring a production build cannot proceed
  /// with a missing configuration.
  factory AppConfig.production() => const AppConfig(
    environment: AppEnvironment.production,
    baseUrl: String.fromEnvironment(
      'BASE_URL',
      defaultValue: 'http://localhost:8080',
    ),
  );

  /// A factory constructor for the demo environment.
  factory AppConfig.demo() => const AppConfig(
    environment: AppEnvironment.demo,
    baseUrl: '', // No API access needed for in-memory demo
  );

  /// A factory constructor for the development environment.
  factory AppConfig.development() => const AppConfig(
    environment: AppEnvironment.development,
    baseUrl: 'http://localhost:8080', // Default Dart Frog local URL
  );

  final AppEnvironment environment;
  final String baseUrl;
}
