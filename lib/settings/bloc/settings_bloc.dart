import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart'; // Generic Data Repository
import 'package:ht_shared/ht_shared.dart'; // Shared models, including UserAppSettings and UserContentPreferences

part 'settings_event.dart'; // Contains event definitions
part 'settings_state.dart';

/// {@template settings_bloc}
/// Manages the state for the application settings feature.
///
/// Handles loading settings from [HtDataRepository] and processing
/// user actions to update settings.
/// {@endtemplate}
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  /// {@macro settings_bloc}
  SettingsBloc({
    required HtDataRepository<UserAppSettings> userAppSettingsRepository,
  }) : _userAppSettingsRepository = userAppSettingsRepository,
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
    // on<SettingsNotificationsEnabledChanged>(
    //   _onNotificationsEnabledChanged, // Corrected handler name if it was misspelled
    //   transformer: sequential(),
    // );
  }

  final HtDataRepository<UserAppSettings> _userAppSettingsRepository;

  /// Handles the initial loading of all settings.
  Future<void> _onLoadRequested(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      // Fetch all settings concurrently
      // Note: UserAppSettings and UserContentPreferences are fetched as single objects
      // from the new generic repositories.
      // TODO(cline): Get actual user ID
      final appSettings = await _userAppSettingsRepository.read(
        id: 'user_id',
      ); // Assuming a fixed ID for user settings

      // Process results
      emit(
        state.copyWith(
          status: SettingsStatus.success,
          userAppSettings: appSettings, // Update state with new model
          clearError: true,
        ),
      );
    } on HtHttpException catch (e) {
      // Catch standardized HTTP exceptions
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    } catch (e) {
      // Catch any other unexpected errors
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    }
  }

  /// Handles changes to the App Theme Mode setting.
  Future<void> _onAppThemeModeChanged(
    SettingsAppThemeModeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    // Read current settings, update, and save
    try {
      // TODO(cline): Get actual user ID
      final currentSettings = await _userAppSettingsRepository.read(
        id: 'user_id',
      );
      final updatedSettings = currentSettings.copyWith(
        displaySettings: currentSettings.displaySettings.copyWith(
          baseTheme: event.themeMode,
        ),
      );
      await _userAppSettingsRepository.update(
        id: 'user_id',
        item: updatedSettings,
      );
      emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    } on HtHttpException catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    }
  }

  /// Handles changes to the App Theme Name setting.
  Future<void> _onAppThemeNameChanged(
    SettingsAppThemeNameChanged event,
    Emitter<SettingsState> emit,
  ) async {
    // Read current settings, update, and save
    try {
      // TODO(cline): Get actual user ID
      final currentSettings = await _userAppSettingsRepository.read(
        id: 'user_id',
      );
      final updatedSettings = currentSettings.copyWith(
        displaySettings: currentSettings.displaySettings.copyWith(
          accentTheme: event.themeName,
        ),
      );
      await _userAppSettingsRepository.update(
        id: 'user_id',
        item: updatedSettings,
      );
      emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    } on HtHttpException catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    }
  }

  /// Handles changes to the App Font Size setting.
  Future<void> _onAppFontSizeChanged(
    SettingsAppFontSizeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    // Read current settings, update, and save
    try {
      // TODO(cline): Get actual user ID
      final currentSettings = await _userAppSettingsRepository.read(
        id: 'user_id',
      );
      final updatedSettings = currentSettings.copyWith(
        displaySettings: currentSettings.displaySettings.copyWith(
          textScaleFactor: event.fontSize,
        ),
      );
      await _userAppSettingsRepository.update(
        id: 'user_id',
        item: updatedSettings,
      );
      emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    } on HtHttpException catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    }
  }

  /// Handles changes to the App Font Type setting.
  Future<void> _onAppFontTypeChanged(
    SettingsAppFontTypeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    // Read current settings, update, and save
    try {
      // TODO(cline): Get actual user ID
      final currentSettings = await _userAppSettingsRepository.read(
        id: 'user_id',
      );
      final updatedSettings = currentSettings.copyWith(
        displaySettings: currentSettings.displaySettings.copyWith(
          fontFamily: event.fontType,
        ),
      );
      await _userAppSettingsRepository.update(
        id: 'user_id',
        item: updatedSettings,
      );
      emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    } on HtHttpException catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    }
  }

  /// Handles changes to the Feed Tile Type setting.
  Future<void> _onFeedTileTypeChanged(
    SettingsFeedTileTypeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    // Read current settings, update, and save
    try {
      // TODO(cline): Get actual user ID
      final currentSettings = await _userAppSettingsRepository.read(
        id: 'user_id',
      );
      // Note: This event currently only handles HeadlineImageStyle.
      // A separate event/logic might be needed for HeadlineDensity.
      final updatedSettings = currentSettings.copyWith(
        feedPreferences: currentSettings.feedPreferences.copyWith(
          headlineImageStyle: event.tileType,
        ),
      );
      await _userAppSettingsRepository.update(
        id: 'user_id',
        item: updatedSettings,
      );
      emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    } on HtHttpException catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    }
  }

  /// Handles changes to the Notifications Enabled setting.
  // Future<void> _onNotificationsEnabledChanged(
  //   SettingsNotificationsEnabledChanged event,
  //   Emitter<SettingsState> emit,
  // ) async {
  //   // Read current preferences, update, and save
  //   try {
  //     // TODO(cline): Get actual user ID
  //     final currentPreferences = await _userContentPreferencesRepository.read(id: 'user_id');
  //     // Note: This only updates the 'enabled' flag. Updating followed items
  //     // would require copying the lists as well.
  //     // The NotificationSettings model from the old preferences client doesn't directly map
  //     // to UserContentPreferences. Assuming notification enabled state is part of UserAppSettings.
  //     // Re-evaluating based on UserAppSettings model... UserAppSettings has engagementShownCounts
  //     // and engagementLastShownTimestamps, but no general notification enabled flag.
  //     // This suggests the notification enabled setting might need to be added to UserAppSettings
  //     // or handled differently. For now, I will add a TODO and emit a failure state.
  //     // TODO(cline): Determine where notification enabled setting is stored in new models.
  //     emit(state.copyWith(status: SettingsStatus.failure, error: Exception('Notification enabled setting location in new models is TBD.')));

  //     // If it were in UserAppSettings:
  //     /*
  //     final currentSettings = await _userAppSettingsRepository.read(id: 'user_id');
  //     final updatedSettings = currentSettings.copyWith(
  //       // Assuming a field like 'notificationsEnabled' exists in UserAppSettings
  //       notificationsEnabled: event.enabled,
  //     );
  //     await _userAppSettingsRepository.update(id: 'user_id', item: updatedSettings);
  //     emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
  //     */

  //   } on HtHttpException catch (e) {
  //     emit(state.copyWith(status: SettingsStatus.failure, error: e));
  //   } catch (e) {
  //     emit(state.copyWith(status: SettingsStatus.failure, error: e));
  //   }
  // }
}
