import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';

/// A sealed class representing the outcome of the application's
/// initialization process.
sealed class InitializationResult extends Equatable {
  const InitializationResult();
}

/// Represents a successful initialization of the application.
///
/// This class bundles all the necessary data required for the app to start
/// in a "ready" state. This includes the remote configuration and, if a user
/// is present, their specific settings and preferences.
///
/// **Architectural Hint for Future Maintenance:**
/// This class acts as the "data contract" for a successful startup. If, in the
/// future, a new piece of critical, user-specific data is required for the app
/// to function (e.g., a `UserSubscription` status, A/B testing flags, etc.),
/// it should be added as a property here. The `AppInitializer` would then be
/// updated to fetch this data, and the `App` widget would receive it.
/// is present, their specific settings and preferences.
final class InitializationSuccess extends InitializationResult {
  /// Creates an instance of a successful initialization result.
  const InitializationSuccess({
    required this.remoteConfig,
    this.user,
    this.userContext,
    this.settings,
    this.userContentPreferences,
  });

  /// The globally fetched remote configuration.
  final RemoteConfig remoteConfig;

  /// The initial user, if one was found. Can be anonymous or authenticated.
  final User? user;

  /// The user's context (ephemeral state like feed decorator status).
  final UserContext? userContext;

  /// The user's specific application settings (theme, font, etc.).
  /// Null if the user is unauthenticated.
  final AppSettings? settings;

  /// The user's specific content preferences (followed items, saved articles).
  /// Null if the user is unauthenticated.
  final UserContentPreferences? userContentPreferences;

  @override
  List<Object?> get props => [
    remoteConfig,
    user,
    userContext,
    settings,
    userContentPreferences,
  ];
}

/// Represents a failed initialization of the application.
///
/// This class is returned when a critical, blocking error occurs during
/// startup, such as failing to fetch the remote config or the app being in
/// maintenance mode.
final class InitializationFailure extends InitializationResult {
  /// Creates an instance of a failed initialization result.
  const InitializationFailure({
    required this.status,
    this.error,
    this.currentAppVersion,
    this.latestAppVersion,
  });

  /// The specific status that caused the failure (e.g., `underMaintenance`,
  /// `updateRequired`, `criticalError`).
  final AppLifeCycleStatus status;

  /// The exception that caused the critical error, if applicable.
  final HttpException? error;

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
