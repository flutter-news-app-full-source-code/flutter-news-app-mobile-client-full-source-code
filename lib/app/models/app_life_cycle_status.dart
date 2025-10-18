/// Defines the various statuses of the application's overall state.
///
/// This enum helps manage the application's flow, especially during startup
/// and critical operations like fetching remote configuration or handling
/// authentication changes.
enum AppLifeCycleStatus {
  /// The application is currently loading user-specific data (settings, preferences).
  loadingUserData,

  /// The user is not authenticated.
  unauthenticated,

  /// The user is authenticated (e.g., standard user).
  authenticated,

  /// The user is anonymous (e.g., guest user).
  anonymous,

  /// A critical error occurred during application startup,
  /// preventing normal operation.
  criticalError,

  /// The application is currently under maintenance.
  underMaintenance,

  /// A mandatory update is required for the application.
  updateRequired,
}
