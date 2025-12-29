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
/// 4. If a user exists, fetch their `AppSettings` and
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
    required DataRepository<AppSettings> appSettingsRepository,
    required DataRepository<UserContentPreferences>
    userContentPreferencesRepository,
    required DataRepository<UserContext> userContextRepository,
    required DataRepository<UserSubscription> userSubscriptionRepository,
    required DataRepository<RemoteConfig> remoteConfigRepository,
    required local_config.AppEnvironment environment,
    required PackageInfoService packageInfoService,
    required Logger logger,
    this.demoDataMigrationService,
    this.demoDataInitializerService,
  }) : _authenticationRepository = authenticationRepository,
       _appSettingsRepository = appSettingsRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _userContextRepository = userContextRepository,
       _userSubscriptionRepository = userSubscriptionRepository,
       _remoteConfigRepository = remoteConfigRepository,
       _environment = environment,
       _packageInfoService = packageInfoService,
       _logger = logger;

  final AuthRepository _authenticationRepository;
  final DataRepository<AppSettings> _appSettingsRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final DataRepository<UserContext> _userContextRepository;
  final DataRepository<UserSubscription> _userSubscriptionRepository;
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
    if (remoteConfig.app.maintenance.isUnderMaintenance) {
      _logger.warning('[AppInitializer] App is under maintenance. Halting.');
      return const InitializationFailure(
        status: AppLifeCycleStatus.underMaintenance,
      );
    }

    // --- Gate 3: Check for Forced Update ---
    // If a forced update is required, halt the startup process.
    if (remoteConfig.app.update.isLatestVersionOnly) {
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
            remoteConfig.app.update.latestAppVersion,
          );
          if (currentVersion < latestRequiredVersion) {
            _logger.warning(
              '[AppInitializer] App update required. Halting. '
              'Current: $currentVersion, Required: $latestRequiredVersion',
            );
            return InitializationFailure(
              status: AppLifeCycleStatus.updateRequired,
              currentAppVersion: currentVersionString,
              latestAppVersion: remoteConfig.app.update.latestAppVersion,
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
        appSettings as AppSettings?,
        userContentPreferences as UserContentPreferences?,
        userContext as UserContext?,
        userSubscription as UserSubscription?,
      ] = await Future.wait<dynamic>([
        _appSettingsRepository.read(id: user.id, userId: user.id),
        _userContentPreferencesRepository.read(id: user.id, userId: user.id),
        _userContextRepository.read(id: user.id, userId: user.id),
        _fetchUserSubscription(user.id),
      ]);

      _logger.fine(
        '[AppInitializer] Parallel fetch complete. '
        'Settings: ${appSettings != null}, '
        'Preferences: ${userContentPreferences != null}, '
        'Context: ${userContext != null}',
      );

      // --- Demo-Specific Logic: Initialize Data on First Run ---
      // If in demo mode and the user data is missing (e.g., first sign-in),
      // create it from fixtures.
      if (_environment == local_config.AppEnvironment.demo &&
          (appSettings == null ||
              userContentPreferences == null ||
              userContext == null)) {
        _logger.info(
          '[AppInitializer] Demo mode: User data missing. '
          'Initializing from fixtures for user ${user.id}.',
        );
        await demoDataInitializerService?.initializeUserSpecificData(user);

        // Re-fetch the data after initialization.
        _logger.fine('[AppInitializer] Re-fetching data after demo init...');
        [
          appSettings,
          userContentPreferences,
          userContext,
          userSubscription,
        ] = await Future.wait<dynamic>([
          _appSettingsRepository.read(id: user.id, userId: user.id),
          _userContentPreferencesRepository.read(id: user.id, userId: user.id),
          _userContextRepository.read(id: user.id, userId: user.id),
          _fetchUserSubscription(user.id),
        ]);
      }

      _logger.fine(
        '[AppInitializer] --- App Initialization Complete (Authenticated) ---',
      );
      return InitializationSuccess(
        remoteConfig: remoteConfig,
        user: user,
        settings: appSettings,
        userContentPreferences: userContentPreferences,
        userContext: userContext,
        userSubscription: userSubscription,
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
  /// another while the application is already running.
  ///
  /// This method is a critical piece of the "running app" lifecycle and is
  /// called by the `AppBloc` in response to an authentication change. Its
  /// primary responsibility is to ensure that the application state is correctly
  /// primary responsibility is to ensure that the application state is correctly
  /// and completely updated to reflect the new user's identity.
  ///
  /// This process involves two main steps:
  /// 1.  **Data Migration (if applicable):** It detects if the transition is
  ///     from an anonymous guest to a fully authenticated user. If so, it
  ///     triggers the `DemoDataMigrationService` to move any data (like saved
  ///     articles) from the old anonymous user ID to the new authenticated
  ///     user ID.
  /// 2.  **Re-fetching All User Data:** After any potential migration, it
  ///     re-fetches all user-specific data (`AppSettings`,
  ///     `UserContentPreferences`) for the `newUser`. This is crucial to
  ///     ensure the app's state is fresh and not polluted with data from the
  ///     previous user.
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
        oldUser != null && oldUser.isAnonymous && !newUser.isAnonymous;

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
            error: UnknownException('Failed to migrate demo user data: $e'),
          );
        }
      }
    }

    // --- Re-fetch User Data ---
    // Always re-fetch data after a transition to ensure the state is fresh.
    _logger.fine(
      '[AppInitializer] Re-fetching user data for transitioned user ${newUser.id}...',
    );

    // --- Demo-Specific Logic: Initialize Data on Transition ---
    // In demo mode, when a new user authenticates (e.g., anonymous sign-in
    // or email verification), their user-specific data (settings, preferences)
    // does not yet exist in the in-memory repositories. This block ensures
    // that the DemoDataInitializerService is called to create this data
    // *before* the subsequent code attempts to read it. This prevents a
    // NotFoundException that would otherwise cause a critical error and
    // stall the authentication flow.
    if (_environment == local_config.AppEnvironment.demo) {
      _logger.info(
        '[AppInitializer] Demo mode: Initializing data for new user '
        '${newUser.id} during transition.',
      );
      await demoDataInitializerService?.initializeUserSpecificData(newUser);
    }

    try {
      final [
        appSettings as AppSettings?,
        userContentPreferences as UserContentPreferences?,
        userContext as UserContext?,
        userSubscription as UserSubscription?,
      ] = await Future.wait<dynamic>([
        _appSettingsRepository.read(id: newUser.id, userId: newUser.id),
        _userContentPreferencesRepository.read(
          id: newUser.id,
          userId: newUser.id,
        ),
        _userContextRepository.read(id: newUser.id, userId: newUser.id),
        _fetchUserSubscription(newUser.id),
      ]);

      _logger.fine('[AppInitializer] User transition data fetch complete.');
      return InitializationSuccess(
        remoteConfig: remoteConfig,
        user: newUser,
        settings: appSettings,
        userContentPreferences: userContentPreferences,
        userContext: userContext,
        userSubscription: userSubscription,
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

  /// Helper to fetch user subscription safely.
  /// Returns null if not found (which is valid for non-subscribers).
  Future<UserSubscription?> _fetchUserSubscription(String userId) async {
    try {
      final response = await _userSubscriptionRepository.readAll(
        userId: userId,
        filter: {'status': 'active'},
        pagination: const PaginationOptions(limit: 1),
      );
      return response.items.firstOrNull;
    } catch (e, s) {
      // If fetch fails or no subscription found, return null.
      // We don't want to block app init for this.
      _logger.warning('Failed to fetch user subscription on init', e, s);
      return null;
    }
  }
}
