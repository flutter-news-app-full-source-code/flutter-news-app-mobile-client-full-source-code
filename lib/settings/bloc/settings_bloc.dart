import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/inline_ad_cache_service.dart';

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
    required DataRepository<UserAppSettings> userAppSettingsRepository,
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
      _onAppFontWeightChanged,
      transformer: sequential(),
    );
    on<SettingsHeadlineImageStyleChanged>(
      _onHeadlineImageStyleChanged,
      transformer: sequential(),
    );
    on<SettingsLanguageChanged>(_onLanguageChanged, transformer: sequential());
  }

  final DataRepository<UserAppSettings> _userAppSettingsRepository;

  Future<void> _persistSettings(
    UserAppSettings settingsToSave,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _userAppSettingsRepository.update(
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
      await _userAppSettingsRepository.create(
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
      final defaultLanguage = languagesFixturesData.firstWhere(
        (l) => l.code == 'en',
        orElse: () => throw StateError(
          'Default language "en" not found in language fixtures.',
        ),
      );

      final defaultSettings = UserAppSettings(
        id: event.userId,
        displaySettings: const DisplaySettings(
          baseTheme: AppBaseTheme.system,
          accentTheme: AppAccentTheme.defaultBlue,
          fontFamily: 'SystemDefault',
          textScaleFactor: AppTextScaleFactor.medium,
          fontWeight: AppFontWeight.regular,
        ),
        language: defaultLanguage,
        feedPreferences: const FeedDisplayPreferences(
          headlineDensity: HeadlineDensity.standard,
          headlineImageStyle: HeadlineImageStyle.largeThumbnail,
          showSourceInHeadlineFeed: true,
          showPublishDateInHeadlineFeed: true,
        ),
      );
      emit(
        state.copyWith(
          status: SettingsStatus.success,
          userAppSettings: defaultSettings,
        ),
      );
      // Persist these default settings
      await _persistSettings(defaultSettings, emit);
    } on HttpException catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure, error: e));
    }
  }

  Future<void> _onAppThemeModeChanged(
    SettingsAppThemeModeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.userAppSettings == null) return;

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
    // When the theme's accent color changes, ads must be reloaded to reflect
    // the new styling. Clearing the cache ensures that any visible or
    // soon-to-be-visible ads are fetched again with the updated theme.
    InlineAdCacheService().clearAllAds();
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

    final updatedSettings = state.userAppSettings!.copyWith(
      displaySettings: state.userAppSettings!.displaySettings.copyWith(
        fontFamily: event.fontType,
      ),
    );
    emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    await _persistSettings(updatedSettings, emit);
  }

  Future<void> _onAppFontWeightChanged(
    SettingsAppFontWeightChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.userAppSettings == null) return;

    final updatedSettings = state.userAppSettings!.copyWith(
      displaySettings: state.userAppSettings!.displaySettings.copyWith(
        fontWeight: event.fontWeight,
      ),
    );
    emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    await _persistSettings(updatedSettings, emit);
  }

  Future<void> _onHeadlineImageStyleChanged(
    SettingsHeadlineImageStyleChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.userAppSettings == null) return;

    final updatedSettings = state.userAppSettings!.copyWith(
      feedPreferences: state.userAppSettings!.feedPreferences.copyWith(
        headlineImageStyle: event.imageStyle,
      ),
    );
    emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    // The headline image style directly influences which native ad template
    // (small or medium) is requested. To ensure the correct ad format is
    // displayed, the cache must be cleared, forcing a new ad load with the
    // appropriate template.
    InlineAdCacheService().clearAllAds();
    await _persistSettings(updatedSettings, emit);
  }

  Future<void> _onLanguageChanged(
    SettingsLanguageChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.userAppSettings == null) return;

    final updatedSettings = state.userAppSettings!.copyWith(
      language: event.language,
    );
    emit(state.copyWith(userAppSettings: updatedSettings, clearError: true));
    await _persistSettings(updatedSettings, emit);
  }
}
