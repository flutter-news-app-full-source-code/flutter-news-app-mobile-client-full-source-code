import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.baseUrl,
    // Add other environment-specific configs here (e.g., analytics keys)
  });

  // Factory constructors for different environments
  factory AppConfig.production() => const AppConfig(
    environment: AppEnvironment.production,
    // Todo(you): Replace with actual production URL
    baseUrl: 'http://api.yourproductiondomain.com',
  );

  factory AppConfig.demo() => const AppConfig(
    environment: AppEnvironment.demo,
    // No API access needed for in-memory demo
    baseUrl: '',
  );

  factory AppConfig.development() => const AppConfig(
    // For local Dart Frog API
    environment: AppEnvironment.development,
    // Default Dart Frog local URL
    baseUrl: 'http://localhost:8080',
  );

  final AppEnvironment environment;
  final String baseUrl;
}
