import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/initialization_result.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_initializer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/services/push_notification_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/extensions/extensions.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/app_review.dart';
import 'package:logging/logging.dart';

part 'app_event.dart';
part 'app_state.dart';

/// {@template app_bloc}
/// Manages the global state of the application *after* successful
/// initialization.
///
/// This BLoC is created only when the [AppInitializationBloc] succeeds. It
/// receives all the pre-fetched initial data (user, settings, remote config)
/// and becomes the single source of truth for the running application's state,
/// reacting to user authentication changes and managing user preferences.
/// {@endtemplate}
class AppBloc extends Bloc<AppEvent, AppState> {
  /// {@macro app_bloc}
  ///
  /// Initializes the BLoC with required repositories, environment, and
  /// pre-fetched initial data.
  AppBloc({
    required User? user,
    required RemoteConfig remoteConfig,
    required AppSettings? settings,
    required UserContentPreferences? userContentPreferences,
    required DataRepository<RemoteConfig> remoteConfigRepository,
    required AppInitializer appInitializer,
    required AuthRepository authRepository,
    required DataRepository<AppSettings> appSettingsRepository,
    required DataRepository<UserContentPreferences>
    userContentPreferencesRepository,
    required InlineAdCacheService inlineAdCacheService,
    required Logger logger,
    required DataRepository<User> userRepository,
    required PushNotificationService pushNotificationService,
    required DataRepository<InAppNotification> inAppNotificationRepository,
    required AppReviewService appReviewService,
  }) : _remoteConfigRepository = remoteConfigRepository,
       _appInitializer = appInitializer,
       _authRepository = authRepository,
       _appSettingsRepository = appSettingsRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _userRepository = userRepository,
       _inAppNotificationRepository = inAppNotificationRepository,
       _pushNotificationService = pushNotificationService,
       _appReviewService = appReviewService,
       _inlineAdCacheService = inlineAdCacheService,
       _logger = logger,
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
    on<AppSettingsRefreshed>(_onUserAppSettingsRefreshed);
    on<AppUserContentPreferencesRefreshed>(_onUserContentPreferencesRefreshed);
    on<AppSettingsChanged>(_onAppSettingsChanged);
    on<AppPeriodicConfigFetchRequested>(_onAppPeriodicConfigFetchRequested);
    on<AppUserFeedDecoratorShown>(_onAppUserFeedDecoratorShown);
    on<AppUserContentPreferencesChanged>(_onAppUserContentPreferencesChanged);
    on<SavedHeadlineFilterAdded>(_onSavedHeadlineFilterAdded);
    on<SavedHeadlineFilterUpdated>(_onSavedHeadlineFilterUpdated);
    on<SavedHeadlineFilterDeleted>(_onSavedHeadlineFilterDeleted);
    on<SavedHeadlineFiltersReordered>(_onSavedHeadlineFiltersReordered);
    on<AppPushNotificationDeviceRegistered>(
      _onAppPushNotificationDeviceRegistered,
    );
    on<AppLogoutRequested>(_onLogoutRequested);
    on<AppPushNotificationTokenRefreshed>(_onAppPushNotificationTokenRefreshed);
    on<AppInAppNotificationReceived>(_onAppInAppNotificationReceived);
    on<AppAllInAppNotificationsMarkedAsRead>(
      _onAllInAppNotificationsMarkedAsRead,
    );
    on<AppPositiveInteractionOcurred>(_onAppPositiveInteractionOcurred);
    on<AppInAppNotificationMarkedAsRead>(_onInAppNotificationMarkedAsRead);
    on<AppNotificationTapped>(_onAppNotificationTapped);

    // Listen to token refresh events from the push notification service.
    // When a token is refreshed, dispatch an event to trigger device
    // re-registration with the backend.
    _pushNotificationService.onTokenRefreshed.listen((_) {
      add(const AppPushNotificationTokenRefreshed());
    });

