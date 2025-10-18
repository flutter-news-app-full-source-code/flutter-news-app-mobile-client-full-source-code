import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
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
    required InitializationResult initializationResult,
    required GlobalKey<NavigatorState> navigatorKey,
  }) : _navigatorKey = navigatorKey,
       _logger = Logger('AppBloc'),
       super(switch (initializationResult) {
         InitializationSuccess(
           :final user,
           :final remoteConfig,
           :final settings,
           :final userContentPreferences,
         ) =>
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
         InitializationFailure(:final status, :final error) => AppState(
           status: status,
           error: error,
         ),
       }) {
    // Register event handlers for various app-level events.
    on<AppStarted>(_onAppStarted);
    on<AppUserChanged>(_onAppUserChanged);
    on<AppUserAppSettingsRefreshed>(_onUserAppSettingsRefreshed);
    on<AppUserContentPreferencesRefreshed>(_onUserContentPreferencesRefreshed);
    on<AppSettingsChanged>(_onAppSettingsChanged);
    on<AppPeriodicConfigFetchRequested>(_onAppPeriodicConfigFetchRequested);
    on<AppVersionCheckRequested>(_onAppVersionCheckRequested);
    on<AppUserFeedDecoratorShown>(_onAppUserFeedDecoratorShown);
    on<AppUserContentPreferencesChanged>(_onAppUserContentPreferencesChanged);
    on<SavedFilterAdded>(_onSavedFilterAdded);
    on<SavedFilterUpdated>(_onSavedFilterUpdated);
    on<SavedFilterDeleted>(_onSavedFilterDeleted);
    on<SavedFiltersReordered>(_onSavedFiltersReordered);
    on<AppLogoutRequested>(_onLogoutRequested);

    // Subscribe to the authentication repository's authStateChanges stream.
    // This stream is the single source of truth for the user's auth state
    // and drives the entire app lifecycle.
    _userSubscription = _navigatorKey.currentContext!
        .read<AuthRepository>()
        .authStateChanges
        .listen((User? user) => add(AppUserChanged(user)));
  }

  final GlobalKey<NavigatorState> _navigatorKey;
  final Logger _logger;
  late final StreamSubscription<User?> _userSubscription;

  /// Provides access to the [NavigatorState] for obtaining a [BuildContext].
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// Fetches [UserAppSettings] and [UserContentPreferences] for the given
  /// [user] and updates the [AppState].
  ///
  /// This method centralizes the logic for loading user-specific data,
  /// ensuring consistency across different app lifecycle events.
  /// It also handles potential [HttpException]s during the fetch operation.

  /// Handles the [AppStarted] event, orchestrating the initial loading of
  /// user-specific data and evaluating the overall app status.
  Future<void> _onAppStarted(AppStarted event, Emitter<AppState> emit) async {
    // The AppStarted event is now a no-op. All initialization logic has been
    // moved to the AppInitializer and is processed in the AppBloc's constructor.
    // This event is kept for potential future use, such as re-initializing
    // the app after a critical error without a full restart.
    _logger.fine(
      '[AppBloc] AppStarted event received. State is already initialized.',
    );
  }

  /// Handles all logic related to user authentication state changes.
  ///
  /// This method is now simplified to only update the user and status based
  /// on the authentication stream, and handle data migration.
  Future<void> _onAppUserChanged(
    AppUserChanged event,
    Emitter<AppState> emit,
  ) async {
    final oldUser = state.user;
    final newUser = event.user;

    // Critical Change: Detect not just user ID changes, but also role changes.
    // This is essential for the "anonymous to authenticated" flow, where the
    // user ID might be the same, but the role changes from guest to standard.
    if (oldUser?.id == newUser?.id && oldUser?.appRole == newUser?.appRole) {
      _logger.info(
        '[AppBloc] AppUserChanged triggered, but user ID and role are the same. '
        'Skipping transition.',
      );
      return;
    }

    // If the user is null, it's a logout.
    if (newUser != null) {
      // handles its own data fetching after creating fixture data.
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

    // A user is present, so we are either logging in or transitioning roles.
    // Show a loading screen while we handle this process.
    emit(state.copyWith(status: AppLifeCycleStatus.loadingUserData));

    // Delegate the complex transition logic to the AppInitializer.
    final transitionResult = await _navigatorKey.currentContext!
        .read<AppInitializer>()
        .handleUserTransition(
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
            status: user.isGuest
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

    final settings = await _navigatorKey.currentContext!
        .read<DataRepository<UserAppSettings>>()
        .read(id: state.user!.id, userId: state.user!.id);
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

    final preferences = await _navigatorKey.currentContext!
        .read<DataRepository<UserContentPreferences>>()
        .read(id: state.user!.id, userId: state.user!.id);
    emit(state.copyWith(userContentPreferences: preferences));
  }

  /// Handles the [AppSettingsChanged] event, updating and persisting the
  /// user's application settings.
  ///
  /// This event is dispatched when any part of the user's settings (theme,
  /// font, language, etc.) is modified. The entire [UserAppSettings] object
  /// is updated and then persisted to the backend.
  Future<void> _onAppSettingsChanged(
    AppSettingsChanged event,
    Emitter<AppState> emit,
  ) async {
    // Ensure settings are loaded and a user is available before attempting to update.
    if (state.user == null || state.settings == null) {
      _logger.warning(
        '[AppBloc] Skipping AppSettingsChanged: User or UserAppSettings not loaded.',
      );
      return;
    }

    final updatedSettings = event.settings;

    // Optimistically update the state.
    emit(state.copyWith(settings: updatedSettings));

    try {
      await _navigatorKey.currentContext!
          .read<DataRepository<UserAppSettings>>()
          .update(
            id: updatedSettings.id,
            item: updatedSettings,
            userId: updatedSettings.id,
          );
      _logger.info(
        '[AppBloc] UserAppSettings successfully updated and persisted for user ${updatedSettings.id}.',
      );
    } on HttpException catch (e) {
      _logger.severe(
        'Failed to persist UserAppSettings for user ${updatedSettings.id} (HttpException): $e',
      );
      // Revert to original settings on failure to maintain state consistency
      emit(state.copyWith(settings: state.settings));
    } catch (e, s) {
      _logger.severe(
        'Unexpected error persisting UserAppSettings for user ${updatedSettings.id}.',
        e,
        s,
      );
      // Revert to original settings on failure to maintain state consistency
      emit(state.copyWith(settings: state.settings));
    }
  }

  /// Handles user logout request.
  void _onLogoutRequested(AppLogoutRequested event, Emitter<AppState> emit) {
    // The actual sign-out is now handled by the auth repository, which
    // will trigger the `authStateChanges` stream. This BLoC will then
    // receive an `AppUserChanged` event with a null user.
    unawaited(_navigatorKey.currentContext!.read<AuthRepository>().signOut());
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }

  /// Handles periodic fetching of the remote application configuration.
  ///
  /// This method is primarily used for re-fetching the remote configuration
  /// (e.g., by [AppStatusService] for background checks or by [StatusPage]
  /// for retries). The initial remote configuration is fetched during bootstrap.
  Future<void> _onAppPeriodicConfigFetchRequested(
    AppPeriodicConfigFetchRequested event,
    Emitter<AppState> emit,
  ) async {
    // This logic is now handled by AppStatusService and AppInitializer.
    // This event handler is kept for backward compatibility but is a no-op.
    _logger.fine('[AppBloc] AppPeriodicConfigFetchRequested is now a no-op.');
  }

  /// Handles the [AppVersionCheckRequested] event to enforce app version updates.
  Future<void> _onAppVersionCheckRequested(
    AppVersionCheckRequested event,
    Emitter<AppState> emit,
  ) async {
    // This logic is now handled by AppInitializer during startup.
    // This event handler is kept for backward compatibility but is a no-op.
    _logger.fine('[AppBloc] AppVersionCheckRequested is now a no-op.');
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
        await _navigatorKey.currentContext!.read<DataRepository<User>>().update(
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
        emit(state.copyWith(user: originalUser));
      }
    }
  }

  /// Handles updating the user's content preferences.
  ///
  /// This event is dispatched by UI components when the user modifies their
  /// followed countries, sources, topics, or saved headlines. The event
  /// carries the complete, updated [UserContentPreferences] object, which
  /// is then persisted to the backend.
  Future<void> _onAppUserContentPreferencesChanged(
    AppUserContentPreferencesChanged event,
    Emitter<AppState> emit,
  ) async {
    // Ensure a user is available before attempting to update preferences.
    if (state.user == null) {
      _logger.warning(
        '[AppBloc] Skipping AppUserContentPreferencesChanged: User is null.',
      );
      return;
    }

    final updatedPreferences = event.preferences;

    // Optimistically update the state.
    emit(state.copyWith(userContentPreferences: updatedPreferences));

    try {
      await _navigatorKey.currentContext!
          .read<DataRepository<UserContentPreferences>>()
          .update(
            id: updatedPreferences.id,
            item: updatedPreferences,
            userId: updatedPreferences.id,
          );
      _logger.info(
        '[AppBloc] UserContentPreferences successfully updated and persisted '
        'for user ${updatedPreferences.id}.',
      );
    } on HttpException catch (e) {
      _logger.severe(
        'Failed to persist UserContentPreferences for user ${updatedPreferences.id} '
        '(HttpException): $e',
      );
      // Revert to original preferences on failure to maintain state consistency.
      emit(
        state.copyWith(userContentPreferences: state.userContentPreferences),
      );
    } catch (e, s) {
      _logger.severe(
        'Unexpected error persisting UserContentPreferences for user ${updatedPreferences.id}.',
        e,
        s,
      );
      // Revert to original preferences on failure to maintain state consistency.
      emit(
        state.copyWith(userContentPreferences: state.userContentPreferences),
      );
    }
  }

  /// Handles adding a new saved filter to the user's content preferences.
  ///
  /// This method optimistically updates the state by dispatching an
  /// [AppUserContentPreferencesChanged] event, which will then handle
  /// persistence.
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
  ///
  /// This method finds the filter by its ID, replaces it with the updated
  /// version, and then dispatches an [AppUserContentPreferencesChanged] event
  /// to persist the changes.
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
  ///
  /// This method removes the filter by its ID and then dispatches an
  /// [AppUserContentPreferencesChanged] event to persist the changes.
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

    // Check if the list was actually modified to avoid unnecessary updates.
    if (updatedSavedFilters.length ==
        state.userContentPreferences!.savedFilters.length) {
      if (updatedSavedFilters.length ==
          state.userContentPreferences!.savedFilters.length) {
        _logger.warning(
          '[AppBloc] Skipping SavedFilterDeleted: Filter with id ${event.filterId} not found.',
        );
        return;
      }
    }

    final updatedPreferences = state.userContentPreferences!.copyWith(
      savedFilters: updatedSavedFilters,
    );

    add(AppUserContentPreferencesChanged(preferences: updatedPreferences));
  }

  /// Handles reordering the list of saved filters.
  ///
  /// This method receives the complete list of filters in their new order
  /// and dispatches an [AppUserContentPreferencesChanged] event to persist
  /// the change. This approach leverages the natural order of the list for
  /// persistence, avoiding the need for a separate 'order' property on the
  /// [SavedFilter] model.
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

    // Create an updated preferences object with the reordered list.
    final updatedPreferences = state.userContentPreferences!.copyWith(
      savedFilters: event.reorderedFilters,
    );

    // Dispatch the existing event to handle persistence and state updates.
    // This reuses the existing logic for updating user preferences.
    add(AppUserContentPreferencesChanged(preferences: updatedPreferences));
    _logger.info(
      '[AppBloc] Dispatched AppUserContentPreferencesChanged '
      'with reordered filters.',
    );
  }
}
