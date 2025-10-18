import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_initializer.dart';
import 'package:logging/logging.dart';

part 'app_event.dart';
part 'app_state.dart';

/// {@template app_bloc}
/// Manages the overall application state, including authentication status,
/// user settings, and remote configuration.
///
/// This BLoC is central to the application's lifecycle, reacting to user
/// authentication changes, managing user preferences, and applying global
/// remote configurations. It acts as the single source of truth for global
/// application state.
/// {@endtemplate}
class AppBloc extends Bloc<AppEvent, AppState> {
  /// {@macro app_bloc}
  ///
  /// Initializes the BLoC with required repositories, environment, and
  /// pre-fetched initial data.
  AppBloc({
    required User? user,
    required RemoteConfig remoteConfig,
    required UserAppSettings? settings,
    required UserContentPreferences? userContentPreferences,
    required DataRepository<RemoteConfig> remoteConfigRepository,
    required AppInitializer appInitializer,
    required AuthRepository authRepository,
    required DataRepository<UserAppSettings> userAppSettingsRepository,
    required DataRepository<UserContentPreferences>
    userContentPreferencesRepository,
    required DataRepository<User> userRepository,
  }) : _remoteConfigRepository = remoteConfigRepository,
       _appInitializer = appInitializer,
       _authRepository = authRepository,
       _userAppSettingsRepository = userAppSettingsRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _userRepository = userRepository,
       _logger = Logger('AppBloc'),
       super(
         AppState(
           status: user == null
               ? AppLifeCycleStatus.unauthenticated
               : user.isGuest
               ? AppLifeCycleStatus.anonymous
               : AppLifeCycleStatus.authenticated,
           user: user,
           remoteConfig: remoteConfig,
           settings: settings,
           userContentPreferences: userContentPreferences,
         ),
       ) {
    // Register event handlers for various app-level events.
    on<AppStarted>(_onAppStarted);
    on<AppUserChanged>(_onAppUserChanged);
    on<AppUserAppSettingsRefreshed>(_onUserAppSettingsRefreshed);
    on<AppUserContentPreferencesRefreshed>(_onUserContentPreferencesRefreshed);
    on<AppSettingsChanged>(_onAppSettingsChanged);
    on<AppPeriodicConfigFetchRequested>(_onAppPeriodicConfigFetchRequested);
    on<AppUserFeedDecoratorShown>(_onAppUserFeedDecoratorShown);
    on<AppUserContentPreferencesChanged>(_onAppUserContentPreferencesChanged);
    on<SavedFilterAdded>(_onSavedFilterAdded);
    on<SavedFilterUpdated>(_onSavedFilterUpdated);
    on<SavedFilterDeleted>(_onSavedFilterDeleted);
    on<SavedFiltersReordered>(_onSavedFiltersReordered);
    on<AppLogoutRequested>(_onLogoutRequested);
  }

  final Logger _logger;
  final DataRepository<RemoteConfig> _remoteConfigRepository;
  final AppInitializer _appInitializer;
  final AuthRepository _authRepository;
  final DataRepository<UserAppSettings> _userAppSettingsRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final DataRepository<User> _userRepository;

  /// Handles the [AppStarted] event.
  ///
  /// This is now a no-op as all initialization logic has been moved to the
  /// [AppInitializer] and is processed in the [AppBloc] constructor.
  Future<void> _onAppStarted(AppStarted event, Emitter<AppState> emit) async {
    _logger.fine(
      '[AppBloc] AppStarted event received. State is already initialized.',
    );
  }

  /// Handles all logic related to user authentication state changes.
  Future<void> _onAppUserChanged(
    AppUserChanged event,
    Emitter<AppState> emit,
  ) async {
    final oldUser = state.user;
    final newUser = event.user;

    // Critical Change: Detect not just user ID changes, but also role changes.
    // This is essential for the "anonymous to authenticated" flow.
    if (oldUser?.id == newUser?.id && oldUser?.appRole == newUser?.appRole) {
      _logger.info(
        '[AppBloc] AppUserChanged triggered, but user ID and role are the same. '
        'Skipping transition.',
      );
      return;
    }

    // If the user is null, it's a logout.
    if (newUser == null) {
      _logger.info(
        '[AppBloc] User logged out. Transitioning to unauthenticated.',
      );
      emit(
        state.copyWith(
          status: AppLifeCycleStatus.unauthenticated,
          user: null,
          settings: null,
          userContentPreferences: null,
        ),
      );
      return;
    }

    // A user is present, so we are logging in or transitioning roles.
    // Show a loading screen while we handle this process.
    emit(state.copyWith(status: AppLifeCycleStatus.loadingUserData));

    // CRITICAL: Guard against a null remoteConfig. This can happen if the
    // initial app load failed but a user change event is somehow triggered.
    // Without this check, the app would crash.
    if (state.remoteConfig == null) {
      _logger.severe(
        '[AppBloc] CRITICAL: A user transition was attempted, but remoteConfig '
        'is null. This indicates a failed initial startup. Halting transition.',
      );
      emit(
        state.copyWith(
          status: AppLifeCycleStatus.criticalError,
          error: const UnknownException(
            'Cannot process user transition without remote configuration.',
          ),
        ),
      );
      return;
    }

    // Delegate the complex transition logic to the AppInitializer.
    final transitionResult = await _appInitializer.handleUserTransition(
      oldUser: oldUser,
      newUser: newUser,
      remoteConfig: state.remoteConfig!,
    );

    // Update the state based on the result of the transition.
    switch (transitionResult) {
      case InitializationSuccess(
        :final user,
        :final settings,
        :final userContentPreferences,
      ):
        emit(
          state.copyWith(
            status: user!.isGuest
                ? AppLifeCycleStatus.anonymous
                : AppLifeCycleStatus.authenticated,
            user: user,
            settings: settings,
            userContentPreferences: userContentPreferences,
            clearError: true,
          ),
        );
      case InitializationFailure(:final status, :final error):
        emit(state.copyWith(status: status, error: error));
    }
  }

