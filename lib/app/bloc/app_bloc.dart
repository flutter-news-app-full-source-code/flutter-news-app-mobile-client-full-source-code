import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ht_auth_repository/ht_auth_repository.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_shared/ht_shared.dart'; // Import shared models and exceptions

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({
    required HtAuthRepository authenticationRepository,
    required HtDataRepository<UserAppSettings> userAppSettingsRepository,
  }) : _authenticationRepository = authenticationRepository,
       _userAppSettingsRepository = userAppSettingsRepository,
       // Initialize with default state, load settings after user is known
       // Provide a default UserAppSettings instance
       super(
         const AppState(
           settings: UserAppSettings(id: 'default'),
           selectedBottomNavigationIndex: 0,
         ),
       ) {
    on<AppUserChanged>(_onAppUserChanged);
    on<AppSettingsRefreshed>(_onAppSettingsRefreshed);
    on<AppLogoutRequested>(_onLogoutRequested);
    on<AppThemeModeChanged>(_onThemeModeChanged);
    on<AppFlexSchemeChanged>(_onFlexSchemeChanged);
    on<AppFontFamilyChanged>(_onFontFamilyChanged);
    on<AppTextScaleFactorChanged>(_onAppTextScaleFactorChanged);

    // Listen directly to the auth state changes stream
    _userSubscription = _authenticationRepository.authStateChanges.listen(
      (User? user) => add(AppUserChanged(user)), // Handle nullable user
    );
  }

  final HtAuthRepository _authenticationRepository;
  final HtDataRepository<UserAppSettings> _userAppSettingsRepository;
  late final StreamSubscription<User?> _userSubscription;

  /// Handles user changes and loads initial settings once user is available.
  Future<void> _onAppUserChanged(
    AppUserChanged event,
    Emitter<AppState> emit,
  ) async {
    // Determine the AppStatus based on the user object and its role
    final AppStatus status;
    switch (event.user?.role) {
      case null: // User is null (unauthenticated)
        status = AppStatus.unauthenticated;
      case UserRole.standardUser:
        status = AppStatus.authenticated;
      // ignore: no_default_cases
      default:
        status = AppStatus.anonymous;
    }

    // Emit user and status update first
    emit(state.copyWith(status: status, user: event.user));

    // Load settings now that we have a user (anonymous or authenticated)
    if (event.user != null) {
      add(const AppSettingsRefreshed());
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
        userId: state.user!.id, // Scope to the current user
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

      print('[AppBloc] _onAppSettingsRefreshed: userAppSettings.fontFamily: ${userAppSettings.displaySettings.fontFamily}');
      print('[AppBloc] _onAppSettingsRefreshed: userAppSettings.fontWeight: ${userAppSettings.displaySettings.fontWeight}');
      print('[AppBloc] _onAppSettingsRefreshed: newFontFamily mapped to: $newFontFamily');

      emit(
        state.copyWith(
          themeMode: newThemeMode,
          flexScheme: newFlexScheme,
          appTextScaleFactor: newAppTextScaleFactor,
          fontFamily: newFontFamily,
          settings: userAppSettings, // Store the fetched settings
          locale: newLocale, // Store the new locale
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
          appTextScaleFactor: AppTextScaleFactor.medium, // Default enum value
          locale: const Locale('en'), // Default to English if settings not found
          settings: UserAppSettings(
            id: state.user!.id,
          ), // Provide default settings
        ),
      );
    } catch (e) {
      // Handle other potential errors during settings fetch
      // Optionally emit a failure state or log the error
      print('Error loading user app settings in AppBloc: $e');
      // Keep the existing theme/font state on error, but ensure settings is not null
      emit(
        state.copyWith(settings: state.settings),
      ); // Ensure settings is present
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
        baseTheme:
            event.themeMode == ThemeMode.light
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
        accentTheme:
            event.flexScheme == FlexScheme.blue
                ? AppAccentTheme.defaultBlue
                : (event.flexScheme == FlexScheme.red
                    ? AppAccentTheme.newsRed
                    : AppAccentTheme
                        .graphiteGray), // Mapping material to graphiteGray
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
        fontFamily:
            event.fontFamily ?? 'SystemDefault', // Map null to 'SystemDefault'
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
        return FlexScheme.material; // Mapping graphiteGray to material for now
    }
  }

  String? _mapFontFamily(String fontFamily) {
    // Assuming 'SystemDefault' means use the theme's default font
    if (fontFamily == 'SystemDefault') return null;

    // Map specific font family names to GoogleFonts
    switch (fontFamily) {
      case 'Roboto':
        return GoogleFonts.roboto().fontFamily;
      case 'OpenSans':
        return GoogleFonts.openSans().fontFamily;
      case 'Lato':
        return GoogleFonts.lato().fontFamily;
      case 'Montserrat':
        return GoogleFonts.montserrat().fontFamily;
      case 'Merriweather':
        return GoogleFonts.merriweather().fontFamily;
      default:
        // If an unknown font family is specified, fall back to theme default
        return null;
    }
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
}
