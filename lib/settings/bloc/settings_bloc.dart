import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_preferences_client/ht_preferences_client.dart'; // Import models and exceptions
import 'package:ht_preferences_repository/ht_preferences_repository.dart';

part 'settings_event.dart'; // Contains event definitions
part 'settings_state.dart';

/// {@template settings_bloc}
/// Manages the state for the application settings feature.
///
/// Handles loading settings from [HtPreferencesRepository] and processing
/// user actions to update settings.
/// {@endtemplate}
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  /// {@macro settings_bloc}
  SettingsBloc({required HtPreferencesRepository preferencesRepository})
    : _preferencesRepository = preferencesRepository,
      super(const SettingsState()) {
    // Register event handlers
    on<SettingsLoadRequested>(_onLoadRequested);
    on<SettingsAppThemeModeChanged>(
      _onAppThemeModeChanged,
      transformer: sequential(), // Ensure saves happen sequentially
    );
    on<SettingsAppThemeNameChanged>(
      _onAppThemeNameChanged,
      transformer: sequential(),
    );
    on<SettingsAppFontSizeChanged>(
      _onAppFontSizeChanged,
      transformer: sequential(),
    );
    on<SettingsAppFontTypeChanged>(
      _onAppFontTypeChanged,
      transformer: sequential(),
    );
    on<SettingsFeedTileTypeChanged>(
      _onFeedTileTypeChanged,
      transformer: sequential(),
    );
    on<SettingsArticleFontSizeChanged>(
      _onArticleFontSizeChanged, // Corrected handler name if it was misspelled
      transformer: sequential(),
    );
    on<SettingsNotificationsEnabledChanged>(
      _onNotificationsEnabledChanged, // Corrected handler name if it was misspelled
      transformer: sequential(),
    );
  }

  final HtPreferencesRepository _preferencesRepository;

  /// Handles the initial loading of all settings.
  Future<void> _onLoadRequested(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      // Fetch all settings concurrently
      final results = await Future.wait([
        _tryFetch(_preferencesRepository.getAppSettings),
        _tryFetch(_preferencesRepository.getArticleSettings),
        _tryFetch(_preferencesRepository.getThemeSettings),
        _tryFetch(_preferencesRepository.getFeedSettings),
        _tryFetch(_preferencesRepository.getNotificationSettings),
      ]);

      // Process results, using defaults from initial state if fetch returned null
      emit(
        state.copyWith(
          status: SettingsStatus.success,
          appSettings: results[0] as AppSettings? ?? state.appSettings,
          articleSettings:
              results[1] as ArticleSettings? ?? state.articleSettings,
          themeSettings: results[2] as ThemeSettings? ?? state.themeSettings,
          feedSettings: results[3] as FeedSettings? ?? state.feedSettings,
          notificationSettings:
              results[4] as NotificationSettings? ?? state.notificationSettings,
          clearError: true,
        ),
      );
    } catch (e) {
      // If any fetch failed beyond PreferenceNotFoundException
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    }
  }

  /// Helper to fetch a setting and handle PreferenceNotFoundException gracefully.
  Future<T?> _tryFetch<T>(Future<T> Function() fetcher) async {
    try {
      return await fetcher();
    } on PreferenceNotFoundException {
      // Setting not found, return null to use default from state
      return null;
    } on PreferenceUpdateException {
      // Rethrow other update/fetch exceptions to be caught by the caller
      rethrow;
    } catch (e) {
      // Rethrow unexpected errors
      rethrow;
    }
  }

  /// Handles changes to the App Theme Mode setting.
  Future<void> _onAppThemeModeChanged(
    SettingsAppThemeModeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    // Manually create new instance as copyWith is missing
    final newThemeSettings = ThemeSettings(
      themeMode: event.themeMode,
      themeName: state.themeSettings.themeName, // Keep existing value
    );
    // Optimistically update UI
    emit(
      state.copyWith(
        status: SettingsStatus.success, // Keep success state
        themeSettings: newThemeSettings,
      ),
    ); // Removed trailing comma

    try {
      await _preferencesRepository.setThemeSettings(newThemeSettings);
      // No need to emit again on success, UI already updated
    } catch (e) {
      // Revert optimistic update on failure and show error
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          themeSettings: state.themeSettings, // Revert to previous
          error: e,
        ),
      ); // Removed trailing comma
    }
  }

  /// Handles changes to the App Theme Name setting.
  Future<void> _onAppThemeNameChanged(
    SettingsAppThemeNameChanged event,
    Emitter<SettingsState> emit,
  ) async {
    // Manually create new instance
    final newThemeSettings = ThemeSettings(
      themeMode: state.themeSettings.themeMode, // Keep existing value
      themeName: event.themeName,
    );
    emit(state.copyWith(themeSettings: newThemeSettings));
    try {
      await _preferencesRepository.setThemeSettings(newThemeSettings);
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          themeSettings: state.themeSettings,
          error: e,
        ),
      ); // Removed trailing comma
    }
  }

  /// Handles changes to the App Font Size setting.
  Future<void> _onAppFontSizeChanged(
    SettingsAppFontSizeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    // Manually create new instance
    final newAppSettings = AppSettings(
      appFontSize: event.fontSize,
      appFontType: state.appSettings.appFontType, // Keep existing value
    );
    emit(state.copyWith(appSettings: newAppSettings));
    try {
      await _preferencesRepository.setAppSettings(newAppSettings);
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          appSettings: state.appSettings,
          error: e,
        ),
      ); // Removed trailing comma
    }
  }

  /// Handles changes to the App Font Type setting.
  Future<void> _onAppFontTypeChanged(
    SettingsAppFontTypeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    // Manually create new instance
    final newAppSettings = AppSettings(
      appFontSize: state.appSettings.appFontSize, // Keep existing value
      appFontType: event.fontType,
    );
    emit(state.copyWith(appSettings: newAppSettings));
    try {
      await _preferencesRepository.setAppSettings(newAppSettings);
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          appSettings: state.appSettings,
          error: e,
        ),
      ); // Removed trailing comma
    }
  }

  /// Handles changes to the Feed Tile Type setting.
  Future<void> _onFeedTileTypeChanged(
    SettingsFeedTileTypeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    // Manually create new instance
    final newFeedSettings = FeedSettings(feedListTileType: event.tileType);
    emit(state.copyWith(feedSettings: newFeedSettings));
    try {
      await _preferencesRepository.setFeedSettings(newFeedSettings);
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          feedSettings: state.feedSettings,
          error: e,
        ),
      ); // Removed trailing comma
    }
  }

  /// Handles changes to the Article Font Size setting.
  Future<void> _onArticleFontSizeChanged(
    SettingsArticleFontSizeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    // Manually create new instance
    final newArticleSettings = ArticleSettings(articleFontSize: event.fontSize);
    emit(state.copyWith(articleSettings: newArticleSettings));
    try {
      await _preferencesRepository.setArticleSettings(newArticleSettings);
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          articleSettings: state.articleSettings,
          error: e,
        ),
      ); // Removed trailing comma
    }
  }

  /// Handles changes to the Notifications Enabled setting.
  Future<void> _onNotificationsEnabledChanged(
    SettingsNotificationsEnabledChanged event,
    Emitter<SettingsState> emit,
  ) async {
    // Manually create new instance
    // Note: This only updates the 'enabled' flag. Updating followed items
    // would require copying the lists as well.
    final newNotificationSettings = NotificationSettings(
      enabled: event.enabled,
      categoryNotifications: state.notificationSettings.categoryNotifications,
      sourceNotifications: state.notificationSettings.sourceNotifications,
      followedEventCountryIds:
          state.notificationSettings.followedEventCountryIds,
    );
    emit(state.copyWith(notificationSettings: newNotificationSettings));
    try {
      await _preferencesRepository.setNotificationSettings(
        newNotificationSettings,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          notificationSettings: state.notificationSettings,
          error: e,
        ),
      ); // Removed trailing comma
    }
  }
} // Added closing brace
