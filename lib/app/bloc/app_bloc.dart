import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/config.dart'
    as local_config;
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_initializer_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_migration_service.dart';
import 'package:logging/logging.dart';

part 'app_event.dart';
part 'app_state.dart';

/// {@template app_bloc}
/// Manages the overall application state, including authentication status,
/// user settings, and remote configuration.
///
/// This BLoC is central to the application's lifecycle, reacting to user
/// authentication changes, managing user preferences, and applying global
/// remote configurations. It acts as the single source of truth for global
/// application state.
/// {@endtemplate}
class AppBloc extends Bloc<AppEvent, AppState> {
  /// {@macro app_bloc}
  ///
  /// Initializes the BLoC with required repositories, environment, and
  /// pre-fetched initial data.
  AppBloc({
    required AuthRepository authenticationRepository,
    required DataRepository<UserAppSettings> userAppSettingsRepository,
    required DataRepository<UserContentPreferences>
        userContentPreferencesRepository,
    required DataRepository<RemoteConfig> appConfigRepository,
    required DataRepository<User> userRepository,
    required local_config.AppEnvironment environment,
    required GlobalKey<NavigatorState> navigatorKey,
    required RemoteConfig? initialRemoteConfig,
    required HttpException? initialRemoteConfigError,
    this.demoDataMigrationService,
    this.demoDataInitializerService,
    this.initialUser,
  })  : _authenticationRepository = authenticationRepository,
        _userAppSettingsRepository = userAppSettingsRepository,
        _userContentPreferencesRepository = userContentPreferencesRepository,
        _appConfigRepository = appConfigRepository,
        _userRepository = userRepository,
        _environment = environment,
        _navigatorKey = navigatorKey,
        _logger = Logger('AppBloc'),
        super(
          // Initial state of the app. The status is set to loadingUserData
          // as the AppBloc will now handle fetching user-specific data.
          // UserAppSettings and UserContentPreferences are initially null
          // and will be fetched asynchronously.
          AppState(
            status: AppLifeCycleStatus.loadingUserData,
            selectedBottomNavigationIndex: 0,
            remoteConfig: initialRemoteConfig, // Use the pre-fetched config
            initialRemoteConfigError:
                initialRemoteConfigError, // Store any initial config error
            environment: environment,
            user: initialUser, // Set initial user if available
          ),
        ) {
    // Register event handlers for various app-level events.
    on<AppStarted>(_onAppStarted);
    on<AppUserChanged>(_onAppUserChanged);
    on<AppSettingsRefreshed>(_onAppSettingsRefreshed);
    on<AppSettingsChanged>(_onAppSettingsChanged);
    on<AppPeriodicConfigFetchRequested>(_onAppPeriodicConfigFetchRequested);
    on<AppUserFeedDecoratorShown>(_onAppUserFeedDecoratorShown);
    on<AppLogoutRequested>(_onLogoutRequested);

    // Subscribe to the authentication repository's authStateChanges stream.
    // This stream is the single source of truth for the user's auth state
    // and drives the entire app lifecycle.
    _userSubscription = _authenticationRepository.authStateChanges.listen(
      (User? user) => add(AppUserChanged(user)),
    );
  }

  final AuthRepository _authenticationRepository;
  final DataRepository<UserAppSettings> _userAppSettingsRepository;
  final DataRepository<UserContentPreferences>
      _userContentPreferencesRepository;
  final DataRepository<RemoteConfig> _appConfigRepository;
  final DataRepository<User> _userRepository;
  final local_config.AppEnvironment _environment;
  final GlobalKey<NavigatorState> _navigatorKey;
  final Logger _logger;
  final DemoDataMigrationService? demoDataMigrationService;
  final DemoDataInitializerService? demoDataInitializerService;
  final User? initialUser;
  late final StreamSubscription<User?> _userSubscription;

