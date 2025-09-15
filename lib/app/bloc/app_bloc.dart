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
/// remote configurations.
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
  }) : _authenticationRepository = authenticationRepository,
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
           // settings is now nullable and will be fetched.
           settings: null,
           selectedBottomNavigationIndex: 0,
           remoteConfig: initialRemoteConfig, // Use the pre-fetched config
           initialRemoteConfigError:
               initialRemoteConfigError, // Store any initial config error
           environment: environment,
           user: initialUser, // Set initial user if available
           // Default theme settings until user settings are loaded
           themeMode: _mapAppBaseTheme(AppBaseTheme.system),
           flexScheme: _mapAppAccentTheme(AppAccentTheme.defaultBlue),
           fontFamily: _mapFontFamily('SystemDefault'),
           appTextScaleFactor: AppTextScaleFactor.medium,
           locale: const Locale('en'), // Default to English
         ),
       ) {
    // Register event handlers for various app-level events.
    on<AppStarted>(_onAppStarted); // New event handler
    on<AppUserChanged>(_onAppUserChanged);
    on<AppSettingsRefreshed>(_onAppSettingsRefreshed);
    on<AppConfigFetchRequested>(_onAppConfigFetchRequested);
    on<AppUserFeedDecoratorShown>(_onAppUserFeedDecoratorShown);
    on<AppLogoutRequested>(_onLogoutRequested);
    on<AppThemeModeChanged>(_onThemeModeChanged);
    on<AppFlexSchemeChanged>(_onFlexSchemeChanged);
    on<AppFontFamilyChanged>(_onFontFamilyChanged);
    on<AppTextScaleFactorChanged>(_onAppTextScaleFactorChanged);
    on<AppFontWeightChanged>(_onAppFontWeightChanged);
    on<AppUserDataLoaded>(_onAppUserDataLoaded); // New event handler

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

  /// Handles the [AppStarted] event, orchestrating the initial loading of
  /// user-specific data and evaluating the overall app status.
  Future<void> _onAppStarted(AppStarted event, Emitter<AppState> emit) async {
    _logger.info('[AppBloc] AppStarted event received. Starting data load.');

    // If there was a critical error during bootstrap (e.g., RemoteConfig fetch failed),
    // we should immediately transition to criticalError state.
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
    _logger.info(
      '[AppBloc] Initial user found: ${currentUser.id} (${currentUser.appRole}). '
      'Fetching user settings and preferences.',
    );

    try {
      // Fetch UserAppSettings
      final userAppSettings = await _userAppSettingsRepository.read(
        id: currentUser.id,
        userId: currentUser.id,
      );
      _logger.info(
        '[AppBloc] UserAppSettings fetched successfully for user: ${currentUser.id}',
      );

      // Fetch UserContentPreferences
      final userContentPreferences = await _userContentPreferencesRepository
          .read(id: currentUser.id, userId: currentUser.id);
      _logger.info(
        '[AppBloc] UserContentPreferences fetched successfully for user: ${currentUser.id}',
      );

      // Map loaded settings to the AppState.
      final newThemeMode = _mapAppBaseTheme(
        userAppSettings.displaySettings.baseTheme,
      );
      final newFlexScheme = _mapAppAccentTheme(
        userAppSettings.displaySettings.accentTheme,
      );
      final newFontFamily = _mapFontFamily(
        userAppSettings.displaySettings.fontFamily,
      );
      final newAppTextScaleFactor = _mapTextScaleFactor(
        userAppSettings.displaySettings.textScaleFactor,
      );
      final newLocale = Locale(userAppSettings.language.code);

      final finalStatus = currentUser.appRole == AppUserRole.standardUser
          ? AppLifeCycleStatus.authenticated
          : AppLifeCycleStatus.anonymous;

      emit(
        state.copyWith(
          status: finalStatus,
          user: currentUser,
          settings: userAppSettings,
          userContentPreferences:
              userContentPreferences, // Store userContentPreferences
          themeMode: newThemeMode,
          flexScheme: newFlexScheme,
          fontFamily: newFontFamily,
          appTextScaleFactor: newAppTextScaleFactor,
          locale: newLocale,
          initialUserPreferencesError: null,
        ),
      );
      // Dispatch event to signal that user settings are loaded
      add(const AppUserDataLoaded());
    } on HttpException catch (e) {
      _logger.severe(
        '[AppBloc] Failed to fetch user settings or preferences (HttpException) for user '
        '${currentUser.id}: ${e.runtimeType} - ${e.message}',
      );
      emit(
        state.copyWith(
          status: AppLifeCycleStatus.criticalError,
          initialUserPreferencesError: e,
        ),
      );
    } catch (e, s) {
      _logger.severe(
        '[AppBloc] Unexpected error during user settings/preferences fetch for user '
        '${currentUser.id}.',
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

    try {
      final userAppSettings = await _userAppSettingsRepository.read(
        id: state.user!.id,
        userId: state.user!.id,
      );

      // Also fetch UserContentPreferences when settings are refreshed
      final userContentPreferences = await _userContentPreferencesRepository
          .read(id: state.user!.id, userId: state.user!.id);

      final newThemeMode = _mapAppBaseTheme(
        userAppSettings.displaySettings.baseTheme,
      );
      final newFlexScheme = _mapAppAccentTheme(
        userAppSettings.displaySettings.accentTheme,
      );
      final newFontFamily = _mapFontFamily(
        userAppSettings.displaySettings.fontFamily,
      );
      final newAppTextScaleFactor = _mapTextScaleFactor(
        userAppSettings.displaySettings.textScaleFactor,
      );
      final newLocale = Locale(userAppSettings.language.code);

      _logger
        ..info(
          '_onAppSettingsRefreshed: userAppSettings.fontFamily: ${userAppSettings.displaySettings.fontFamily}',
        )
        ..info(
          '_onAppSettingsRefreshed: newFontFamily mapped to: $newFontFamily',
        );

      emit(
        state.copyWith(
          themeMode: newThemeMode,
          flexScheme: newFlexScheme,
          appTextScaleFactor: newAppTextScaleFactor,
          fontFamily: newFontFamily,
          settings: userAppSettings,
          userContentPreferences:
              userContentPreferences, // Store userContentPreferences
          locale: newLocale,
          initialUserPreferencesError: null,
        ),
      );
      // Dispatch event to signal that user settings are loaded
      add(const AppUserDataLoaded());
    } on HttpException catch (e) {
      _logger.severe(
        'Error loading user app settings or preferences in AppBloc (HttpException): $e',
      );
      emit(
        state.copyWith(
          status: AppLifeCycleStatus.criticalError,
          initialUserPreferencesError: e, // Use the new error field
        ),
      );
    } catch (e, s) {
      _logger.severe(
        'Error loading user app settings or preferences in AppBloc.',
        e,
        s,
      );
      emit(
        state.copyWith(
          status: AppLifeCycleStatus.criticalError,
          initialUserPreferencesError: UnknownException(
            e.toString(),
          ), // Use the new error field
        ),
      );
    }
  }

  /// Handles user logout request.
  void _onLogoutRequested(AppLogoutRequested event, Emitter<AppState> emit) {
    unawaited(_authenticationRepository.signOut());
  }

  /// Handles changes to the application's base theme mode (light, dark, system).
  Future<void> _onThemeModeChanged(
    AppThemeModeChanged event,
    Emitter<AppState> emit,
  ) async {
    // Ensure settings are loaded before attempting to update.
    if (state.settings == null) {
      _logger.warning(
        '[AppBloc] Skipping theme mode change: UserAppSettings not loaded.',
      );
      return;
    }

    final updatedSettings = state.settings!.copyWith(
      displaySettings: state.settings!.displaySettings.copyWith(
        baseTheme: event.themeMode == ThemeMode.light
            ? AppBaseTheme.light
            : (event.themeMode == ThemeMode.dark
                  ? AppBaseTheme.dark
                  : AppBaseTheme.system),
      ),
    );
    emit(state.copyWith(settings: updatedSettings, themeMode: event.themeMode));
    try {
      await _userAppSettingsRepository.update(
        id: updatedSettings.id,
        item: updatedSettings,
        userId: updatedSettings.id,
      );
      _logger.info('[AppBloc] UserAppSettings updated for theme mode change.');
    } catch (e, s) {
      _logger.severe(
        'Failed to persist theme mode change for user ${updatedSettings.id}.',
        e,
        s,
      );
    }
  }

  /// Handles changes to the application's accent color scheme.
  Future<void> _onFlexSchemeChanged(
    AppFlexSchemeChanged event,
    Emitter<AppState> emit,
  ) async {
    // Ensure settings are loaded before attempting to update.
    if (state.settings == null) {
      _logger.warning(
        '[AppBloc] Skipping accent scheme change: UserAppSettings not loaded.',
      );
      return;
    }

    final updatedSettings = state.settings!.copyWith(
      displaySettings: state.settings!.displaySettings.copyWith(
        accentTheme: event.flexScheme == FlexScheme.blue
            ? AppAccentTheme.defaultBlue
            : (event.flexScheme == FlexScheme.red
                  ? AppAccentTheme.newsRed
                  : AppAccentTheme.graphiteGray),
      ),
    );
    emit(
      state.copyWith(settings: updatedSettings, flexScheme: event.flexScheme),
    );
    try {
      await _userAppSettingsRepository.update(
        id: updatedSettings.id,
        item: updatedSettings,
        userId: updatedSettings.id,
      );
      _logger.info(
        '[AppBloc] UserAppSettings updated for accent scheme change.',
      );
    } catch (e, s) {
      _logger.severe(
        'Failed to persist accent scheme change for user ${updatedSettings.id}.',
        e,
        s,
      );
    }
  }

  /// Handles changes to the application's font family.
  Future<void> _onFontFamilyChanged(
    AppFontFamilyChanged event,
    Emitter<AppState> emit,
  ) async {
    // Ensure settings are loaded before attempting to update.
    if (state.settings == null) {
      _logger.warning(
        '[AppBloc] Skipping font family change: UserAppSettings not loaded.',
      );
      return;
    }

    final updatedSettings = state.settings!.copyWith(
      displaySettings: state.settings!.displaySettings.copyWith(
        fontFamily: event.fontFamily ?? 'SystemDefault',
      ),
    );
    emit(
      state.copyWith(settings: updatedSettings, fontFamily: event.fontFamily),
    );
    try {
      await _userAppSettingsRepository.update(
        id: updatedSettings.id,
        item: updatedSettings,
        userId: updatedSettings.id,
      );
      _logger.info('[AppBloc] UserAppSettings updated for font family change.');
    } catch (e, s) {
      _logger.severe(
        'Failed to persist font family change for user ${updatedSettings.id}.',
        e,
        s,
      );
    }
  }

  /// Handles changes to the application's text scale factor.
  Future<void> _onAppTextScaleFactorChanged(
    AppTextScaleFactorChanged event,
    Emitter<AppState> emit,
  ) async {
    // Ensure settings are loaded before attempting to update.
    if (state.settings == null) {
      _logger.warning(
        '[AppBloc] Skipping text scale factor change: UserAppSettings not loaded.',
      );
      return;
    }

    final updatedSettings = state.settings!.copyWith(
      displaySettings: state.settings!.displaySettings.copyWith(
        textScaleFactor: event.appTextScaleFactor,
      ),
    );
    emit(
      state.copyWith(
        settings: updatedSettings,
        appTextScaleFactor: event.appTextScaleFactor,
      ),
    );
    try {
      await _userAppSettingsRepository.update(
        id: updatedSettings.id,
        item: updatedSettings,
        userId: updatedSettings.id,
      );
      _logger.info(
        '[AppBloc] UserAppSettings updated for text scale factor change.',
      );
    } catch (e, s) {
      _logger.severe(
        'Failed to persist text scale factor change for user ${updatedSettings.id}.',
        e,
        s,
      );
    }
  }

  /// Handles changes to the application's font weight.
  Future<void> _onAppFontWeightChanged(
    AppFontWeightChanged event,
    Emitter<AppState> emit,
  ) async {
    // Ensure settings are loaded before attempting to update.
    if (state.settings == null) {
      _logger.warning(
        '[AppBloc] Skipping font weight change: UserAppSettings not loaded.',
      );
      return;
    }

    final updatedSettings = state.settings!.copyWith(
      displaySettings: state.settings!.displaySettings.copyWith(
        fontWeight: event.fontWeight,
      ),
    );
    emit(state.copyWith(settings: updatedSettings));
    try {
      await _userAppSettingsRepository.update(
        id: updatedSettings.id,
        item: updatedSettings,
        userId: updatedSettings.id,
      );
      _logger.info('[AppBloc] UserAppSettings updated for font weight change.');
    } catch (e, s) {
      _logger.severe(
        'Failed to persist font weight change for user ${updatedSettings.id}.',
        e,
        s,
      );
    }
  }

  /// Maps [AppBaseTheme] enum to Flutter's [ThemeMode].
  static ThemeMode _mapAppBaseTheme(AppBaseTheme mode) {
    switch (mode) {
      case AppBaseTheme.light:
        return ThemeMode.light;
      case AppBaseTheme.dark:
        return ThemeMode.dark;
      case AppBaseTheme.system:
        return ThemeMode.system;
    }
  }

  /// Maps [AppAccentTheme] enum to FlexColorScheme's [FlexScheme].
  static FlexScheme _mapAppAccentTheme(AppAccentTheme name) {
    switch (name) {
      case AppAccentTheme.defaultBlue:
        return FlexScheme.blue;
      case AppAccentTheme.newsRed:
        return FlexScheme.red;
      case AppAccentTheme.graphiteGray:
        return FlexScheme.material;
    }
  }

  /// Maps a font family string to a nullable string for theme data.
  static String? _mapFontFamily(String fontFamilyString) {
    if (fontFamilyString == 'SystemDefault') {
      return null;
    }
    return fontFamilyString;
  }

  /// Maps [AppTextScaleFactor] to itself (no transformation needed).
  static AppTextScaleFactor _mapTextScaleFactor(AppTextScaleFactor factor) {
    return factor;
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }

  /// Handles fetching the remote application configuration.
  ///
  /// This method is primarily used for re-fetching the remote configuration
  /// (e.g., by [AppStatusService] for background checks or by [StatusPage]
  /// for retries). The initial remote configuration is fetched during bootstrap.
  Future<void> _onAppConfigFetchRequested(
    AppConfigFetchRequested event,
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

  /// Handles the [AppUserDataLoaded] event.
  /// This event is dispatched when user-specific settings (UserAppSettings and
  /// UserContentPreferences) have been successfully loaded and updated in the
  /// AppBloc state. This handler currently does nothing, but it serves as a
  /// placeholder for future logic that might need to react to this event.
  Future<void> _onAppUserDataLoaded(
    AppUserDataLoaded event,
    Emitter<AppState> emit,
  ) async {
    _logger.info('[AppBloc] AppUserSettingsLoaded event received.');
    // This event is primarily for other BLoCs to listen to.
    // AppBloc itself doesn't need to do anything further here.
  }
}
