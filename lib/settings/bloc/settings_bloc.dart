import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/inline_ad_cache_service.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// {@template settings_bloc}
/// Manages the state for the application settings feature.
///
/// Handles loading [UserAppSettings] from [DataRepository] and processing
/// user actions to update these settings.
/// {@endtemplate}
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  /// {@macro settings_bloc}
  SettingsBloc({
    required DataRepository<AppSettings> appSettingsRepository,
    required InlineAdCacheService inlineAdCacheService,
  }) : _appSettingsRepository = appSettingsRepository,
       _inlineAdCacheService = inlineAdCacheService,
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
      _onAppFontWeightChanged,
      transformer: sequential(),
    );
    on<SettingsFeedItemImageStyleChanged>(
      _onFeedItemImageStyleChanged,
      transformer: sequential(),
    );
    on<SettingsLanguageChanged>(_onLanguageChanged, transformer: sequential());
  }

  final DataRepository<AppSettings> _appSettingsRepository;
  final InlineAdCacheService _inlineAdCacheService;

  Future<void> _persistSettings(
    AppSettings settingsToSave,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _appSettingsRepository.update(
        id: settingsToSave.id,
        item: settingsToSave,
        userId: settingsToSave.id,
      );
    } on NotFoundException {
      // If settings not found, create them
      // needed specifically for the demo mode
      // that uses the ht data in memory impl
      // as for the api impl, the backend handle
      // this use case.
      await _appSettingsRepository.create(
        item: settingsToSave,
        userId: settingsToSave.id,
      );
    } on HttpException catch (e) {
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
      final appSettings = await _appSettingsRepository.read(
        id: event.userId,
        userId: event.userId,
      );
      emit(
        state.copyWith(
          status: SettingsStatus.success,
          appSettings: appSettings,
        ),
      );
    } on HttpException {
      // Re-throw to AppBloc for centralized error handling
      rethrow;
    } catch (e) {
      // Re-throw to AppBloc for centralized error handling
      rethrow;
    }
  }

  Future<void> _onAppThemeModeChanged(
    SettingsAppThemeModeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.appSettings == null) return;

    final updatedSettings = state.appSettings!.copyWith(
      displaySettings: state.appSettings!.displaySettings.copyWith(
        baseTheme: event.themeMode,
      ),
    );
    emit(state.copyWith(appSettings: updatedSettings, clearError: true));
    await _persistSettings(updatedSettings, emit);
  }

  Future<void> _onAppThemeNameChanged(
    SettingsAppThemeNameChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.appSettings == null) return;

    final updatedSettings = state.appSettings!.copyWith(
      displaySettings: state.appSettings!.displaySettings.copyWith(
        accentTheme: event.themeName,
      ),
    );
    emit(state.copyWith(appSettings: updatedSettings, clearError: true));
    // When the theme's accent color changes, ads must be reloaded to reflect
    // the new styling. Clearing the cache ensures that any visible or
    // soon-to-be-visible ads are fetched again with the updated theme.
    _inlineAdCacheService.clearAllAds();
    await _persistSettings(updatedSettings, emit);
  }

  Future<void> _onAppFontSizeChanged(
    SettingsAppFontSizeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.appSettings == null) return;

    final updatedSettings = state.appSettings!.copyWith(
      displaySettings: state.appSettings!.displaySettings.copyWith(
        textScaleFactor: event.fontSize,
      ),
    );
    emit(state.copyWith(appSettings: updatedSettings, clearError: true));
    await _persistSettings(updatedSettings, emit);
  }

  Future<void> _onAppFontTypeChanged(
    SettingsAppFontTypeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.appSettings == null) return;

    final updatedSettings = state.appSettings!.copyWith(
      displaySettings: state.appSettings!.displaySettings.copyWith(
        fontFamily: event.fontType,
      ),
    );
    emit(state.copyWith(appSettings: updatedSettings, clearError: true));
    await _persistSettings(updatedSettings, emit);
  }

  Future<void> _onAppFontWeightChanged(
    SettingsAppFontWeightChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.appSettings == null) return;

    final updatedSettings = state.appSettings!.copyWith(
      displaySettings: state.appSettings!.displaySettings.copyWith(
        fontWeight: event.fontWeight,
      ),
    );
    emit(state.copyWith(appSettings: updatedSettings, clearError: true));
    await _persistSettings(updatedSettings, emit);
  }

  Future<void> _onFeedItemImageStyleChanged(
    SettingsFeedItemImageStyleChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.appSettings == null) return;

    final updatedSettings = state.appSettings!.copyWith(
      feedSettings: state.appSettings!.feedSettings.copyWith(
        feedItemImageStyle: event.imageStyle,
      ),
    );
    emit(state.copyWith(appSettings: updatedSettings, clearError: true));
    // The headline image style directly influences which native ad template
    // (small or medium) is requested. To ensure the correct ad format is
    // displayed, the cache must be cleared, forcing a new ad load with the
    // appropriate template.
    _inlineAdCacheService.clearAllAds();
    await _persistSettings(updatedSettings, emit);
  }

  Future<void> _onLanguageChanged(
    SettingsLanguageChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.appSettings == null) return;

    final updatedSettings = state.appSettings!.copyWith(
      language: event.language,
    );
    emit(state.copyWith(appSettings: updatedSettings, clearError: true));
    await _persistSettings(updatedSettings, emit);
  }
}
