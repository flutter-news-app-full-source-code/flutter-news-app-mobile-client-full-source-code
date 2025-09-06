import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/config.dart'
    as local_config;
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_initializer_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_migration_service.dart';
import 'package:logging/logging.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({
    required AuthRepository authenticationRepository,
    required DataRepository<UserAppSettings> userAppSettingsRepository,
    required DataRepository<RemoteConfig> appConfigRepository,
    required DataRepository<User> userRepository,
    required local_config.AppEnvironment environment,
    required AdService adService,
    this.demoDataMigrationService,
    this.demoDataInitializerService,
    this.initialUser,
  }) : _authenticationRepository = authenticationRepository,
       _userAppSettingsRepository = userAppSettingsRepository,
       _appConfigRepository = appConfigRepository,
       _userRepository = userRepository,
       _environment = environment,
       _adService = adService,
       _logger = Logger('AppBloc'),
       super(
         AppState(
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
           remoteConfig: null,
           environment: environment,
           status: initialUser != null
               ? (initialUser.appRole == AppUserRole.standardUser
                     ? AppStatus.authenticated
                     : AppStatus.anonymous)
               : AppStatus.unauthenticated,
           user: initialUser,
         ),
       ) {
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

    _userSubscription = _authenticationRepository.authStateChanges.listen(
      (User? user) => add(AppUserChanged(user)),
    );
  }

  final AuthRepository _authenticationRepository;
  final DataRepository<UserAppSettings> _userAppSettingsRepository;
  final DataRepository<RemoteConfig> _appConfigRepository;
  final DataRepository<User> _userRepository;
  final local_config.AppEnvironment _environment;
  final AdService _adService;
  final Logger _logger;
  final DemoDataMigrationService? demoDataMigrationService;
  final DemoDataInitializerService? demoDataInitializerService;
  final User? initialUser;
  late final StreamSubscription<User?> _userSubscription;

  /// Handles user changes and loads initial settings once user is available.
  Future<void> _onAppUserChanged(
    AppUserChanged event,
    Emitter<AppState> emit,
  ) async {
    // Determine the AppStatus based on the user object and its role
    final AppStatus status;
    final oldUser = state.user;

    switch (event.user?.appRole) {
      case null:
        status = AppStatus.unauthenticated;
      case AppUserRole.standardUser:
        status = AppStatus.authenticated;
      case AppUserRole.guestUser: // Explicitly map guestUser to anonymous
        status = AppStatus.anonymous;
      // ignore: no_default_cases
      default: // Fallback for any other roles not explicitly handled
        status = AppStatus.anonymous;
    }

    // Emit user and status update first
    emit(state.copyWith(status: status, user: event.user));

    if (event.user != null) {
      // User is present (authenticated or anonymous)
      // In demo mode, ensure user-specific data is initialized
      if (_environment == local_config.AppEnvironment.demo &&
          demoDataInitializerService != null) {
        try {
          _logger.info(
            'Demo mode: Initializing user-specific data for '
            'user ${event.user!.id}.',
          );
          await demoDataInitializerService!.initializeUserSpecificData(
            event.user!,
          );
          _logger.info(
            'Demo mode: User-specific data initialization completed '
            'for user ${event.user!.id}.',
          );
        } catch (e, s) {
          // It's important to handle failures here to avoid crashing the app.
          // Consider emitting a specific failure state if this is critical.
          _logger.severe('ERROR: Failed to initialize demo user data: $e\n$s');
        }
      }

      add(const AppSettingsRefreshed());
      add(const AppConfigFetchRequested());

      // Check for anonymous to authenticated transition for data migration
      if (oldUser != null &&
          oldUser.appRole == AppUserRole.guestUser &&
          event.user!.appRole == AppUserRole.standardUser) {
        _logger.info(
          'Anonymous user ${oldUser.id} transitioned to '
          'authenticated user ${event.user!.id}. Attempting data migration.',
        );
        // This block handles data migration specifically for the demo environment.
        // In production/development, this logic is typically handled by the backend.
        if (demoDataMigrationService != null &&
            _environment == local_config.AppEnvironment.demo) {
          _logger.info(
            'Demo mode: Awaiting data migration from anonymous '
            'user ${oldUser.id} to authenticated user ${event.user!.id}.',
          );
          // Await the migration to ensure it completes before refreshing settings.
          await demoDataMigrationService!.migrateAnonymousData(
            oldUserId: oldUser.id,
            newUserId: event.user!.id,
          );
          // After successful migration, explicitly refresh app settings
          // to load the newly migrated data into the AppBloc's state.
          add(const AppSettingsRefreshed());
          _logger.info(
            'Demo mode: Data migration completed and settings '
            'refresh triggered for user ${event.user!.id}.',
          );
        } else {
          _logger.info(
            'DemoDataMigrationService not available or not in demo '
            'environment. Skipping client-side data migration.',
          );
        }
      }
    } else {
      // User is null (unauthenticated or logged out)
      emit(
        state.copyWith(
          remoteConfig: null,
          clearAppConfig: true,
          status: AppStatus.unauthenticated,
        ),
      );
    }
  }

  /// Handles refreshing/loading app settings (theme, font).
  Future<void> _onAppSettingsRefreshed(
    AppSettingsRefreshed event,
    Emitter<AppState> emit,
  ) async {
    // Avoid loading if user is unauthenticated (shouldn't happen if logic is correct)
    if (state.status == AppStatus.unauthenticated || state.user == null) {
      return;
    }

    try {
      // Fetch relevant settings using the new generic repository
      // Use the current user's ID to fetch user-specific settings
      final userAppSettings = await _userAppSettingsRepository.read(
        id: state.user!.id,
        userId: state.user!.id,
      );

      // Map settings from UserAppSettings to AppState properties
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
      // Map language code to Locale
      final newLocale = Locale(userAppSettings.language.code);

      _logger.info(
        '_onAppSettingsRefreshed: userAppSettings.fontFamily: ${userAppSettings.displaySettings.fontFamily}',
      );
      _logger.info(
        '_onAppSettingsRefreshed: userAppSettings.fontWeight: ${userAppSettings.displaySettings.fontWeight}',
      );
      _logger.info(
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
    } catch (e) {
      // Handle other potential errors during settings fetch
      // Optionally emit a failure state or log the error
      _logger.severe('Error loading user app settings in AppBloc: $e');
      // Keep the existing theme/font state on error, but ensure settings is not null
      emit(state.copyWith(settings: state.settings));
    }
  }

  // Add handlers for settings changes (dispatching events from UI)
  void _onLogoutRequested(AppLogoutRequested event, Emitter<AppState> emit) {
    unawaited(_authenticationRepository.signOut());
  }

  void _onThemeModeChanged(AppThemeModeChanged event, Emitter<AppState> emit) {
    // Update settings and emit new state
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
    // Optionally save settings to repository here
    // unawaited(_userAppSettingsRepository.update(id: updatedSettings.id, item: updatedSettings));
  }

  void _onFlexSchemeChanged(
    AppFlexSchemeChanged event,
    Emitter<AppState> emit,
  ) {
    // Update settings and emit new state
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
    // Optionally save settings to repository here
    // unawaited(_userAppSettingsRepository.update(id: updatedSettings.id, item: updatedSettings));
  }

  void _onFontFamilyChanged(
    AppFontFamilyChanged event,
    Emitter<AppState> emit,
  ) {
    // Update settings and emit new state
    final updatedSettings = state.settings.copyWith(
      displaySettings: state.settings.displaySettings.copyWith(
        fontFamily: event.fontFamily ?? 'SystemDefault',
      ),
    );
    emit(
      state.copyWith(settings: updatedSettings, fontFamily: event.fontFamily),
    );
    // Optionally save settings to repository here
    // unawaited(_userAppSettingsRepository.update(id: updatedSettings.id, item: updatedSettings));
  }

  void _onAppTextScaleFactorChanged(
    AppTextScaleFactorChanged event,
    Emitter<AppState> emit,
  ) {
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
    // Optionally save settings to repository here
    // unawaited(_userAppSettingsRepository.update(id: updatedSettings.id, item: updatedSettings));
  }

  void _onAppFontWeightChanged(
    AppFontWeightChanged event,
    Emitter<AppState> emit,
  ) {
    final updatedSettings = state.settings.copyWith(
      displaySettings: state.settings.displaySettings.copyWith(
        fontWeight: event.fontWeight,
      ),
    );
    emit(state.copyWith(settings: updatedSettings));
  }

  ThemeMode _mapAppBaseTheme(AppBaseTheme mode) {
    switch (mode) {
      case AppBaseTheme.light:
        return ThemeMode.light;
      case AppBaseTheme.dark:
        return ThemeMode.dark;
      case AppBaseTheme.system:
        return ThemeMode.system;
    }
  }

  FlexScheme _mapAppAccentTheme(AppAccentTheme name) {
    switch (name) {
      case AppAccentTheme.defaultBlue:
        return FlexScheme.blue;
      case AppAccentTheme.newsRed:
        return FlexScheme.red;
      case AppAccentTheme.graphiteGray:
        return FlexScheme.material;
    }
  }

  String? _mapFontFamily(String fontFamilyString) {
    // If the input is 'SystemDefault', return null so FlexColorScheme uses its default.
    if (fontFamilyString == 'SystemDefault') {
      _logger.info('_mapFontFamily: Input is SystemDefault, returning null.');
      return null;
    }
    // Otherwise, return the font family string directly.
    // The GoogleFonts.xyz().fontFamily getters often return strings like "Roboto-Regular",
    // but FlexColorScheme's fontFamily parameter or GoogleFonts.xyzTextTheme() expect simple names.
    _logger.info(
      '_mapFontFamily: Input is $fontFamilyString, returning as is.',
    );
    return fontFamilyString;
  }

  // Map AppTextScaleFactor to AppTextScaleFactor (no change needed)
  AppTextScaleFactor _mapTextScaleFactor(AppTextScaleFactor factor) {
    return factor;
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }

  Future<void> _onAppConfigFetchRequested(
    AppConfigFetchRequested event,
    Emitter<AppState> emit,
  ) async {
    // Guard: Only fetch if a user (authenticated or anonymous) is present.
    if (state.user == null) {
      _logger.info(
        '[AppBloc] User is null. Skipping AppConfig fetch because it requires authentication.',
      );
      // If AppConfig was somehow present without a user, clear it.
      // And ensure status isn't stuck on configFetching if this event was dispatched erroneously.
      if (state.remoteConfig != null ||
          state.status == AppStatus.configFetching) {
        emit(
          state.copyWith(
            remoteConfig: null,
            clearAppConfig: true,
            status: AppStatus.unauthenticated,
          ),
        );
      }
      return;
    }

    // For background checks, we don't want to show a loading screen.
    // Only for the initial fetch should we set the status to configFetching.
    if (!event.isBackgroundCheck) {
      _logger.info(
        '[AppBloc] Initial config fetch. Setting status to configFetching.',
      );
      emit(state.copyWith(status: AppStatus.configFetching));
    } else {
      _logger.info('[AppBloc] Background config fetch. Proceeding silently.');
    }

    try {
      final remoteConfig = await _appConfigRepository.read(id: kRemoteConfigId);
      _logger.info(
        '[AppBloc] Remote Config fetched successfully. ID: ${remoteConfig.id} for user: ${state.user!.id}',
      );

      // --- CRITICAL STATUS EVALUATION ---
      // For both initial and background checks, if a critical status is found,
      // we must update the app status immediately to lock the UI.

      // 1. Check for Maintenance Mode. This has the highest priority.
      if (remoteConfig.appStatus.isUnderMaintenance) {
        emit(
          state.copyWith(
            status: AppStatus.underMaintenance,
            remoteConfig: remoteConfig,
          ),
        );
        return;
      }

      // 2. Check for a Required Update.
      // TODO(fulleni): Compare with actual app version from package_info_plus.
      if (remoteConfig.appStatus.isLatestVersionOnly) {
        emit(
          state.copyWith(
            status: AppStatus.updateRequired,
            remoteConfig: remoteConfig,
          ),
        );
        return;
      }

      // --- POST-CHECK STATE RESOLUTION ---
      // If no critical status was found, we resolve the final state.
      // This logic applies to both initial fetches (transitioning from
      // configFetching) and background checks (transitioning from a state
      // like underMaintenance back to a running state).
      final finalStatus = state.user!.appRole == AppUserRole.standardUser
          ? AppStatus.authenticated
          : AppStatus.anonymous;
      emit(state.copyWith(remoteConfig: remoteConfig, status: finalStatus));
    } on HttpException catch (e) {
      _logger.severe(
        '[AppBloc] Failed to fetch AppConfig (HttpException) for user ${state.user?.id}: ${e.runtimeType} - ${e.message}',
      );
      // Only show a failure screen on an initial fetch.
      // For background checks, we fail silently to avoid disruption.
      if (!event.isBackgroundCheck) {
        emit(state.copyWith(status: AppStatus.configFetchFailed));
      } else {
        _logger.info('[AppBloc] Silent failure on background config fetch.');
      }
    } catch (e, s) {
      _logger.severe(
        '[AppBloc] Unexpected error fetching AppConfig for user ${state.user?.id}: $e',
        e,
        s,
      );
      if (!event.isBackgroundCheck) {
        emit(state.copyWith(status: AppStatus.configFetchFailed));
      } else {
        _logger.info('[AppBloc] Silent failure on background config fetch.');
      }
    }
  }

  Future<void> _onAppUserFeedDecoratorShown(
    AppUserFeedDecoratorShown event,
    Emitter<AppState> emit,
  ) async {
    if (state.user != null && state.user!.id == event.userId) {
      final originalUser = state.user!;
      final now = DateTime.now();
      // Get the current status for the decorator, or create a default if not present.
      final currentStatus =
          originalUser.feedDecoratorStatus[event.feedDecoratorType] ??
          const UserFeedDecoratorStatus(isCompleted: false);

      // Create an updated status.
      // It always updates the `lastShownAt` timestamp.
      // It updates `isCompleted` to true if the event marks it as completed.
      // Once completed, it should stay completed.
      final updatedDecoratorStatus = currentStatus.copyWith(
        lastShownAt: now,
        isCompleted: event.isCompleted || currentStatus.isCompleted,
      );

      // Create a new map with the updated status for the specific decorator type.
      final newFeedDecoratorStatus =
          Map<FeedDecoratorType, UserFeedDecoratorStatus>.from(
            originalUser.feedDecoratorStatus,
          )..update(
            event.feedDecoratorType,
            (_) => updatedDecoratorStatus,
            ifAbsent: () => updatedDecoratorStatus,
          );

      // Update the user with the new feedDecoratorStatus map.
      final updatedUser = originalUser.copyWith(
        feedDecoratorStatus: newFeedDecoratorStatus,
      );

      // Emit the change so UI can react if needed, and other BLoCs get the update.
      emit(state.copyWith(user: updatedUser));

      // Persist this change to the backend.
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
        // Revert the state on failure to maintain consistency.
        emit(state.copyWith(user: originalUser));
      }
    }
  }
}