  /// Provides access to the [NavigatorState] for obtaining a [BuildContext].
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// Fetches [UserAppSettings] and [UserContentPreferences] for the given
  /// [user] and updates the [AppState].
  ///
  /// This method centralizes the logic for loading user-specific data,
  /// ensuring consistency across different app lifecycle events.
  /// It also handles potential [HttpException]s during the fetch operation.
  Future<void> _fetchAndSetUserData(User user, Emitter<AppState> emit) async {
    _logger.info(
      '[AppBloc] Fetching user settings and preferences for user: ${user.id}',
    );
    try {
      final userAppSettings = await _userAppSettingsRepository.read(
        id: user.id,
        userId: user.id,
      );
      _logger.info(
        '[AppBloc] UserAppSettings fetched successfully for user: ${user.id}',
      );

      final userContentPreferences = await _userContentPreferencesRepository
          .read(id: user.id, userId: user.id);
      _logger.info(
        '[AppBloc] UserContentPreferences fetched successfully for user: ${user.id}',
      );

      final finalStatus = user.appRole == AppUserRole.standardUser
          ? AppLifeCycleStatus.authenticated
          : AppLifeCycleStatus.anonymous;

      emit(
        state.copyWith(
          status: finalStatus,
          user: user,
          settings: userAppSettings,
          userContentPreferences: userContentPreferences,
          initialUserPreferencesError: null,
        ),
      );
    } on HttpException catch (e) {
      _logger.severe(
        '[AppBloc] Failed to fetch user settings or preferences (HttpException) '
        'for user ${user.id}: ${e.runtimeType} - ${e.message}',
      );
      emit(
        state.copyWith(
          status: AppLifeCycleStatus.criticalError,
          initialUserPreferencesError: e,
        ),
      );
    } catch (e, s) {
      _logger.severe(
        '[AppBloc] Unexpected error during user settings/preferences fetch '
        'for user ${user.id}.',
        e,
        s,
      );
      emit(
        state.copyWith(
          status: AppLifeCycleStatus.criticalError,
          initialUserPreferencesError: UnknownException(e.toString()),
        ),
      );
    }
  }

  /// Handles the [AppStarted] event, orchestrating the initial loading of
  /// user-specific data and evaluating the overall app status.
  Future<void> _onAppStarted(AppStarted event, Emitter<AppState> emit) async {
    _logger.info('[AppBloc] AppStarted event received. Starting data load.');

    // If there was a critical error during bootstrap (e.g., RemoteConfig fetch failed),
    // immediately transition to criticalError state.
    if (state.initialRemoteConfigError != null) {
      _logger.severe(
        '[AppBloc] Initial RemoteConfig fetch failed during bootstrap. '
        'Transitioning to critical error.',
      );
      emit(state.copyWith(status: AppLifeCycleStatus.criticalError));
      return;
    }

    // If RemoteConfig is null at this point, it's an unexpected error.
    if (state.remoteConfig == null) {
      _logger.severe(
        '[AppBloc] RemoteConfig is null after bootstrap, but no error was reported. '
        'Transitioning to critical error.',
      );
      emit(
        state.copyWith(
          status: AppLifeCycleStatus.criticalError,
          initialRemoteConfigError: const UnknownException(
            'RemoteConfig is null after bootstrap.',
          ),
        ),
      );
      return;
    }

    // Evaluate global app status from RemoteConfig first.
    if (state.remoteConfig!.appStatus.isUnderMaintenance) {
      _logger.info(
        '[AppBloc] App is under maintenance. Transitioning to maintenance state.',
      );
      emit(state.copyWith(status: AppLifeCycleStatus.underMaintenance));
      return;
    }

    if (state.remoteConfig!.appStatus.isLatestVersionOnly) {
      // TODO(fulleni): Compare with actual app version.
      _logger.info(
        '[AppBloc] App update required. Transitioning to updateRequired state.',
      );
      emit(state.copyWith(status: AppLifeCycleStatus.updateRequired));
      return;
    }

    // If we reach here, the app is not under maintenance or requires update.
    // Proceed to load user-specific data.
    emit(state.copyWith(status: AppLifeCycleStatus.loadingUserData));

    final currentUser = event.initialUser;

    if (currentUser == null) {
      _logger.info(
        '[AppBloc] No initial user. Transitioning to unauthenticated state.',
      );
      emit(state.copyWith(status: AppLifeCycleStatus.unauthenticated));
      return;
    }

    // User is present, proceed to fetch user-specific settings and preferences.
    await _fetchAndSetUserData(currentUser, emit);
  }

