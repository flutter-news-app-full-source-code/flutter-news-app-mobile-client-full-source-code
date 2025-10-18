import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/config.dart'
    as local_config;
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_initializer_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_migration_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/package_info_service.dart';
import 'package:logging/logging.dart';
import 'package:pub_semver/pub_semver.dart';

/// A sealed class representing the outcome of the application's
/// initialization process.
///
/// This is used by the [AppInitializer] to return a single, definitive result
/// to the `bootstrap` function, which then passes it to the `AppBloc`.
abstract sealed class InitializationResult {
  const InitializationResult();
}

/// Represents a successful initialization of the application.
///
/// This class bundles all the necessary data required for the app to start
/// in a "ready" state. This includes the remote configuration and, if a user
/// is present, their specific settings and preferences.
final class InitializationSuccess extends InitializationResult {
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
}

/// A dedicated service that orchestrates the entire application startup
/// sequence.
///
/// This class acts as a "locked box" for the critical, complex, and fragile
/// logic of initializing the app. Its sole responsibility is to perform all
/// startup steps in a specific, linear order, eliminating race conditions and
/// centralizing error handling.
///
/// The process is as follows:
/// 1. Fetch `RemoteConfig`.
/// 2. Check for blocking states (maintenance, forced update).
/// 3. Fetch the initial `User`.
/// 4. If a user exists, fetch their `UserAppSettings` and
///    `UserContentPreferences` in parallel.
/// 5. Handle demo-specific data initialization.
/// 6. Return a single, immutable `InitializationResult` (either `Success` or
///    `Failure`) that contains all pre-loaded data.
///
/// This approach makes the startup process robust, testable, and easy to
/// maintain, as the logic is isolated from the rest of the application,
/// particularly the `AppBloc` and UI layers.
class AppInitializer {
  /// Creates an instance of the [AppInitializer].
  ///
  /// Requires all repositories and services needed for the startup sequence.
  AppInitializer({
    required AuthRepository authenticationRepository,
    required DataRepository<UserAppSettings> userAppSettingsRepository,
    required DataRepository<UserContentPreferences>
        userContentPreferencesRepository,
    required DataRepository<RemoteConfig> remoteConfigRepository,
    required DataRepository<User> userRepository,
    required local_config.AppEnvironment environment,
    required PackageInfoService packageInfoService,
    required Logger logger,
    this.demoDataMigrationService,
    this.demoDataInitializerService,
  })  : _authenticationRepository = authenticationRepository,
        _userAppSettingsRepository = userAppSettingsRepository,
        _userContentPreferencesRepository = userContentPreferencesRepository,
        _remoteConfigRepository = remoteConfigRepository,
        _userRepository = userRepository,
        _environment = environment,
        _packageInfoService = packageInfoService,
        _logger = logger;

  final AuthRepository _authenticationRepository;
  final DataRepository<UserAppSettings> _userAppSettingsRepository;
  final DataRepository<UserContentPreferences>
      _userContentPreferencesRepository;
  final DataRepository<RemoteConfig> _remoteConfigRepository;
  final DataRepository<User> _userRepository;
  final local_config.AppEnvironment _environment;
  final PackageInfoService _packageInfoService;
  final Logger _logger;
  final DemoDataMigrationService? demoDataMigrationService;
  final DemoDataInitializerService? demoDataInitializerService;

  /// Runs the entire startup sequence in a controlled, sequential manner.
  ///
  /// This is the single entry point for application initialization. It ensures
  /// all necessary data is fetched and validated before the main app UI is
  /// ever displayed, preventing race conditions and inconsistent states.
  ///
  /// Returns a [InitializationResult] which is either [InitializationSuccess]
  /// with all the required data, or [InitializationFailure] with a specific
  //  /// failure status.
  Future<InitializationResult> initializeApp() async {
    // This method will be implemented in the next phase.
    throw UnimplementedError();
  }

  /// Handles the complex logic of transitioning a user from one state to
  /// another, for example, from an anonymous user to a fully authenticated one.
  ///
  /// This includes triggering data migration and re-fetching all user-specific
  /// data to reflect the new authenticated state.
  ///
  /// [oldUser]: The user state before the change.
  /// [newUser]: The user state after the change.
  ///
  /// Returns a [InitializationResult] which can be used by the `AppBloc` to
  /// update its state.
  Future<InitializationResult> handleUserTransition({
    required User? oldUser,
    required User newUser,
    required RemoteConfig remoteConfig,
  }) async {
    // This method will be implemented in a later phase.
    throw UnimplementedError();
  }
}

/// Extension on [AppLifeCycleStatus] to provide a convenient way to check
/// for "running" states.
extension AppStatusX on AppLifeCycleStatus {
  /// Returns `true` if the app is in a state where the main UI should be
  /// interactive.
  bool get isRunning =>
      this == AppLifeCycleStatus.authenticated ||
      this == AppLifeCycleStatus.anonymous ||
      this == AppLifeCycleStatus.unauthenticated;
}

/// Extension on [User] to provide a convenient way to check
/// for "running" states.
extension AppUserX on User {
  /// Returns `true` if the user is a guest user.
  bool get isGuest => appRole == AppUserRole.guestUser;
}

/// Extension on [UserFeedDecoratorStatus] to encapsulate the logic for
/// determining if a decorator can be shown.
extension UserFeedDecoratorStatusX on UserFeedDecoratorStatus {
  /// Determines if a decorator can be shown based on its completion status
  /// and the configured cooldown period.
  ///
  /// [daysBetweenViews]: The minimum number of days that must pass before the
  /// decorator can be shown again.
  ///
  /// Returns `true` if the decorator has never been shown, or if it has been
  /// shown but the cooldown period has elapsed. Returns `false` if the
  /// decorator action has been marked as completed or if it is still within
  /// its cooldown period.
  bool canBeShown({required int daysBetweenViews}) {
    if (isCompleted) {
      return false;
    }
    if (lastShownAt == null) {
      return true;
    }
    return DateTime.now().difference(lastShownAt!).inDays >= daysBetweenViews;
  }
}

/// Extension on [HttpException] to provide a user-friendly message.
extension HttpExceptionX on HttpException {
  /// Returns a user-friendly message for the given [HttpException].
  String toFriendlyMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      final ConflictException e => e.message,
      final InternalServerErrorException e => e.message,
      final InvalidInputException e => e.message,
      final NotFoundException e => e.message,
      final UnauthorizedException e => e.message,
      final UnknownException e => e.message,
      _ => l10n.unknownError,
    };
  }
}