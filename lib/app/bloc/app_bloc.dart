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
    required DataRepository<RemoteConfig> appConfigRepository,
    required DataRepository<User> userRepository,
    required local_config.AppEnvironment environment,
    required GlobalKey<NavigatorState> navigatorKey,
    required RemoteConfig initialRemoteConfig,
    this.demoDataMigrationService,
    this.demoDataInitializerService,
    this.initialUser,
  }) : _authenticationRepository = authenticationRepository,
       _userAppSettingsRepository = userAppSettingsRepository,
       _appConfigRepository = appConfigRepository,
       _userRepository = userRepository,
       _environment = environment,
       _navigatorKey = navigatorKey,
       _logger = Logger('AppBloc'),
       super(
         // The initial state of the app. The status is set based on the
         // initialRemoteConfig and whether an initial user is provided.
         // This ensures critical app status (maintenance, update) is checked
         // immediately upon app launch, before any user-specific data is loaded.
         AppState(
           status: initialRemoteConfig.appStatus.isUnderMaintenance
               ? AppLifeCycleStatus.underMaintenance
               : initialRemoteConfig.appStatus.isLatestVersionOnly
               ? AppLifeCycleStatus.updateRequired
               : initialUser == null
               ? AppLifeCycleStatus.unauthenticated
               : AppLifeCycleStatus
                     .authenticated, // Assuming authenticated if user exists and no other critical status
           settings: UserAppSettings(
             id: 'default',
             displaySettings: const DisplaySettings(
               baseTheme: AppBaseTheme.system,
               accentTheme: AppAccentTheme.defaultBlue,
               fontFamily: 'SystemDefault',
               textScaleFactor: AppTextScaleFactor.medium,
               fontWeight: AppFontWeight.regular,
             ),
             language: languagesFixturesData.firstWhere(
               (l) => l.code == 'en',
               orElse: () => throw StateError(
                 'Default language "en" not found in language fixtures.',
               ),
             ),
             feedPreferences: const FeedDisplayPreferences(
               headlineDensity: HeadlineDensity.standard,
               headlineImageStyle: HeadlineImageStyle.largeThumbnail,
               showSourceInHeadlineFeed: true,
               showPublishDateInHeadlineFeed: true,
             ),
           ),
           selectedBottomNavigationIndex: 0,
           remoteConfig: initialRemoteConfig, // Use the pre-fetched config
           environment: environment,
           user: initialUser, // Set initial user if available
           themeMode: _mapAppBaseTheme(
             initialUser?.appRole == AppUserRole.guestUser
                 ? AppBaseTheme.system
                 : AppBaseTheme.system, // Default to system theme
           ),
           flexScheme: _mapAppAccentTheme(AppAccentTheme.defaultBlue),
           fontFamily: _mapFontFamily('SystemDefault'),
           appTextScaleFactor: AppTextScaleFactor.medium,
           locale: Locale(
             initialUser?.appRole == AppUserRole.guestUser ? 'en' : 'en',
           ), // Default to English
         ),
       ) {
    // Register event handlers for various app-level events.
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

    // Subscribe to the authentication repository's authStateChanges stream.
    // This stream is the single source of truth for the user's auth state
    // and drives the entire app lifecycle.
    _userSubscription = _authenticationRepository.authStateChanges.listen(
      (User? user) => add(AppUserChanged(user)),
    );
  }

  final AuthRepository _authenticationRepository;
  final DataRepository<UserAppSettings> _userAppSettingsRepository;
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

  /// Handles all logic related to user authentication state changes.
  ///
  /// This method is the consolidated entry point for the app's startup
  /// and data loading sequence, triggered exclusively by the auth stream.
  ///
  ///   1. It will first check if the user's ID has actually changed to prevent
  ///      redundant reloads from simple token refreshes.
  ///   2. If the user is `null`, it will emit an `unauthenticated` state.
  ///   3. If a user is present, it will immediately emit a `configFetching`
  ///      state to display the loading UI.
  ///   4. It will then proceed to fetch the `userAppSettings` (RemoteConfig is
  ///      already available from initial bootstrap).
  ///   5. Upon successful fetch, it will evaluate the app's status (maintenance,
  ///      update required) using the *already available* `remoteConfig` and
  ///      emit the final stable state (`authenticated`, `anonymous`, etc.)
  ///      with the correct, freshly-loaded data.
  ///   6. If any fetch fails, it will emit a `configFetchFailed` state,
  ///      allowing the user to retry.
  Future<void> _onAppUserChanged(
    AppUserChanged event,
    Emitter<AppState> emit,
  ) async {
    final oldUser = state.user;

    // Optimization: Prevent redundant reloads if the user ID hasn't changed.
    // This can happen with token refreshes that re-emit the same user.
    if (oldUser?.id == event.user?.id) {
      _logger.info(
        '[AppBloc] AppUserChanged triggered, but user ID is the same. '
        'Skipping reload.',
      );
      return;
    }

    // --- Handle Unauthenticated State (User is null) ---
    if (event.user == null) {
      _logger.info(
        '[AppBloc] User is null. Transitioning to unauthenticated state.',
      );
      emit(
        state.copyWith(
          status: AppLifeCycleStatus.unauthenticated,
          user: null,
          // RemoteConfig is now managed by initial bootstrap and AppConfigFetchRequested.
          // It should not be cleared here.
        ),
      );
      return;
    }

    // --- Handle Authenticated/Anonymous State (User is present) ---
    final newUser = event.user!;
    _logger.info(
      '[AppBloc] User changed to ${newUser.id} (${newUser.appRole}). '
      'Beginning data fetch sequence.',
    );

    // Immediately emit the new user and set status to configFetching.
    // This ensures the UI shows a loading state while we fetch user-specific data.
    emit(
      state.copyWith(user: newUser, status: AppLifeCycleStatus.configFetching),
    );

    // In demo mode, ensure user-specific data is initialized.
    if (_environment == local_config.AppEnvironment.demo &&
        demoDataInitializerService != null) {
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

    // --- Fetch Core Application Data ---
    try {
      // Only fetch user settings. RemoteConfig is already available from bootstrap
      // and is stored in the current state.
      final userAppSettings = await _userAppSettingsRepository.read(
        id: newUser.id,
        userId: newUser.id,
      );

      _logger.info(
        '[AppBloc] UserAppSettings fetched successfully for user: ${newUser.id}',
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

      // --- CRITICAL STATUS EVALUATION (using already available remoteConfig) ---
      // The remoteConfig is already in the state from the initial bootstrap.
      // We use the existing state.remoteConfig to perform these checks.
      final remoteConfig = state.remoteConfig!;

      if (remoteConfig.appStatus.isUnderMaintenance) {
        emit(
          state.copyWith(
            status: AppLifeCycleStatus.underMaintenance,
            // remoteConfig: remoteConfig, // Already in state, no need to re-assign
            settings: userAppSettings,
            themeMode: newThemeMode,
            flexScheme: newFlexScheme,
            fontFamily: newFontFamily,
            appTextScaleFactor: newAppTextScaleFactor,
            locale: newLocale,
          ),
        );
        return;
      }

      if (remoteConfig.appStatus.isLatestVersionOnly) {
        // TODO(fulleni): Compare with actual app version.
        emit(
          state.copyWith(
            status: AppLifeCycleStatus.updateRequired,
            // remoteConfig: remoteConfig, // Already in state, no need to re-assign
            settings: userAppSettings,
            themeMode: newThemeMode,
            flexScheme: newFlexScheme,
            fontFamily: newFontFamily,
            appTextScaleFactor: newAppTextScaleFactor,
            locale: newLocale,
          ),
        );
        return;
      }

      // --- Final State Transition ---
      // If no critical status, transition to the final stable state.
      final finalStatus = newUser.appRole == AppUserRole.standardUser
          ? AppLifeCycleStatus.authenticated
          : AppLifeCycleStatus.anonymous;

      emit(
        state.copyWith(
          status: finalStatus,
          // remoteConfig: remoteConfig, // Already in state, no need to re-assign
          settings: userAppSettings,
          themeMode: newThemeMode,
          flexScheme: newFlexScheme,
          fontFamily: newFontFamily,
          appTextScaleFactor: newAppTextScaleFactor,
          locale: newLocale,
        ),
      );
    } on HttpException catch (e) {
      _logger.severe(
        '[AppBloc] Failed to fetch initial data (HttpException) for user '
        '${newUser.id}: ${e.runtimeType} - ${e.message}',
      );
      emit(state.copyWith(status: AppLifeCycleStatus.configFetchFailed));
    } catch (e, s) {
      _logger.severe(
        '[AppBloc] Unexpected error during initial data fetch for user '
        '${newUser.id}.',
        e,
        s,
      );
      emit(state.copyWith(status: AppLifeCycleStatus.configFetchFailed));
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
          locale: newLocale,
        ),
      );
    } on HttpException catch (e) {
      _logger.severe(
        'Error loading user app settings in AppBloc (HttpException): $e',
      );
      emit(state.copyWith(settings: state.settings));
    } catch (e, s) {
      _logger.severe('Error loading user app settings in AppBloc.', e, s);
      emit(state.copyWith(settings: state.settings));
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
    final updatedSettings = state.settings.copyWith(
      displaySettings: state.settings.displaySettings.copyWith(
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
    final updatedSettings = state.settings.copyWith(
      displaySettings: state.settings.displaySettings.copyWith(
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
    final updatedSettings = state.settings.copyWith(
      displaySettings: state.settings.displaySettings.copyWith(
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
    final updatedSettings = state.settings.copyWith(
      displaySettings: state.settings.displaySettings.copyWith(
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
    final updatedSettings = state.settings.copyWith(
      displaySettings: state.settings.displaySettings.copyWith(
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
      // If there's no user, and we're not already fetching, or if remoteConfig
      // is present, we might transition to unauthenticated.
      if (state.remoteConfig != null ||
          state.status == AppLifeCycleStatus.configFetching) {
        emit(
          state.copyWith(
            remoteConfig: null, // Clear remoteConfig if unauthenticated
            clearAppConfig: true,
            status: AppLifeCycleStatus.unauthenticated,
          ),
        );
      }
      return;
    }

    if (!event.isBackgroundCheck) {
      _logger.info(
        '[AppBloc] Initial config fetch. Setting status to configFetching.',
      );
      emit(state.copyWith(status: AppLifeCycleStatus.configFetching));
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
          ),
        );
        return;
      }

      final finalStatus = state.user!.appRole == AppUserRole.standardUser
          ? AppLifeCycleStatus.authenticated
          : AppLifeCycleStatus.anonymous;
      emit(state.copyWith(remoteConfig: remoteConfig, status: finalStatus));
    } on HttpException catch (e) {
      _logger.severe(
        '[AppBloc] Failed to fetch AppConfig (HttpException) for user ${state.user?.id}: ${e.runtimeType} - ${e.message}',
      );
      if (!event.isBackgroundCheck) {
        emit(state.copyWith(status: AppLifeCycleStatus.configFetchFailed));
      }
    } catch (e, s) {
      _logger.severe(
        '[AppBloc] Unexpected error fetching AppConfig for user ${state.user?.id}.',
        e,
        s,
      );
      if (!event.isBackgroundCheck) {
        emit(state.copyWith(status: AppLifeCycleStatus.configFetchFailed));
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