  /// Handles all logic related to user authentication state changes.
  ///
  /// This method is now simplified to only update the user and status based
  /// on the authentication stream, and handle data migration.
  Future<void> _onAppUserChanged(
    AppUserChanged event,
    Emitter<AppState> emit,
  ) async {
    final oldUser = state.user;
    final newUser = event.user;

    // Optimization: Prevent redundant reloads if the user ID hasn't changed.
    if (oldUser?.id == newUser?.id) {
      _logger.info(
        '[AppBloc] AppUserChanged triggered, but user ID is the same. '
        'Skipping reload.',
      );
      return;
    }

    // Update the user in the state.
    emit(state.copyWith(user: newUser));

    // Determine the new status based on the user.
    final newStatus = newUser == null
        ? AppLifeCycleStatus.unauthenticated
        : (newUser.appRole == AppUserRole.standardUser
            ? AppLifeCycleStatus.authenticated
            : AppLifeCycleStatus.anonymous);

    emit(state.copyWith(status: newStatus));

    // If a new user is present, fetch their specific data.
    if (newUser != null) {
      await _fetchAndSetUserData(newUser, emit);
    } else {
      // If user logs out, clear user-specific data from state.
      emit(
        state.copyWith(
          settings: null,
          userContentPreferences: null,
        ),
      );
    }

    // In demo mode, ensure user-specific data is initialized.
    if (_environment == local_config.AppEnvironment.demo &&
        demoDataInitializerService != null &&
        newUser != null) {
      try {
        _logger.info('Demo mode: Initializing data for user ${newUser.id}.');
        await demoDataInitializerService!.initializeUserSpecificData(newUser);
        _logger.info(
          'Demo mode: Data initialization complete for ${newUser.id}.',
        );
      } catch (e, s) {
        _logger.severe('ERROR: Failed to initialize demo user data.', e, s);
      }
    }

    // Handle data migration if an anonymous user signs in.
    if (oldUser != null &&
        oldUser.appRole == AppUserRole.guestUser &&
        newUser != null &&
        newUser.appRole == AppUserRole.standardUser) {
      _logger.info(
        'Anonymous user ${oldUser.id} transitioned to authenticated user '
        '${newUser.id}. Attempting data migration.',
      );
      if (demoDataMigrationService != null &&
          _environment == local_config.AppEnvironment.demo) {
        await demoDataMigrationService!.migrateAnonymousData(
          oldUserId: oldUser.id,
          newUserId: newUser.id,
        );
        _logger.info('Demo mode: Data migration completed for ${newUser.id}.');
      }
    }
  }

  /// Handles refreshing/loading app settings (theme, font).
  Future<void> _onAppSettingsRefreshed(
    AppSettingsRefreshed event,
    Emitter<AppState> emit,
  ) async {
    if (state.user == null) {
      _logger.info('[AppBloc] Skipping AppSettingsRefreshed: User is null.');
      return;
    }

    await _fetchAndSetUserData(state.user!, emit);
  }

  /// Handles the [AppSettingsChanged] event, updating and persisting the
  /// user's application settings.
  ///
  /// This event is dispatched when any part of the user's settings (theme,
  /// font, language, etc.) is modified. The entire [UserAppSettings] object
  /// is updated and then persisted to the backend.
  Future<void> _onAppSettingsChanged(
    AppSettingsChanged event,
    Emitter<AppState> emit,
  ) async {
    // Ensure settings are loaded and a user is available before attempting to update.
    if (state.user == null || state.settings == null) {
      _logger.warning(
        '[AppBloc] Skipping AppSettingsChanged: User or UserAppSettings not loaded.',
      );
      return;
    }

    final updatedSettings = event.settings;

    emit(state.copyWith(settings: updatedSettings));

    try {
      await _userAppSettingsRepository.update(
        id: updatedSettings.id,
        item: updatedSettings,
        userId: updatedSettings.id,
      );
      _logger.info(
        '[AppBloc] UserAppSettings successfully updated and persisted for user ${updatedSettings.id}.',
      );
    } on HttpException catch (e) {
      _logger.severe(
        'Failed to persist UserAppSettings for user ${updatedSettings.id} (HttpException): $e',
      );
      // Revert to original settings on failure to maintain state consistency
      emit(state.copyWith(settings: state.settings));
    } catch (e, s) {
      _logger.severe(
        'Unexpected error persisting UserAppSettings for user ${updatedSettings.id}.',
        e,
        s,
      );
      // Revert to original settings on failure to maintain state consistency
      emit(state.copyWith(settings: state.settings));
    }
  }

  /// Handles user logout request.
  void _onLogoutRequested(AppLogoutRequested event, Emitter<AppState> emit) {
    unawaited(_authenticationRepository.signOut());
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }

