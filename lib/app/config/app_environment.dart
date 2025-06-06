/// Defines the different application environments.
enum AppEnvironment {
  /// Represents the production environment.
  ///
  /// This environment is used for the live application, connecting to
  /// production backend services and configurations.
  production,

  /// Represents a development environment connecting to a local API.
  ///
  /// This environment is used during local development, typically connecting
  /// to a locally running Dart Frog backend API.
  development,

  /// Represents a demonstration environment with in-memory data.
  ///
  /// This environment is designed for showcasing the application's user
  /// interface and features without requiring any external backend services.
  /// All data operations are handled by mock data stored directly in memory,
  /// eliminating the need for API access.
  demo,

  // Add other environments like staging, etc. as needed
}