  /// Handles refreshing/loading app settings (theme, font).
  Future<void> _onUserAppSettingsRefreshed(
    AppUserAppSettingsRefreshed event,
    Emitter<AppState> emit,
  ) async {
    if (state.user == null) {
      _logger.info(
        '[AppBloc] Skipping AppUserAppSettingsRefreshed: User is null.',
      );
      return;
    }

    final settings = await _userAppSettingsRepository.read(
      id: state.user!.id,
      userId: state.user!.id,
    );
    emit(state.copyWith(settings: settings));
  }

  /// Handles refreshing/loading user content preferences.
  Future<void> _onUserContentPreferencesRefreshed(
    AppUserContentPreferencesRefreshed event,
    Emitter<AppState> emit,
  ) async {
    if (state.user == null) {
      _logger.info(
        '[AppBloc] Skipping AppUserContentPreferencesRefreshed: User is null.',
      );
      return;
    }

    final preferences = await _userContentPreferencesRepository.read(
      id: state.user!.id,
      userId: state.user!.id,
    );
    emit(state.copyWith(userContentPreferences: preferences));
  }

  /// Handles the [AppSettingsChanged] event, updating and persisting the
  /// user's application settings.
  Future<void> _onAppSettingsChanged(
    AppSettingsChanged event,
    Emitter<AppState> emit,
  ) async {
    if (state.user == null || state.settings == null) {
      _logger.warning(
        '[AppBloc] Skipping AppSettingsChanged: User or UserAppSettings not loaded.',
      );
      return;
    }

    final updatedSettings = event.settings;
    emit(state.copyWith(settings: updatedSettings));

    try {
      await _userAppSettingsRepository.update(
        id: updatedSettings.id,
        item: updatedSettings,
        userId: updatedSettings.id,
      );
      _logger.info(
        '[AppBloc] UserAppSettings successfully updated for user ${updatedSettings.id}.',
      );
    } catch (e, s) {
      _logger.severe(
        'Failed to persist UserAppSettings for user ${updatedSettings.id}.',
        e,
        s,
      );
      emit(state.copyWith(settings: state.settings));
    }
  }

  /// Handles user logout request.
  void _onLogoutRequested(AppLogoutRequested event, Emitter<AppState> emit) {
    unawaited(_authRepository.signOut());
  }

