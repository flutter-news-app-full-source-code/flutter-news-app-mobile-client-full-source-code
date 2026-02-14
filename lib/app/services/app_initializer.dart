import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/initialization_result.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/package_info_service.dart';
import 'package:kv_storage_service/kv_storage_service.dart';
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
/// 5. Return a single, immutable `InitializationResult` (either `Success` or
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
    required DataRepository<UserRewards> userRewardsRepository,
    required DataRepository<RemoteConfig> remoteConfigRepository,
    required KVStorageService storageService,
    required PackageInfoService packageInfoService,
    required Logger logger,
  }) : _authenticationRepository = authenticationRepository,
       _appSettingsRepository = appSettingsRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _userContextRepository = userContextRepository,
       _userRewardsRepository = userRewardsRepository,
       _remoteConfigRepository = remoteConfigRepository,
       _storageService = storageService,
       _packageInfoService = packageInfoService,
       _logger = logger;

  final AuthRepository _authenticationRepository;
  final DataRepository<AppSettings> _appSettingsRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final DataRepository<UserContext> _userContextRepository;
  final DataRepository<UserRewards> _userRewardsRepository;
  final DataRepository<RemoteConfig> _remoteConfigRepository;
  final KVStorageService _storageService;
  final PackageInfoService _packageInfoService;
  final Logger _logger;

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
    User? user;
    try {
      user = await _authenticationRepository.getCurrentUser();
    } on UnauthorizedException {
      _logger.info(
        '[AppInitializer] No active session found (401). Proceeding as unauthenticated.',
      );
      user = null;
    }

    // --- Path A: Unauthenticated User ---
    // If there's no user, the initialization is complete. Return success
    // with an unauthenticated status.

    if (user == null) {
      // Check for Pre-Auth Tour
      final tourConfig = remoteConfig.features.onboarding.appTour;
      if (tourConfig.isEnabled) {
        final hasSeenTour = await _storageService.readBool(
          key: StorageKey.hasSeenAppTour.stringValue,
        );
        if (!hasSeenTour) {
          _logger.info('[AppInitializer] Pre-authentication tour required.');
          return InitializationOnboardingRequired(
            status: OnboardingStatus.preAuthTour,
            remoteConfig: remoteConfig,
          );
        }
      }
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
      final results = await Future.wait<dynamic>([
        _readAppSettings(user),
        _readUserContentPreferences(user),
        _readUserContext(user),
        _fetchUserRewards(user),
      ]);
      
      final appSettings = results[0] as AppSettings?;
      final userContentPreferences = results[1] as UserContentPreferences?;
      final userContext = results[2] as UserContext?;
      final userRewards = results[3] as UserRewards?;

      // Check for Post-Auth Personalization
      final personalizationConfig =
          remoteConfig.features.onboarding.initialPersonalization;
      if (personalizationConfig.isEnabled &&
          userContext != null &&
          !userContext.hasCompletedInitialPersonalization) {
        _logger.info(
          '[AppInitializer] Post-authentication personalization required.',
        );
        return InitializationOnboardingRequired(
          status: OnboardingStatus.postAuthPersonalization,
          remoteConfig: remoteConfig,
          user: user,
          userContext: userContext,
          settings: appSettings,
          userContentPreferences: userContentPreferences,
        );
      }

      _logger
        ..fine(
          '[AppInitializer] Parallel fetch complete. '
          'Settings: ${appSettings != null}, '
          'Preferences: ${userContentPreferences != null}, '
          'Context: ${userContext != null}',
        )
        ..fine(
          '[AppInitializer] --- App Initialization Complete (Authenticated) ---',
        );
      return InitializationSuccess(
        remoteConfig: remoteConfig,
        user: user,
        settings: appSettings,
        userContentPreferences: userContentPreferences,
        userContext: userContext,
        userRewards: userRewards,
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
  /// Returns a [InitializationResult] which can be used by the `AppBloc` to
  /// update its state.
  Future<InitializationResult> handleUserTransition({
    required User? oldUser,
    required User newUser,
    required RemoteConfig remoteConfig,
  }) async {
    _logger
      ..fine(
        '[AppInitializer] Handling user transition for user ${newUser.id}.',
      )
      // --- Re-fetch User Data ---
      // Always re-fetch data after a transition to ensure the state is fresh.
      ..fine(
        '[AppInitializer] Re-fetching user data for transitioned user ${newUser.id}...',
      );

    try {
      final results = await Future.wait<dynamic>([
        _readAppSettings(newUser),
        _readUserContentPreferences(newUser),
        _readUserContext(newUser),
        _fetchUserRewards(newUser),
      ]);
      final appSettings = results[0] as AppSettings?;
      final userContentPreferences = results[1] as UserContentPreferences?;
      final userContext = results[2] as UserContext?;
      final userRewards = results[3] as UserRewards?;
      _logger.fine('[AppInitializer] User transition data fetch complete.');

      // Check for Post-Auth Personalization during transition.
      final personalizationConfig =
          remoteConfig.features.onboarding.initialPersonalization;
      if (personalizationConfig.isEnabled &&
          userContext != null &&
          !userContext.hasCompletedInitialPersonalization) {
        _logger.info(
          '[AppInitializer] Post-authentication personalization required '
          'after user transition.',
        );
        return InitializationOnboardingRequired(
          status: OnboardingStatus.postAuthPersonalization,
          remoteConfig: remoteConfig,
          user: newUser,
          userContext: userContext,
          settings: appSettings,
          userContentPreferences: userContentPreferences,
        );
      }

      return InitializationSuccess(
        remoteConfig: remoteConfig,
        user: newUser,
        settings: appSettings,
        userContentPreferences: userContentPreferences,
        userContext: userContext,
        userRewards: userRewards,
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

  /// Helper to fetch app settings safely, returning null if not found.
  Future<AppSettings?> _readAppSettings(User user) async {
    try {
      return await _appSettingsRepository.read(id: user.id, userId: user.id);
    } on NotFoundException {
      _logger.info('No AppSettings found for user ${user.id}.');
      return null;
    } on HttpException catch (e, s) {
      _logger.severe('Failed to fetch AppSettings for user ${user.id}.', e, s);
      rethrow;
    }
  }

  /// Helper to fetch user content preferences safely, returning null if not
  /// found.
  Future<UserContentPreferences?> _readUserContentPreferences(User user) async {
    try {
      return await _userContentPreferencesRepository.read(
        id: user.id,
        userId: user.id,
      );
    } on NotFoundException {
      _logger.info('No UserContentPreferences found for user ${user.id}.');
      return null;
    } on HttpException catch (e, s) {
      _logger.severe(
        'Failed to fetch UserContentPreferences for user ${user.id}.',
        e,
        s,
      );
      rethrow;
    }
  }

  /// Helper to fetch user context safely, returning null if not found.
  Future<UserContext?> _readUserContext(User user) async {
    try {
      return await _userContextRepository.read(id: user.id, userId: user.id);
    } on NotFoundException {
      _logger.info('No UserContext found for user ${user.id}.');
      return null;
    } on HttpException catch (e, s) {
      _logger.severe('Failed to fetch UserContext for user ${user.id}.', e, s);
      rethrow;
    }
  }

  /// Helper to fetch user rewards safely.
  /// Returns null if not found.
  Future<UserRewards?> _fetchUserRewards(User user) async {
    if (user.isAnonymous) return null;

    try {
      final userRewards = await _userRewardsRepository.read(
        userId: user.id,
        id: user.id,
      );
      return userRewards;
    } catch (e, s) {
      // If fetch fails or no rewards found, return null.
      // We don't want to block app init for this.
      _logger.warning('Failed to fetch user rewards on init', e, s);
      return null;
    }
  }
}
