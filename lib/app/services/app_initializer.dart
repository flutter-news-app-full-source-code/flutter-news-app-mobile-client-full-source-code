import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/config.dart'
    as local_config;
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/initialization_result.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_initializer_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_migration_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/package_info_service.dart';
import 'package:logging/logging.dart';
import 'package:pub_semver/pub_semver.dart';

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
    required local_config.AppEnvironment environment,
    required PackageInfoService packageInfoService,
    required Logger logger,
    this.demoDataMigrationService,
    this.demoDataInitializerService,
  }) : _authenticationRepository = authenticationRepository,
       _userAppSettingsRepository = userAppSettingsRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _remoteConfigRepository = remoteConfigRepository,
       _environment = environment,
       _packageInfoService = packageInfoService,
       _logger = logger;

  final AuthRepository _authenticationRepository;
  final DataRepository<UserAppSettings> _userAppSettingsRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final DataRepository<RemoteConfig> _remoteConfigRepository;
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
    _logger
      ..fine('[AppInitializer] --- Starting App Initialization ---')
      // --- Gate 1: Fetch RemoteConfig ---
      // This is the first and most critical step. The RemoteConfig dictates
      // global app behavior like maintenance mode and forced updates.
      ..fine('[AppInitializer] 1. Fetching RemoteConfig...');
    late final RemoteConfig remoteConfig;
    try {
      remoteConfig = await _remoteConfigRepository.read(id: kRemoteConfigId);
      _logger.fine('[AppInitializer] RemoteConfig fetched successfully.');
    } on HttpException catch (e, s) {
      _logger.severe(
        '[AppInitializer] CRITICAL: Failed to fetch RemoteConfig.',
        e,
        s,
      );
      return InitializationFailure(
        status: AppLifeCycleStatus.criticalError,
        error: e,
      );
    }

    // --- Gate 2: Check for Maintenance Mode ---
    // If maintenance mode is enabled, halt the entire startup process.
    if (remoteConfig.appStatus.isUnderMaintenance) {
      _logger.warning('[AppInitializer] App is under maintenance. Halting.');
      return const InitializationFailure(status: AppLifeCycleStatus.underMaintenance);
    }

    // --- Gate 3: Check for Forced Update ---
    // If a forced update is required, halt the startup process.
    if (remoteConfig.appStatus.isLatestVersionOnly) {
      _logger.fine('[AppInitializer] Version check required.');
      final currentVersionString = await _packageInfoService.getAppVersion();
      if (currentVersionString == null) {
        _logger.warning(
          '[AppInitializer] Could not determine current app version. '
          'Skipping version check.',
        );
      } else {
        try {
          final currentVersion = Version.parse(currentVersionString);
          final latestRequiredVersion = Version.parse(
            remoteConfig.appStatus.latestAppVersion,
          );
          if (currentVersion < latestRequiredVersion) {
            _logger.warning(
              '[AppInitializer] App update required. Halting. '
              'Current: $currentVersion, Required: $latestRequiredVersion',
            );
            return InitializationFailure(
              status: AppLifeCycleStatus.updateRequired,
              currentAppVersion: currentVersionString,
              latestAppVersion: remoteConfig.appStatus.latestAppVersion,
            );
          }
          _logger.fine(
            '[AppInitializer] App version is up to date '
            '($currentVersion >= $latestRequiredVersion).',
          );
        } on FormatException catch (e, s) {
          _logger.severe(
            '[AppInitializer] CRITICAL: Failed to parse app version.',
            e,
            s,
          );
          return InitializationFailure(
            status: AppLifeCycleStatus.criticalError,
            error: UnknownException('Failed to parse app version: $e'),
          );
        }
      }
    }

    // --- Step 4: Fetch Initial User ---
    // Now that global gates are passed, determine the user's auth state.
    _logger.fine('[AppInitializer] 2. Fetching initial user...');
    final user = await _authenticationRepository.getCurrentUser();

    // --- Path A: Unauthenticated User ---
    // If there's no user, the initialization is complete. Return success
    // with an unauthenticated status.
    if (user == null) {
      _logger.fine(
        '[AppInitializer] No initial user found. '
        'Initialization complete (unauthenticated).',
      );
      return InitializationSuccess(remoteConfig: remoteConfig);
    }

    // --- Path B: Authenticated or Anonymous User ---
    // If a user exists, we must fetch their specific settings.
    _logger.fine(
      '[AppInitializer] User ${user.id} found. '
      '3. Fetching user settings and preferences in parallel...',
    );

    try {
      // Fetch settings and preferences concurrently for performance.
      var [
        userAppSettings as UserAppSettings?,
        userContentPreferences as UserContentPreferences?,
      ] = await Future.wait<dynamic>([
        _userAppSettingsRepository.read(id: user.id, userId: user.id),
        _userContentPreferencesRepository.read(id: user.id, userId: user.id),
      ]);

      _logger.fine(
        '[AppInitializer] Parallel fetch complete. '
        'Settings: ${userAppSettings != null}, '
        'Preferences: ${userContentPreferences != null}',
      );

      // --- Demo-Specific Logic: Initialize Data on First Run ---
      // If in demo mode and the user data is missing (e.g., first sign-in),
      // create it from fixtures.
      if (_environment == local_config.AppEnvironment.demo &&
          (userAppSettings == null || userContentPreferences == null)) {
        _logger.info(
          '[AppInitializer] Demo mode: User data missing. '
          'Initializing from fixtures for user ${user.id}.',
        );
        await demoDataInitializerService?.initializeUserSpecificData(user);

        // Re-fetch the data after initialization.
        _logger.fine('[AppInitializer] Re-fetching data after demo init...');
        [userAppSettings, userContentPreferences] = await Future.wait<dynamic>([
          _userAppSettingsRepository.read(id: user.id, userId: user.id),
          _userContentPreferencesRepository.read(id: user.id, userId: user.id),
        ]);
      }

      _logger.fine(
        '[AppInitializer] --- App Initialization Complete (Authenticated) ---',
      );
      return InitializationSuccess(
        remoteConfig: remoteConfig,
        user: user,
        settings: userAppSettings,
        userContentPreferences: userContentPreferences,
      );
    } on HttpException catch (e, s) {
      _logger.severe(
        '[AppInitializer] CRITICAL: Failed to fetch user data.',
        e,
        s,
      );
      return InitializationFailure(
        status: AppLifeCycleStatus.criticalError,
        error: e,
      );
    }
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
    _logger.fine(
      '[AppInitializer] Handling user transition for user ${newUser.id}.',
    );

    // --- Data Migration Logic ---
    final isMigration =
        oldUser != null &&
        oldUser.appRole == AppUserRole.guestUser &&
        newUser.appRole == AppUserRole.standardUser;

    if (isMigration) {
      _logger.info(
        '[AppInitializer] Anonymous user ${oldUser.id} transitioned to '
        'authenticated user ${newUser.id}. Attempting data migration.',
      );
      if (demoDataMigrationService != null &&
          _environment == local_config.AppEnvironment.demo) {
        try {
          await demoDataMigrationService!.migrateAnonymousData(
            oldUserId: oldUser.id,
            newUserId: newUser.id,
          );
          _logger.info(
            '[AppInitializer] Demo mode: Data migration completed for ${newUser.id}.',
          );
        } catch (e, s) {
          _logger.severe(
            '[AppInitializer] CRITICAL: Failed to migrate demo user data.',
            e,
            s,
          );
          return InitializationFailure(
            status: AppLifeCycleStatus.criticalError,
            error: UnknownException(
              'Failed to migrate demo user data: $e',
            ),
          );
        }
      }
    }

    // --- Re-fetch User Data ---
    // Always re-fetch data after a transition to ensure the state is fresh.
    _logger.fine(
      '[AppInitializer] Re-fetching user data for transitioned user ${newUser.id}...',
    );
    try {
      final [
        userAppSettings as UserAppSettings?,
        userContentPreferences as UserContentPreferences?,
      ] = await Future.wait<dynamic>([
        _userAppSettingsRepository.read(id: newUser.id, userId: newUser.id),
        _userContentPreferencesRepository.read(
          id: newUser.id,
          userId: newUser.id,
        ),
      ]);

      _logger.fine('[AppInitializer] User transition data fetch complete.');
      return InitializationSuccess(
        remoteConfig: remoteConfig,
        user: newUser,
        settings: userAppSettings,
        userContentPreferences: userContentPreferences,
      );
    } on HttpException catch (e, s) {
      _logger.severe(
        '[AppInitializer] CRITICAL: Failed to fetch data for transitioned user.',
        e,
        s,
      );
      return InitializationFailure(
        status: AppLifeCycleStatus.criticalError,
        error: e,
      );
    }
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