  /// Handles periodic fetching of the remote application configuration.
  Future<void> _onAppPeriodicConfigFetchRequested(
    AppPeriodicConfigFetchRequested event,
    Emitter<AppState> emit,
  ) async {
    _logger.fine('[AppBloc] Periodic remote config fetch requested.');
    try {
      final remoteConfig = await _remoteConfigRepository.read(
        id: kRemoteConfigId,
      );

      if (remoteConfig.appStatus.isUnderMaintenance) {
        _logger.warning(
          '[AppBloc] Maintenance mode detected. Updating status.',
        );
        emit(
          state.copyWith(
            status: AppLifeCycleStatus.underMaintenance,
            remoteConfig: remoteConfig,
          ),
        );
        return;
      }

      if (state.status == AppLifeCycleStatus.underMaintenance &&
          !remoteConfig.appStatus.isUnderMaintenance) {
        _logger.info(
          '[AppBloc] Maintenance mode lifted. Restoring previous status.',
        );
        final restoredStatus = state.user == null
            ? AppLifeCycleStatus.unauthenticated
            : (state.user!.isGuest
                  ? AppLifeCycleStatus.anonymous
                  : AppLifeCycleStatus.authenticated);
        emit(
          state.copyWith(status: restoredStatus, remoteConfig: remoteConfig),
        );
      }
    } catch (e, s) {
      _logger.warning(
        '[AppBloc] Failed to fetch remote config during periodic check.',
        e,
        s,
      );
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
          'status successfully updated.',
        );
      } catch (e) {
        _logger.severe('Failed to update feed decorator status: $e');
        emit(state.copyWith(user: originalUser));
      }
    }
  }

  /// Handles updating the user's content preferences.
  Future<void> _onAppUserContentPreferencesChanged(
    AppUserContentPreferencesChanged event,
    Emitter<AppState> emit,
  ) async {
    if (state.user == null) {
      _logger.warning(
        '[AppBloc] Skipping AppUserContentPreferencesChanged: User is null.',
      );
      return;
    }

    final updatedPreferences = event.preferences;
    emit(state.copyWith(userContentPreferences: updatedPreferences));

    try {
      await _userContentPreferencesRepository.update(
        id: updatedPreferences.id,
        item: updatedPreferences,
        userId: updatedPreferences.id,
      );
      _logger.info(
        '[AppBloc] UserContentPreferences successfully updated for user ${updatedPreferences.id}.',
      );
    } catch (e, s) {
      _logger.severe(
        'Failed to persist UserContentPreferences for user ${updatedPreferences.id}.',
        e,
        s,
      );
      emit(
        state.copyWith(userContentPreferences: state.userContentPreferences),
      );
    }
  }

  /// Handles adding a new saved filter to the user's content preferences.
  Future<void> _onSavedFilterAdded(
    SavedFilterAdded event,
    Emitter<AppState> emit,
  ) async {
    if (state.userContentPreferences == null) {
      _logger.warning(
        '[AppBloc] Skipping SavedFilterAdded: UserContentPreferences not loaded.',
      );
      return;
    }

    final updatedSavedFilters = List<SavedFilter>.from(
      state.userContentPreferences!.savedFilters,
    )..add(event.filter);

    final updatedPreferences = state.userContentPreferences!.copyWith(
      savedFilters: updatedSavedFilters,
    );

    add(AppUserContentPreferencesChanged(preferences: updatedPreferences));
  }

  /// Handles updating an existing saved filter (e.g., renaming it).
  Future<void> _onSavedFilterUpdated(
    SavedFilterUpdated event,
    Emitter<AppState> emit,
  ) async {
    if (state.userContentPreferences == null) {
      _logger.warning(
        '[AppBloc] Skipping SavedFilterUpdated: UserContentPreferences not loaded.',
      );
      return;
    }

    final originalFilters = state.userContentPreferences!.savedFilters;
    final index = originalFilters.indexWhere((f) => f.id == event.filter.id);

    if (index == -1) {
      _logger.warning(
        '[AppBloc] Skipping SavedFilterUpdated: Filter with id ${event.filter.id} not found.',
      );
      return;
    }

    final updatedSavedFilters = List<SavedFilter>.from(originalFilters)
      ..[index] = event.filter;

    final updatedPreferences = state.userContentPreferences!.copyWith(
      savedFilters: updatedSavedFilters,
    );

    add(AppUserContentPreferencesChanged(preferences: updatedPreferences));
  }

  /// Handles deleting a saved filter from the user's content preferences.
  Future<void> _onSavedFilterDeleted(
    SavedFilterDeleted event,
    Emitter<AppState> emit,
  ) async {
    if (state.userContentPreferences == null) {
      _logger.warning(
        '[AppBloc] Skipping SavedFilterDeleted: UserContentPreferences not loaded.',
      );
      return;
    }

    final updatedSavedFilters = List<SavedFilter>.from(
      state.userContentPreferences!.savedFilters,
    )..removeWhere((f) => f.id == event.filterId);

    if (updatedSavedFilters.length ==
        state.userContentPreferences!.savedFilters.length) {
      _logger.warning(
        '[AppBloc] Skipping SavedFilterDeleted: Filter with id ${event.filterId} not found.',
      );
      return;
    }

    final updatedPreferences = state.userContentPreferences!.copyWith(
      savedFilters: updatedSavedFilters,
    );

    add(AppUserContentPreferencesChanged(preferences: updatedPreferences));
  }

  /// Handles reordering the list of saved filters.
  Future<void> _onSavedFiltersReordered(
    SavedFiltersReordered event,
    Emitter<AppState> emit,
  ) async {
    _logger.info('[AppBloc] SavedFiltersReordered event received.');

    if (state.userContentPreferences == null) {
      _logger.warning(
        '[AppBloc] Skipping SavedFiltersReordered: UserContentPreferences not loaded.',
      );
      return;
    }

    final updatedPreferences = state.userContentPreferences!.copyWith(
      savedFilters: event.reorderedFilters,
    );

    add(AppUserContentPreferencesChanged(preferences: updatedPreferences));
    _logger.info(
      '[AppBloc] Dispatched AppUserContentPreferencesChanged '
      'with reordered filters.',
    );
  }
}
