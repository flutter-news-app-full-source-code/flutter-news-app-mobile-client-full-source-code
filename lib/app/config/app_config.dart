import 'package:ht_main/app/config/app_environment.dart';

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.baseUrl,
    // Add other environment-specific configs here (e.g., analytics keys)
  });

  final AppEnvironment environment;
  final String baseUrl;

  // Factory constructors for different environments
  factory AppConfig.production() => const AppConfig(
        environment: AppEnvironment.production,
        baseUrl: 'http://api.yourproductiondomain.com', // Replace with actual production URL
      );

  factory AppConfig.developmentInMemory() => const AppConfig(
        environment: AppEnvironment.developmentInMemory,
        baseUrl: 'http://localhost:8080', // Base URL still needed for Auth API client, even if data is in-memory
      );

  factory AppConfig.developmentApi() => const AppConfig( // New: For local Dart Frog API
        environment: AppEnvironment.developmentApi,
        baseUrl: 'http://localhost:8080', // Default Dart Frog local URL
      );
}