    // Listen to raw foreground push notifications.
    _pushNotificationService.onMessage.listen((payload) async {
      _logger.fine('AppBloc received foreground push notification payload.');
      // The backend now persists the notification when it sends the push. The
      // client's only responsibility is to react to the incoming message
      // and update the UI to show an unread indicator.
      add(const AppInAppNotificationReceived());
    });
  }

  final Logger _logger;
  final DataRepository<RemoteConfig> _remoteConfigRepository;
  final AppInitializer _appInitializer;
  final AuthRepository _authRepository;
  final DataRepository<AppSettings> _appSettingsRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final DataRepository<User> _userRepository;
  final DataRepository<InAppNotification> _inAppNotificationRepository;
  final PushNotificationService _pushNotificationService;
  final AppReviewService _appReviewService;
  final InlineAdCacheService _inlineAdCacheService;

  /// Handles the [AppStarted] event.
  ///
  /// This is now a no-op. All critical initialization logic has been moved to
  /// the [AppInitializer] service and is orchestrated by the
  /// [AppInitializationBloc] *before* this AppBloc is ever created.
  Future<void> _onAppStarted(AppStarted event, Emitter<AppState> emit) async {
    _logger.fine(
      '[AppBloc] AppStarted event received. State is already initialized.',
    );

    // If a user is already logged in when the app starts, register their
    // device for push notifications.
    if (state.user != null) {
      // Check for existing unread notifications on startup.
      // This ensures the notification dot is shown correctly if the user
      // has unread notifications from a previous session.
      try {
        final unreadCount = await _inAppNotificationRepository.count(
          userId: state.user!.id,
          filter: {'readAt': null},
        );
        if (unreadCount > 0) {
          emit(state.copyWith(hasUnreadInAppNotifications: true));
        }
      } catch (e, s) {
        _logger.severe(
          'Failed to check for unread notifications on app start.',
          e,
          s,
        );
      }
      await _registerDeviceForPushNotifications(state.user!.id);
    }
  }

  /// Handles all logic related to user authentication state changes.
  ///
  /// This method is the reactive entry point for handling a user logging in,
  /// logging out, or transitioning from an anonymous to an authenticated
  /// state while the app is running. It is triggered by the `AppUserChanged`
  /// event, which is dispatched in response to the `AuthRepository`'s
  /// `authStateChanges` stream.
  ///
  /// **Responsibilities:**
  /// 1.  **Manages UI State:** It immediately emits a `loadingUserData` status
  ///     to inform the UI to show a loading indicator, providing immediate
  ///     feedback to the user.
  /// 2.  **Delegates Complex Logic:** It does NOT perform the data fetching
  ///     or migration itself. Instead, it delegates this complex, critical
  ///     work to the `AppInitializer.handleUserTransition` method. This keeps
  ///     the BLoC clean and respects the single responsibility of the
  ///     `AppInitializer`.
  /// 3.  **Updates Final State:** Based on the `InitializationResult` returned
  ///     by the `AppInitializer`, it emits the final state, either with the
  ///     newly hydrated user data or with a critical error.
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
      // When logging out, it's crucial to explicitly clear all user-related
      // data to ensure a clean state for the next session. This prevents
      // stale data from causing issues on subsequent logins.
      _inlineAdCacheService.clearAllAds();

      emit(
        state.copyWith(
          status: AppLifeCycleStatus.unauthenticated,
          clearUser: true,
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
        // On a successful transition, update the state with the newly
        // fetched user data. The status is determined by the user's role
        // (guest or standard). Any previous error state is cleared.
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

        // After any successful user transition (including guest), attempt to
        // register their device for push notifications. This ensures that
        // guests can also receive notifications.
        await _registerDeviceForPushNotifications(user.id);
      // If the transition fails (e.g., due to a network error while
      // fetching user data), emit a critical error state.
      case InitializationFailure(:final status, :final error):
        emit(state.copyWith(status: status, error: error));
    }
  }

  /// Handles refreshing/loading app settings (theme, font).
  Future<void> _onUserAppSettingsRefreshed(
    AppSettingsRefreshed event,
    Emitter<AppState> emit,
  ) async {
    if (state.user == null) {
      _logger.info('[AppBloc] Skipping AppSettingsRefreshed: User is null.');
      return;
    }

    final settings = await _appSettingsRepository.read(
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
        '[AppBloc] Skipping AppSettingsChanged: User or AppSettings not loaded.',
      );
      return;
    }

    final updatedSettings = event.settings;
    // Optimistically update the UI with the new settings immediately.
    // This provides a responsive user experience. The original settings are
    // saved in case the persistence fails and we need to roll back.
    final originalSettings = state.settings;
    emit(state.copyWith(settings: updatedSettings));

    try {
      await _appSettingsRepository.update(
        id: updatedSettings.id,
        item: updatedSettings,
        userId: updatedSettings.id,
      );
      _logger.info(
        '[AppBloc] AppSettings successfully updated for user ${updatedSettings.id}.',
      );
    } catch (e, s) {
      _logger.severe(
        'Failed to persist AppSettings for user ${updatedSettings.id}.',
        e,
        s,
      );
      // If persistence fails, roll back the state to the original settings
      // to keep the UI consistent with the backend state.
      emit(state.copyWith(settings: originalSettings));
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

      if (remoteConfig.app.maintenance.isUnderMaintenance) {
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
          !remoteConfig.app.maintenance.isUnderMaintenance) {
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
        // Always update the last shown timestamp.
        lastShownAt: now,
        // If the event marks it as completed, it should be completed.
        // Otherwise, respect the existing completion status. This prevents
        // a non-completed event from overriding a completed one.
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
    // Optimistically update the UI with the new preferences.
    // The original preferences are saved for potential rollback on failure.
    final originalPreferences = state.userContentPreferences;
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
      // If persistence fails, roll back the state to the original preferences.
      emit(state.copyWith(userContentPreferences: originalPreferences));
    }
  }

  /// Handles adding a new saved headline filter to the user's content
  /// preferences.
  Future<void> _onSavedHeadlineFilterAdded(
    SavedHeadlineFilterAdded event,
    Emitter<AppState> emit,
  ) async {
    _logger.fine(
      '[AppBloc] SavedHeadlineFilterAdded event received for filter: '
      '"${event.filter.name}".',
    );
    // This method modifies the preferences in memory and then delegates the
    // persistence and final state update to the AppUserContentPreferencesChanged event.
    if (state.userContentPreferences == null) {
      _logger.warning(
        '[AppBloc] Skipping SavedHeadlineFilterAdded: UserContentPreferences '
        'not loaded.',
      );
      return;
    }

    final updatedSavedFilters = List<SavedHeadlineFilter>.from(
      state.userContentPreferences!.savedHeadlineFilters,
    )..add(event.filter);

    final updatedPreferences = state.userContentPreferences!.copyWith(
      savedHeadlineFilters: updatedSavedFilters,
    );

    add(AppUserContentPreferencesChanged(preferences: updatedPreferences));
  }

  /// Handles updating an existing saved headline filter (e.g., renaming it).
  Future<void> _onSavedHeadlineFilterUpdated(
    SavedHeadlineFilterUpdated event,
    Emitter<AppState> emit,
  ) async {
    _logger.fine(
      '[AppBloc] SavedHeadlineFilterUpdated event received for filter id: '
      '${event.filter.id}.',
    );
    // This method modifies the preferences in memory and then delegates the
    // persistence and final state update to the AppUserContentPreferencesChanged event.
    if (state.userContentPreferences == null) {
      _logger.warning(
        '[AppBloc] Skipping SavedHeadlineFilterUpdated: '
        'UserContentPreferences not loaded.',
      );
      return;
    }

    final originalFilters = state.userContentPreferences!.savedHeadlineFilters;
    final index = originalFilters.indexWhere((f) => f.id == event.filter.id);

    if (index == -1) {
      _logger.warning(
        '[AppBloc] Skipping SavedHeadlineFilterUpdated: Filter with id '
        '${event.filter.id} not found.',
      );
      return;
    }

    final updatedSavedFilters = List<SavedHeadlineFilter>.from(originalFilters)
      ..[index] = event.filter;

    final updatedPreferences = state.userContentPreferences!.copyWith(
      savedHeadlineFilters: updatedSavedFilters,
    );

    add(AppUserContentPreferencesChanged(preferences: updatedPreferences));
  }

  /// Handles deleting a saved headline filter from the user's content
  /// preferences.
  Future<void> _onSavedHeadlineFilterDeleted(
    SavedHeadlineFilterDeleted event,
    Emitter<AppState> emit,
  ) async {
    _logger.fine(
      '[AppBloc] SavedHeadlineFilterDeleted event received for filter id: '
      '${event.filterId}.',
    );
    // This method modifies the preferences in memory and then delegates the
    // persistence and final state update to the AppUserContentPreferencesChanged event.
    if (state.userContentPreferences == null) {
      _logger.warning(
        '[AppBloc] Skipping SavedHeadlineFilterDeleted: '
        'UserContentPreferences not loaded.',
      );
      return;
    }

    final updatedSavedFilters = List<SavedHeadlineFilter>.from(
      state.userContentPreferences!.savedHeadlineFilters,
    )..removeWhere((f) => f.id == event.filterId);

    if (updatedSavedFilters.length ==
        state.userContentPreferences!.savedHeadlineFilters.length) {
      _logger.warning(
        '[AppBloc] Skipping SavedHeadlineFilterDeleted: Filter with id '
        '${event.filterId} not found.',
      );
      return;
    }

    final updatedPreferences = state.userContentPreferences!.copyWith(
      savedHeadlineFilters: updatedSavedFilters,
    );

    add(AppUserContentPreferencesChanged(preferences: updatedPreferences));
  }

  /// Handles reordering the list of saved headline filters.
  Future<void> _onSavedHeadlineFiltersReordered(
    SavedHeadlineFiltersReordered event,
    Emitter<AppState> emit,
  ) async {
    _logger.fine('[AppBloc] SavedHeadlineFiltersReordered event received.');
    // This method modifies the preferences in memory and then delegates the
    // persistence and final state update to the AppUserContentPreferencesChanged event.
    if (state.userContentPreferences == null) {
      _logger.warning(
        '[AppBloc] Skipping SavedHeadlineFiltersReordered: '
        'UserContentPreferences not loaded.',
      );
      return;
    }

    final updatedPreferences = state.userContentPreferences!.copyWith(
      savedHeadlineFilters: event.reorderedFilters,
    );

    add(AppUserContentPreferencesChanged(preferences: updatedPreferences));
    _logger.info(
      '[AppBloc] Dispatched AppUserContentPreferencesChanged '
      'with reordered filters.',
    );
  }

  /// Handles the [AppPushNotificationDeviceRegistered] event.
  ///
  /// This handler is primarily for logging and does not change the state.
  void _onAppPushNotificationDeviceRegistered(
    AppPushNotificationDeviceRegistered event,
    Emitter<AppState> emit,
  ) {
    _logger.info('[AppBloc] Push notification device registration noted.');
  }

  /// Handles the [AppInAppNotificationReceived] event.
  ///
  /// This handler updates the state to indicate that a new, unread in-app
  /// notification has been received, which can be used to show a UI indicator.
  void _onAppInAppNotificationReceived(
    AppInAppNotificationReceived event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(hasUnreadInAppNotifications: true));
  }

  /// Handles the [AppAllInAppNotificationsMarkedAsRead] event.
  ///
  /// This handler is responsible for resetting the global unread notification
  /// indicator when all notifications have been marked as read.
  Future<void> _onAllInAppNotificationsMarkedAsRead(
    AppAllInAppNotificationsMarkedAsRead event,
    Emitter<AppState> emit,
  ) async {
    // After marking all as read, we can confidently set the flag to false.
    emit(state.copyWith(hasUnreadInAppNotifications: false));
  }

  /// Handles the [AppInAppNotificationMarkedAsRead] event.
  ///
  /// This handler checks if there are any remaining unread notifications after
  /// one has been marked as read. If no unread notifications are left, it
  /// resets the global unread indicator.
  Future<void> _onInAppNotificationMarkedAsRead(
    AppInAppNotificationMarkedAsRead event,
    Emitter<AppState> emit,
  ) async {
    if (state.user == null) return;

    try {
      final unreadCount = await _inAppNotificationRepository.count(
        userId: state.user!.id,
        filter: {'readAt': null},
      );

      if (unreadCount == 0) {
        emit(state.copyWith(hasUnreadInAppNotifications: false));
      }
    } catch (e, s) {
      _logger.severe(
        'Failed to check for remaining unread notifications.',
        e,
        s,
      );
      // Do not change state on error to avoid inconsistent UI.
    }
  }

  /// Handles marking a specific notification as read when it's tapped.
  Future<void> _onAppNotificationTapped(
    AppNotificationTapped event,
    Emitter<AppState> emit,
  ) async {
    final userId = state.user?.id;
    if (userId == null) {
      _logger.warning(
        '[AppBloc] Cannot mark notification as read: user is not logged in.',
      );
      return;
    }

    try {
      // First, read the existing notification to get the full object.
      final notification = await _inAppNotificationRepository.read(
        id: event.notificationId,
        userId: userId,
      );

      // If already read, do nothing.
      if (notification.isRead) return;

      // Then, update it with the 'readAt' timestamp.
      await _inAppNotificationRepository.update(
        id: notification.id,
        item: notification.copyWith(readAt: DateTime.now()),
        userId: userId,
      );

      _logger.info(
        '[AppBloc] Marked notification ${event.notificationId} as read.',
      );
    } catch (e, s) {
      _logger.severe('Failed to mark notification as read.', e, s);
    }
  }

  /// Handles the [AppPositiveInteractionOcurred] event.
  ///
  /// This handler increments the user's positive interaction count and then
  /// delegates to the [AppReviewService] to check if a review prompt should
  /// be shown.
  Future<void> _onAppPositiveInteractionOcurred(
    AppPositiveInteractionOcurred event,
    Emitter<AppState> emit,
  ) async {
    await _appReviewService.incrementPositiveInteractionCount();
    await _appReviewService.checkEligibilityAndTrigger(
      context: event.context,
    );
  }

  /// Handles the [AppPushNotificationTokenRefreshed] event.
  ///
  /// This event is triggered when the underlying push notification provider
  /// (e.g., FCM, OneSignal) refreshes its device token. The AppBloc then
  /// attempts to re-register the device with the backend using the current
  /// user's ID.
  Future<void> _onAppPushNotificationTokenRefreshed(
    AppPushNotificationTokenRefreshed event,
    Emitter<AppState> emit,
  ) async {
    if (state.user == null) {
      _logger.info('[AppBloc] Skipping token re-registration: User is null.');
      return;
    }
    _logger.info(
      '[AppBloc] Push notification token refreshed. Re-registering device.',
    );
    await _registerDeviceForPushNotifications(state.user!.id);
  }

  /// A private helper method to encapsulate the logic for registering a
  /// device for push notifications.
  ///
  /// This method is called from multiple places (`_onAppStarted`,
  /// `_onAppUserChanged`, `_onAppPushNotificationTokenRefreshed`) to avoid
  /// code duplication. It includes robust error handling to prevent unhandled
  /// exceptions from crashing the BLoC.
  Future<void> _registerDeviceForPushNotifications(String userId) async {
    _logger.info(
      '[AppBloc] Attempting to register device for push notifications for user $userId.',
    );
    try {
      // The PushNotificationService handles getting the token and calling the
      // repository's create method. The `registerDevice` method implements a
      // "delete-then-create" pattern for idempotency.
      await _pushNotificationService.registerDevice(userId: userId);
      add(const AppPushNotificationDeviceRegistered());
    } catch (e, s) {
      _logger.severe(
        '[AppBloc] Failed to register push notification device for user $userId.',
        e,
        s,
      );
    }
  }
}