  /// Handles periodic fetching of the remote application configuration.
  ///
  /// This method is primarily used for re-fetching the remote configuration
  /// (e.g., by [AppStatusService] for background checks or by [StatusPage]
  /// for retries). The initial remote configuration is fetched during bootstrap.
  Future<void> _onAppPeriodicConfigFetchRequested(
    AppPeriodicConfigFetchRequested event,
    Emitter<AppState> emit,
  ) async {
    if (state.user == null) {
      _logger.info('[AppBloc] User is null. Skipping AppConfig fetch.');
      emit(
        state.copyWith(
          remoteConfig: null,
          clearAppConfig: true,
          status: AppLifeCycleStatus.unauthenticated,
          initialRemoteConfigError: null,
        ),
      );
      return;
    }

    // Only show critical error if it's not a background check.
    if (!event.isBackgroundCheck) {
      _logger.info(
        '[AppBloc] Initial config fetch. Setting status to loadingUserData if failed.',
      );
      emit(state.copyWith(status: AppLifeCycleStatus.loadingUserData));
    } else {
      _logger.info('[AppBloc] Background config fetch. Proceeding silently.');
    }

    try {
      final remoteConfig = await _appConfigRepository.read(id: kRemoteConfigId);
      _logger.info(
        '[AppBloc] Remote Config fetched successfully for user: ${state.user!.id}',
      );

      if (remoteConfig.appStatus.isUnderMaintenance) {
        emit(
          state.copyWith(
            status: AppLifeCycleStatus.underMaintenance,
            remoteConfig: remoteConfig,
            initialRemoteConfigError: null,
          ),
        );
        return;
      }

      if (remoteConfig.appStatus.isLatestVersionOnly) {
        // TODO(fulleni): Compare with actual app version.
        emit(
          state.copyWith(
            status: AppLifeCycleStatus.updateRequired,
            remoteConfig: remoteConfig,
            initialRemoteConfigError: null,
          ),
        );
        return;
      }

      final finalStatus = state.user!.appRole == AppUserRole.standardUser
          ? AppLifeCycleStatus.authenticated
          : AppLifeCycleStatus.anonymous;
      emit(
        state.copyWith(
          remoteConfig: remoteConfig,
          status: finalStatus,
          initialRemoteConfigError: null,
        ),
      );
    } on HttpException catch (e) {
      _logger.severe(
        '[AppBloc] Failed to fetch AppConfig (HttpException) for user ${state.user?.id}: ${e.runtimeType} - ${e.message}',
      );
      if (!event.isBackgroundCheck) {
        emit(
          state.copyWith(
            status: AppLifeCycleStatus.criticalError,
            initialRemoteConfigError: e,
          ),
        );
      }
    } catch (e, s) {
      _logger.severe(
        '[AppBloc] Unexpected error fetching AppConfig for user ${state.user?.id}.',
        e,
        s,
      );
      if (!event.isBackgroundCheck) {
        emit(
          state.copyWith(
            status: AppLifeCycleStatus.criticalError,
            initialRemoteConfigError: UnknownException(e.toString()),
          ),
        );
      }
    }
  }

  /// Handles updating the user's feed decorator status.
  Future<void> _onAppUserFeedDecoratorShown(
    AppUserFeedDecoratorShown event,
    Emitter<AppState> emit,
  ) async {
    if (state.user != null && state.user!.id == event.userId) {
      final originalUser = state.user!;
      final now = DateTime.now();
      final currentStatus =
          originalUser.feedDecoratorStatus[event.feedDecoratorType] ??
          const UserFeedDecoratorStatus(isCompleted: false);

      final updatedDecoratorStatus = currentStatus.copyWith(
        lastShownAt: now,
        isCompleted: event.isCompleted || currentStatus.isCompleted,
      );

      final newFeedDecoratorStatus =
          Map<FeedDecoratorType, UserFeedDecoratorStatus>.from(
            originalUser.feedDecoratorStatus,
          )..update(
            event.feedDecoratorType,
            (_) => updatedDecoratorStatus,
            ifAbsent: () => updatedDecoratorStatus,
          );

      final updatedUser = originalUser.copyWith(
        feedDecoratorStatus: newFeedDecoratorStatus,
      );

      emit(state.copyWith(user: updatedUser));

      try {
        await _userRepository.update(
          id: updatedUser.id,
          item: updatedUser,
          userId: updatedUser.id,
        );
        _logger.info(
          '[AppBloc] User ${event.userId} FeedDecorator ${event.feedDecoratorType} '
          'status successfully updated on the backend.',
        );
      } catch (e) {
        _logger.severe('Failed to update feed decorator status on backend: $e');
        emit(state.copyWith(user: originalUser));
      }
    }
  }
}
