part of 'app_initialization_bloc.dart';

/// {@template app_initialization_state}
/// Base class for all states related to the application initialization process.
/// {@endtemplate}
sealed class AppInitializationState extends Equatable {
  /// {@macro app_initialization_state}
  const AppInitializationState();

  @override
  List<Object> get props => [];
}

/// {@template app_initialization_in_progress}
/// State indicating that the application initialization is currently in
/// progress.
/// {@endtemplate}
final class AppInitializationInProgress extends AppInitializationState {
  /// {@macro app_initialization_in_progress}
  const AppInitializationInProgress();
}

/// {@template app_initialization_success}
/// State indicating that the application has been successfully initialized.
///
/// Contains the successful initialization data.
/// {@endtemplate}
final class AppInitializationSucceeded extends AppInitializationState {
  /// {@macro app_initialization_success}
  const AppInitializationSucceeded(this.initializationSuccess);

  /// The result of a successful initialization, containing all necessary
  /// pre-loaded data like remote config and user settings.
  final InitializationSuccess initializationSuccess;

  @override
  List<Object> get props => [initializationSuccess];
}

/// {@template app_initialization_failure}
/// State indicating that the application initialization has failed.
///
/// Contains the failure details.
/// {@endtemplate}
final class AppInitializationFailed extends AppInitializationState {
  /// {@macro app_initialization_failure}
  const AppInitializationFailed(this.initializationFailure);

  /// The result of a failed initialization, containing the reason for the
  /// failure (e.g., maintenance mode, critical error).
  final InitializationFailure initializationFailure;

  @override
  List<Object> get props => [initializationFailure];
}

/// Represents a successful initialization of the application.
///
/// This class bundles all the necessary data required for the app to start
/// in a "ready" state. This includes the remote configuration and, if a user
/// is present, their specific settings and preferences.
final class InitializationSuccess extends Equatable {
  /// Creates an instance of a successful initialization result.
  const InitializationSuccess({
    required this.remoteConfig,
    this.user,
    this.settings,
    this.userContentPreferences,
  });

  /// The globally fetched remote configuration.
  final RemoteConfig remoteConfig;

  /// The initial user, if one was found. Can be anonymous or authenticated.
  final User? user;

  /// The user's specific application settings (theme, font, etc.).
  /// Null if the user is unauthenticated.
  final UserAppSettings? settings;

  /// The user's specific content preferences (followed items, saved articles).
  /// Null if the user is unauthenticated.
  final UserContentPreferences? userContentPreferences;

  @override
  List<Object?> get props => [
    remoteConfig,
    user,
    settings,
    userContentPreferences,
  ];
}

/// Represents a failed initialization of the application.
///
/// This class is returned when a critical, blocking error occurs during
/// startup, such as failing to fetch the remote config or the app being in
/// maintenance mode.
final class InitializationFailure extends Equatable {
  /// Creates an instance of a failed initialization result.
  InitializationFailure({
    required this.status,
    this.error,
    this.currentAppVersion,
    this.latestAppVersion,
  });

  /// The specific status that caused the failure (e.g., `underMaintenance`,
  /// `updateRequired`, `criticalError`).
  final AppLifeCycleStatus status;

  /// The exception that caused the critical error, if applicable.
  final Exception? error;

  /// The current version of the app, for display on the update page.
  final String? currentAppVersion;

  /// The latest required version from remote config, for the update page.
  final String? latestAppVersion;

  @override
  List<Object?> get props => [
    status,
    error,
    currentAppVersion,
    latestAppVersion,
  ];
}
