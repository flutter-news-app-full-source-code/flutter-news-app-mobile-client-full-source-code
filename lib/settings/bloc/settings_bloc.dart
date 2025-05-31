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
/// Handles loading [UserAppSettings] from [HtDataRepository] and processing
/// user actions to update these settings.
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
      transformer: sequential(),
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
    on<SettingsAppFontWeightChanged>(
      // Added handler for font weight
      _onAppFontWeightChanged,
      transformer: sequential(),
    );
    on<SettingsFeedTileTypeChanged>(
      _onFeedTileTypeChanged,
      transformer: sequential(),
    );
    on<SettingsLanguageChanged>(_onLanguageChanged, transformer: sequential());
    // SettingsNotificationsEnabledChanged event and handler removed.
  }

  final HtDataRepository<UserAppSettings> _userAppSettingsRepository;

  Future<void> _persistSettings(
    UserAppSettings settingsToSave,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _userAppSettingsRepository.update(
        id: settingsToSave.id, // UserID is the ID of UserAppSettings
        item: settingsToSave,
        userId: settingsToSave.id, // Pass userId for repository method
      );
      // State already updated optimistically, no need to emit success here
      // unless we want a specific "save success" status.
    } on HtHttpException catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    }
  }

  Future<void> _onLoadRequested(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading, clearError: true));
    try {
      final appSettings = await _userAppSettingsRepository.read(
        id: event.userId,
        userId: event.userId,
      );
      emit(
        state.copyWith(
          status: SettingsStatus.success,
          userAppSettings: appSettings,
        ),
      );
    } on NotFoundException {
      // Settings not found for the user, create and persist defaults
      final defaultSettings = UserAppSettings(id: event.userId);
      emit(
        state.copyWith(
          status: SettingsStatus.success,
          userAppSettings: defaultSettings,
        ),
      );
      // Persist these default settings
      await _persistSettings(defaultSettings, emit);
    } on HtHttpException catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    }
  }

  Future<void> _onAppThemeModeChanged(
    SettingsAppThemeModeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.userAppSettings == null) return; // Guard against null settings

    final updatedSettings = state.userAppSettings!.copyWith(
      displaySettings: state.userAppSettings!.displaySettings.copyWith(
        baseTheme: event.themeMode,
      ),
    );
    emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    await _persistSettings(updatedSettings, emit);
  }

  Future<void> _onAppThemeNameChanged(
    SettingsAppThemeNameChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.userAppSettings == null) return;

    final updatedSettings = state.userAppSettings!.copyWith(
      displaySettings: state.userAppSettings!.displaySettings.copyWith(
        accentTheme: event.themeName,
      ),
    );
    emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    await _persistSettings(updatedSettings, emit);
  }

  Future<void> _onAppFontSizeChanged(
    SettingsAppFontSizeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.userAppSettings == null) return;

    final updatedSettings = state.userAppSettings!.copyWith(
      displaySettings: state.userAppSettings!.displaySettings.copyWith(
        textScaleFactor: event.fontSize,
      ),
    );
    emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    await _persistSettings(updatedSettings, emit);
  }

  Future<void> _onAppFontTypeChanged(
    SettingsAppFontTypeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.userAppSettings == null) return;
    print(
      '[SettingsBloc] _onAppFontTypeChanged: Received event.fontType: ${event.fontType}',
    );

    final updatedSettings = state.userAppSettings!.copyWith(
      displaySettings: state.userAppSettings!.displaySettings.copyWith(
        fontFamily: event.fontType,
      ),
    );
    print(
      '[SettingsBloc] _onAppFontTypeChanged: Updated settings.fontFamily: ${updatedSettings.displaySettings.fontFamily}',
    );
    emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    await _persistSettings(updatedSettings, emit);
  }

  Future<void> _onAppFontWeightChanged(
    SettingsAppFontWeightChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.userAppSettings == null) return;
    print(
      '[SettingsBloc] _onAppFontWeightChanged: Received event.fontWeight: ${event.fontWeight}',
    );

    final updatedSettings = state.userAppSettings!.copyWith(
      displaySettings: state.userAppSettings!.displaySettings.copyWith(
        fontWeight: event.fontWeight,
      ),
    );
    print(
      '[SettingsBloc] _onAppFontWeightChanged: Updated settings.fontWeight: ${updatedSettings.displaySettings.fontWeight}',
    );
    emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    await _persistSettings(updatedSettings, emit);
  }

  Future<void> _onFeedTileTypeChanged(
    SettingsFeedTileTypeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.userAppSettings == null) return;

    final updatedSettings = state.userAppSettings!.copyWith(
      feedPreferences: state.userAppSettings!.feedPreferences.copyWith(
        headlineImageStyle: event.tileType,
      ),
    );
    emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    await _persistSettings(updatedSettings, emit);
  }

  Future<void> _onLanguageChanged(
    SettingsLanguageChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.userAppSettings == null) return;

    final updatedSettings = state.userAppSettings!.copyWith(
      language: event.languageCode,
    );
    emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    await _persistSettings(updatedSettings, emit);
  }
}
