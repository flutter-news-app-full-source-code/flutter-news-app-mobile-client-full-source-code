import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:ht_auth_repository/ht_auth_repository.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_main/app/config/config.dart' as local_config;
import 'package:ht_main/shared/services/demo_data_migration_service.dart';
import 'package:ht_shared/ht_shared.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({
    required HtAuthRepository authenticationRepository,
    required HtDataRepository<UserAppSettings> userAppSettingsRepository,
    required HtDataRepository<AppConfig> appConfigRepository,
    required local_config.AppEnvironment environment,
    this.demoDataMigrationService,
  }) : _authenticationRepository = authenticationRepository,
       _userAppSettingsRepository = userAppSettingsRepository,
       _appConfigRepository = appConfigRepository,
       _environment = environment,
       super(
         AppState(
           settings: const UserAppSettings(id: 'default'),
           selectedBottomNavigationIndex: 0,
           appConfig: null,
           environment: environment,
         ),
       ) {
    on<AppUserChanged>(_onAppUserChanged);
    on<AppSettingsRefreshed>(_onAppSettingsRefreshed);
    on<AppConfigFetchRequested>(_onAppConfigFetchRequested);
    on<AppUserAccountActionShown>(_onAppUserAccountActionShown);
    on<AppLogoutRequested>(_onLogoutRequested);
    on<AppThemeModeChanged>(_onThemeModeChanged);
    on<AppFlexSchemeChanged>(_onFlexSchemeChanged);
    on<AppFontFamilyChanged>(_onFontFamilyChanged);
    on<AppTextScaleFactorChanged>(_onAppTextScaleFactorChanged);

    // Listen directly to the auth state changes stream
    _userSubscription = _authenticationRepository.authStateChanges.listen(
      (User? user) => add(AppUserChanged(user)),
    );
  }

  final HtAuthRepository _authenticationRepository;
  final HtDataRepository<UserAppSettings> _userAppSettingsRepository;
  final HtDataRepository<AppConfig> _appConfigRepository;
  final local_config.AppEnvironment _environment;
  final DemoDataMigrationService? demoDataMigrationService;
  late final StreamSubscription<User?> _userSubscription;

  /// Handles user changes and loads initial settings once user is available.
  Future<void> _onAppUserChanged(
    AppUserChanged event,
    Emitter<AppState> emit,
  ) async {
    // Determine the AppStatus based on the user object and its role
    final AppStatus status;
    final oldUser = state.user;

    switch (event.user?.role) {
      case null:
        status = AppStatus.unauthenticated;
      case UserRole.standardUser:
        status = AppStatus.authenticated;
      case UserRole.guestUser: // Explicitly map guestUser to anonymous
        status = AppStatus.anonymous;
      // ignore: no_default_cases
      default: // Fallback for any other roles not explicitly handled
        status = AppStatus.anonymous;
    }

    // Emit user and status update first
    emit(state.copyWith(status: status, user: event.user));

    if (event.user != null) {
      // User is present (authenticated or anonymous)
      add(const AppSettingsRefreshed());
      add(const AppConfigFetchRequested());

      // Check for anonymous to authenticated transition for data migration
      if (oldUser != null &&
          oldUser.role == UserRole.guestUser &&
          event.user!.role == UserRole.standardUser) {
        print(
          '[AppBloc] Anonymous user ${oldUser.id} transitioned to '
          'authenticated user ${event.user!.id}. Attempting data migration.',
        );
        // This block handles data migration specifically for the demo environment.
        // In production/development, this logic is typically handled by the backend.
        if (demoDataMigrationService != null &&
            _environment == local_config.AppEnvironment.demo) {
          print(
            '[AppBloc] Demo mode: Awaiting data migration from anonymous '
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
          print(
            '[AppBloc] Demo mode: Data migration completed and settings '
            'refresh triggered for user ${event.user!.id}.',
          );
        } else {
          print(
            '[AppBloc] DemoDataMigrationService not available or not in demo '
            'environment. Skipping client-side data migration.',
          );
        }
      }
    } else {
      // User is null (unauthenticated or logged out)
      emit(
        state.copyWith(
          appConfig: null,
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
      final newLocale = Locale(userAppSettings.language);

      print(
        '[AppBloc] _onAppSettingsRefreshed: userAppSettings.fontFamily: ${userAppSettings.displaySettings.fontFamily}',
      );
      print(
        '[AppBloc] _onAppSettingsRefreshed: userAppSettings.fontWeight: ${userAppSettings.displaySettings.fontWeight}',
      );
      print(
        '[AppBloc] _onAppSettingsRefreshed: newFontFamily mapped to: $newFontFamily',
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
    } on NotFoundException {
      // User settings not found (e.g., first time user), use defaults
      print('User app settings not found, using defaults.');
      // Emit state with default settings
      emit(
        state.copyWith(
          themeMode: ThemeMode.system,
          flexScheme: FlexScheme.material,
          appTextScaleFactor: AppTextScaleFactor.medium,
          locale: const Locale('en'),
          settings: UserAppSettings(id: state.user!.id),
        ),
      );
    } catch (e) {
      // Handle other potential errors during settings fetch
      // Optionally emit a failure state or log the error
      print('Error loading user app settings in AppBloc: $e');
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
    // Update settings and emit new state
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

  // --- Settings Mapping Helpers ---

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
      print(
        '[AppBloc] _mapFontFamily: Input is SystemDefault, returning null.',
      );
      return null;
    }
    // Otherwise, return the font family string directly.
    // The GoogleFonts.xyz().fontFamily getters often return strings like "Roboto-Regular",
    // but FlexColorScheme's fontFamily parameter or GoogleFonts.xyzTextTheme() expect simple names.
    print(
      '[AppBloc] _mapFontFamily: Input is $fontFamilyString, returning as is.',
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
      print(
        '[AppBloc] User is null. Skipping AppConfig fetch because it requires authentication.',
      );
      // If AppConfig was somehow present without a user, clear it.
      // And ensure status isn't stuck on configFetching if this event was dispatched erroneously.
      if (state.appConfig != null || state.status == AppStatus.configFetching) {
        emit(
          state.copyWith(
            appConfig: null,
            clearAppConfig: true,
            status: AppStatus.unauthenticated,
          ),
        );
      }
      return;
    }

    // Avoid refetching if already loaded for the current user session, unless explicitly trying to recover from a failed state.
    if (state.appConfig != null &&
        state.status != AppStatus.configFetchFailed) {
      print(
        '[AppBloc] AppConfig already loaded for user ${state.user?.id} and not in a failed state. Skipping fetch.',
      );
      return;
    }

    print(
      '[AppBloc] Attempting to fetch AppConfig for user: ${state.user!.id}...',
    );
    emit(
      state.copyWith(
        status: AppStatus.configFetching,
        appConfig: null,
        clearAppConfig: true,
      ),
    );

    try {
      final appConfig = await _appConfigRepository.read(id: 'app_config');
      print(
        '[AppBloc] AppConfig fetched successfully. ID: ${appConfig.id} for user: ${state.user!.id}',
      );

      // Determine the correct status based on the existing user's role.
      // This ensures that successfully fetching config doesn't revert auth status to 'initial'.
      final newStatusBasedOnUser = state.user!.role == UserRole.standardUser
          ? AppStatus.authenticated
          : AppStatus.anonymous;
      emit(state.copyWith(appConfig: appConfig, status: newStatusBasedOnUser));
    } on HtHttpException catch (e) {
      print(
        '[AppBloc] Failed to fetch AppConfig (HtHttpException) for user ${state.user?.id}: ${e.runtimeType} - ${e.message}',
      );
      emit(
        state.copyWith(
          status: AppStatus.configFetchFailed,
          appConfig: null,
          clearAppConfig: true,
        ),
      );
    } catch (e, s) {
      print(
        '[AppBloc] Unexpected error fetching AppConfig for user ${state.user?.id}: $e',
      );
      print('[AppBloc] Stacktrace: $s');
      emit(
        state.copyWith(
          status: AppStatus.configFetchFailed,
          appConfig: null,
          clearAppConfig: true,
        ),
      );
    }
  }

  Future<void> _onAppUserAccountActionShown(
    AppUserAccountActionShown event,
    Emitter<AppState> emit,
  ) async {
    if (state.user != null && state.user!.id == event.userId) {
      final now = DateTime.now();
      // Optimistically update the local user state.
      // Corrected parameter name for copyWith as per User model in models.txt
      final updatedUser = state.user!.copyWith(lastEngagementShownAt: now);

      // Emit the change so UI can react if needed, and other BLoCs get the update.
      // This also ensures that FeedInjectorService will see the updated timestamp immediately.
      emit(state.copyWith(user: updatedUser));

      // TODO: Persist this change to the backend.
      // This would typically involve calling a method on a repository, e.g.:
      // try {
      //   await _authenticationRepository.updateUserLastActionTimestamp(event.userId, now);
      //   // If the repository's authStateChanges stream doesn't automatically emit
      //   // the updated user, you might need to re-fetch or handle it here.
      //   // For now, we've optimistically updated the local state.
      // } catch (e) {
      //   // Handle error, potentially revert optimistic update or show an error.
      //   print('Failed to update lastAccountActionShownAt on backend: $e');
      //   // Optionally revert: emit(state.copyWith(user: state.user));
      // }
      print(
        '[AppBloc] User ${event.userId} AccountAction shown. Last shown timestamp updated locally to $now. Backend update pending.',
      );
    }
  }
}
