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
}
