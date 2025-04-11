import 'dart:async';

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart'; // Added
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Added for font mapping
import 'package:ht_authentication_client/ht_authentication_client.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';
import 'package:ht_preferences_client/ht_preferences_client.dart'; // Added
import 'package:ht_preferences_repository/ht_preferences_repository.dart'; // Added

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({
    required HtAuthenticationRepository authenticationRepository,
    required HtPreferencesRepository preferencesRepository, // Added
  })  : _authenticationRepository = authenticationRepository,
        _preferencesRepository = preferencesRepository, // Added
        // Initialize with default state, load settings after user is known
        super(AppState()) {
    on<AppUserChanged>(_onAppUserChanged);
    // Add handler for explicitly refreshing settings if needed later
    on<AppSettingsRefreshed>(_onAppSettingsRefreshed);

    // Listen directly to the user stream
    _userSubscription = _authenticationRepository.user.listen(
      (User user) => add(AppUserChanged(user)), // Explicitly type user
    );
  }

  final HtAuthenticationRepository _authenticationRepository;
  final HtPreferencesRepository _preferencesRepository; // Added
  late final StreamSubscription<User> _userSubscription;

  // Removed _onAppThemeChanged

  /// Handles user changes and loads initial settings once user is available.
  Future<void> _onAppUserChanged(
    AppUserChanged event,
    Emitter<AppState> emit,
  ) async {
    // Determine the AppStatus based on the user's AuthenticationStatus
    final AppStatus status;
    switch (event.user.authenticationStatus) {
      case AuthenticationStatus.unauthenticated:
        status = AppStatus.unauthenticated;
        // Emit status change immediately for unauthenticated users
        emit(state.copyWith(status: status, user: event.user));
        return; // Don't load settings for unauthenticated users
      case AuthenticationStatus.anonymous:
        status = AppStatus.anonymous;
        break; // Continue to load settings for anonymous
      case AuthenticationStatus.authenticated:
        status = AppStatus.authenticated;
        break; // Continue to load settings for authenticated
    }

    // Emit user and status update first
    emit(state.copyWith(status: status, user: event.user));

    // Load settings now that we have a user (anonymous or authenticated)
    // Use a separate event to avoid complexity within this handler
    add(const AppSettingsRefreshed());
  }

  /// Handles refreshing/loading app settings (theme, font).
  Future<void> _onAppSettingsRefreshed(
    AppSettingsRefreshed event,
    Emitter<AppState> emit,
  ) async {
    // Avoid loading if user is unauthenticated (shouldn't happen if logic is correct)
    if (state.status == AppStatus.unauthenticated) return;

    try {
      // Fetch relevant settings
      final themeSettings =
          await _tryFetch(_preferencesRepository.getThemeSettings);
      final appSettings =
          await _tryFetch(_preferencesRepository.getAppSettings);

      // Map settings to AppState properties
      final newThemeMode = _mapAppThemeMode(
        themeSettings?.themeMode ?? AppThemeMode.system, // Default
      );
      final newFlexScheme = _mapAppThemeName(
        themeSettings?.themeName ?? AppThemeName.grey, // Default
      );
      final newFontFamily = _mapAppFontType(
        appSettings?.appFontType, // Nullable, default handled in theme
      );

      emit(
        state.copyWith(
          themeMode: newThemeMode,
          flexScheme: newFlexScheme,
          fontFamily: newFontFamily,
          // Use clearFontFamily flag if appSettings was null and we want to reset
          clearFontFamily: appSettings == null,
        ),
      );
    } catch (e) {
      // Handle potential errors during settings fetch
      // Optionally emit a failure state or log the error
      print('Error loading app settings in AppBloc: $e');
      // Keep the existing theme/font state on error
    }
  }

  /// Helper to fetch a setting and handle PreferenceNotFoundException gracefully.
  Future<T?> _tryFetch<T>(Future<T> Function() fetcher) async {
    try {
      return await fetcher();
    } on PreferenceNotFoundException {
      return null; // Setting not found, return null to use default
    } catch (e) {
      // Rethrow other errors to be caught by the caller
      rethrow;
    }
  }

  // --- Settings Mapping Helpers ---

  ThemeMode _mapAppThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
      default:
        return ThemeMode.system;
    }
  }

  FlexScheme _mapAppThemeName(AppThemeName name) {
    switch (name) {
      case AppThemeName.red:
        return FlexScheme.red;
      case AppThemeName.blue:
        return FlexScheme.blue;
      case AppThemeName.grey:
      default:
        return FlexScheme.material; // Default grey maps to material
    }
  }

  String? _mapAppFontType(AppFontType? type) {
    if (type == null) return null; // Use theme default if null

    switch (type) {
      case AppFontType.roboto:
        return GoogleFonts.roboto().fontFamily;
      case AppFontType.openSans:
        return GoogleFonts.openSans().fontFamily;
      case AppFontType.lato:
        return GoogleFonts.lato().fontFamily;
      case AppFontType.montserrat:
        return GoogleFonts.montserrat().fontFamily;
      case AppFontType.merriweather:
        return GoogleFonts.merriweather().fontFamily;
      // Add other fonts if necessary
      default:
        return null; // Fallback to theme default
    }
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
}
