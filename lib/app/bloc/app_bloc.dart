import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/initialization_result.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_initializer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/services/feed_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/services/push_notification_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/services/app_review_service.dart';
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
    required UserContext? userContext,
    required RemoteConfig remoteConfig,
    required AppSettings? settings,
    required UserContentPreferences? userContentPreferences,
    required UserRewards? userRewards,
    required DataRepository<RemoteConfig> remoteConfigRepository,
    required AppInitializer appInitializer,
    required AuthRepository authRepository,
    required DataRepository<AppSettings> appSettingsRepository,
    required DataRepository<UserContentPreferences>
    userContentPreferencesRepository,
    required DataRepository<UserContext> userContextRepository,
    required InlineAdCacheService inlineAdCacheService,
    required FeedCacheService feedCacheService,
    required Logger logger,
    required PushNotificationService pushNotificationService,
    required DataRepository<Report> reportRepository,
    required ContentLimitationService contentLimitationService,
    required DataRepository<InAppNotification> inAppNotificationRepository,
    required AppReviewService appReviewService,
    required AnalyticsService analyticsService,
    required DataRepository<UserRewards> userRewardsRepository,
  }) : _remoteConfigRepository = remoteConfigRepository,
       _appInitializer = appInitializer,
       _authRepository = authRepository,
       _appSettingsRepository = appSettingsRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _userContextRepository = userContextRepository,
       _inAppNotificationRepository = inAppNotificationRepository,
       _feedCacheService = feedCacheService,
       _pushNotificationService = pushNotificationService,
       _reportRepository = reportRepository,
       _contentLimitationService = contentLimitationService,
       _appReviewService = appReviewService,
       _inlineAdCacheService = inlineAdCacheService,
       _analyticsService = analyticsService,
       _userRewardsRepository = userRewardsRepository,
       _logger = logger,
       super(
         AppState(
           status: user == null
               ? AppLifeCycleStatus.unauthenticated
               : user.isAnonymous
               ? AppLifeCycleStatus.anonymous
               : AppLifeCycleStatus.authenticated,
           user: user,
           userContext: userContext,
           remoteConfig: remoteConfig,
           settings: settings,
           userContentPreferences: userContentPreferences,
           userRewards: userRewards,
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
    on<AppBookmarkToggled>(_onAppBookmarkToggled);
    on<AppContentReported>(_onAppContentReported);
    on<UserRewardsRefreshed>(_onUserRewardsRefreshed);

    // Listen to token refresh events from the push notification service.
    // When a token is refreshed, dispatch an event to trigger device
    // re-registration with the backend.
    _pushNotificationService.onTokenRefreshed.listen((_) {
      add(const AppPushNotificationTokenRefreshed());
    });

    // Listen to raw foreground push notifications.
    _pushNotificationService.onMessage.listen((payload) async {
      _logger
        ..fine('AppBloc received foreground push notification payload.')
        ..info(
          '[AppBloc] Received foreground push notification: ${payload.notificationId}',
        );
      // The backend persists the notification when it sends the push. The
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
  final DataRepository<UserContext> _userContextRepository;
  final DataRepository<InAppNotification> _inAppNotificationRepository;
  final PushNotificationService _pushNotificationService;
  final DataRepository<Report> _reportRepository;
  final ContentLimitationService _contentLimitationService;
  final AppReviewService _appReviewService;
  final InlineAdCacheService _inlineAdCacheService;
  final FeedCacheService _feedCacheService;
  final AnalyticsService _analyticsService;
  final DataRepository<UserRewards> _userRewardsRepository;

  /// Handles the [AppStarted] event.
  ///
  /// This event is a no-op as critical initialization logic is handled by
  /// [AppInitializer] and [AppInitializationBloc] before AppBloc creation.
  Future<void> _onAppStarted(AppStarted event, Emitter<AppState> emit) async {
    _logger.fine(
      '[AppBloc] AppStarted event received. State is already initialized.',
    );

    // If a user is already logged in when the app starts, prepare for push
    // notifications.
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

      // Ensure we have permission before attempting to register the device.
      // On modern Android, getToken() will return null without permission.
      try {
        final hasPermission = await _pushNotificationService.hasPermission();
        if (hasPermission ||
            await _pushNotificationService.requestPermission()) {
          await _registerDeviceForPushNotifications(state.user!.id);
        } else {
          _logger.warning(
            '[AppBloc] Push notification permission not granted.',
          );
        }
      } catch (e, s) {
        _logger.severe(
          '[AppBloc] Failed to process push notification permissions.',
          e,
          s,
        );
      }
    }
  }

  Future<void> _onUserRewardsRefreshed(
    UserRewardsRefreshed event,
    Emitter<AppState> emit,
  ) async {
    final oldRewards = state.userRewards;
    final userId = state.user?.id;
    if (userId == null) {
      event.completer?.complete(null);
      return;
    }

    _logger.info('[AppBloc] Refreshing user rewards...');

    try {
      final newRewards = await _userRewardsRepository.read(
        userId: userId,
        id: userId,
      );

      // Verify data integrity. Ensure the received rewards object
      // belongs to the currently logged-in user.
      if (newRewards.userId != userId) {
        _logger.severe(
          '[AppBloc] CRITICAL DATA MISMATCH: Fetched UserRewards for user '
          '${newRewards.userId}, but current user is $userId. Halting update. '
          'This is likely a server-side bug where the API is not filtering by userId.',
        );
        // Complete the completer with an error to halt the polling loop in the
        // RewardsBloc and prevent further incorrect processing.
        event.completer?.completeError(
          Exception('Mismatched user data received from server.'),
        );
        return;
      }

      // Determine which rewards have become newly active.
      final newlyActivatedRewards = <RewardType>{};
      for (final type in RewardType.values) {
        final wasActive = oldRewards?.isRewardActive(type) ?? false;
        final isNowActive = newRewards.isRewardActive(type);
        if (isNowActive && !wasActive) {
          newlyActivatedRewards.add(type);
        }
      }

      // Trigger side effects for newly activated rewards.
      for (final rewardType in newlyActivatedRewards) {
        if (rewardType == RewardType.adFree) {
          _logger.info(
            '[AppBloc] Ad-Free reward activated. Clearing ad and feed caches.',
          );
          _inlineAdCacheService.clearAllAds();
          _feedCacheService.clearAll();
          // The HeadlinesFeedBloc listens for the AppState change and will
          // trigger its own refresh, which will then use the new ad-free
          // status to correctly rebuild the feed without ads. This is a clean,
          // decoupled way to trigger the UI update.
        }
      }

      emit(state.copyWith(userRewards: newRewards));
      _logger.info('[AppBloc] User rewards refreshed successfully.');
      event.completer?.complete(newRewards);
    } catch (e, s) {
      _logger.severe('[AppBloc] Failed to refresh user rewards.', e, s);
      event.completer?.completeError(e, s);
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

    // Detect not just user ID changes, but also role changes.
    // This is essential for the "anonymous to authenticated" flow.
    if (oldUser?.id == newUser?.id &&
        oldUser?.role == newUser?.role &&
        oldUser?.tier == newUser?.tier &&
        oldUser?.isAnonymous == newUser?.isAnonymous) {
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
      // Also clear the feed cache to ensure the next user (or a new anonymous
      // session) gets fresh data instead of seeing the previous user's feed.
      _feedCacheService.clearAll();
      _logger.info('[AppBloc] Cleared inline ad and feed caches on logout.');

      emit(
        state.copyWith(
          status: AppLifeCycleStatus.unauthenticated,
          clearUser: true,
        ),
      );
      return;
    }

    // If the user is changing (e.g., anonymous to authenticated), clear caches
    // to prevent showing stale data from the previous user session.
    if (oldUser != null && oldUser.id != newUser.id) {
      _inlineAdCacheService.clearAllAds();
      _feedCacheService.clearAll();
      _logger.info(
        '[AppBloc] User changed from ${oldUser.id} to ${newUser.id}. '
        'Cleared inline ad and feed caches.',
      );
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
        :final userContext,
        :final userRewards,
      ):
        emit(
          state.copyWith(
            status: user!.isAnonymous
                ? AppLifeCycleStatus.anonymous
                : AppLifeCycleStatus.authenticated,
            user: user,
            userContext: userContext,
            settings: settings,
            userContentPreferences: userContentPreferences,
            userRewards: userRewards,
            clearError: true,
          ),
        );

        // Analytics: Track user role changes
        if (oldUser != null && oldUser.role != user.role) {
          unawaited(
            _analyticsService.logEvent(
              AnalyticsEvent.userRoleChanged,
              payload: UserRoleChangedPayload(
                fromRole: oldUser.role,
                toRole: user.role,
              ),
            ),
          );
        }

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
    final originalSettings = state.settings!;

    // Analytics: Track setting changes
    if (updatedSettings.displaySettings.baseTheme !=
            originalSettings.displaySettings.baseTheme ||
        updatedSettings.displaySettings.accentTheme !=
            originalSettings.displaySettings.accentTheme) {
      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.themeChanged,
          payload: ThemeChangedPayload(
            baseTheme: updatedSettings.displaySettings.baseTheme,
            accentTheme: updatedSettings.displaySettings.accentTheme,
          ),
        ),
      );
    }

    if (updatedSettings.language.code != originalSettings.language.code) {
      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.languageChanged,
          payload: LanguageChangedPayload(
            languageCode: updatedSettings.language.code,
          ),
        ),
      );
    }

    if (updatedSettings.feedSettings.feedItemDensity !=
        originalSettings.feedSettings.feedItemDensity) {
      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.feedDensityChanged,
          payload: FeedDensityChangedPayload(
            density: updatedSettings.feedSettings.feedItemDensity,
          ),
        ),
      );
    }

    if (updatedSettings.feedSettings.feedItemClickBehavior !=
        originalSettings.feedSettings.feedItemClickBehavior) {
      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.browserChoiceChanged,
          payload: BrowserChoiceChangedPayload(
            browserType: updatedSettings.feedSettings.feedItemClickBehavior,
          ),
        ),
      );
    }

    // Optimistically update the UI with the new settings immediately.
    // This provides a responsive user experience. The original settings are
    // saved in case the persistence fails and we need to roll back.
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
            : (state.user!.isAnonymous
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
    if (state.userContext != null &&
        state.userContext!.userId == event.userId) {
      final originalContext = state.userContext!;
      final now = DateTime.now();
      final currentStatus =
          originalContext.feedDecoratorStatus[event.feedDecoratorType] ??
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
            //
            originalContext.feedDecoratorStatus,
          )..update(
            event.feedDecoratorType,
            (_) => updatedDecoratorStatus,
            ifAbsent: () => updatedDecoratorStatus,
          );

      final updatedContext = originalContext.copyWith(
        feedDecoratorStatus: newFeedDecoratorStatus,
      );

      emit(state.copyWith(userContext: updatedContext));

      try {
        await _userContextRepository.update(
          id: updatedContext.userId,
          item: updatedContext,
          userId: updatedContext.userId,
        );
        _logger.info(
          '[AppBloc] User ${event.userId} FeedDecorator ${event.feedDecoratorType} '
          'status successfully updated.',
        );
      } catch (e) {
        _logger.severe('Failed to update feed decorator status: $e');
        emit(state.copyWith(userContext: originalContext));
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

    // Analytics: Track filter creation
    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvent.headlineFilterCreated,
        payload: HeadlineFilterCreatedPayload(
          filterId: event.filter.id,
          criteriaSummary: HeadlineFilterCriteriaSummary.fromCriteria(
            event.filter.criteria,
          ),
          isPinned: event.filter.isPinned,
          deliveryTypes: event.filter.deliveryTypes,
        ),
      ),
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

    // Analytics: Track filter update
    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvent.headlineFilterUpdated,
        payload: HeadlineFilterUpdatedPayload(
          filterId: event.filter.id,
          newName: event.filter.name,
          pinStatusChangedTo: event.filter.isPinned,
          newCriteriaSummary: HeadlineFilterCriteriaSummary.fromCriteria(
            event.filter.criteria,
          ),
        ),
      ),
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
    _logger.info(
      '[AppBloc] Set hasUnreadInAppNotifications to true due to incoming notification.',
    );
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
    _logger.info(
      '[AppBloc] Set hasUnreadInAppNotifications to false after marking all as read.',
    );
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
    _logger.fine(
      '[AppBloc] AppInAppNotificationMarkedAsRead event received. Checking remaining unread count.',
    );
    if (state.user == null) return;

    try {
      final unreadCount = await _inAppNotificationRepository.count(
        userId: state.user!.id,
        filter: {'readAt': null},
      );

      if (unreadCount == 0) {
        _logger.info(
          '[AppBloc] No unread notifications remaining. Setting hasUnreadInAppNotifications to false.',
        );
        emit(state.copyWith(hasUnreadInAppNotifications: false));
      } else {
        _logger.fine('[AppBloc] $unreadCount unread notifications remain.');
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
    _logger.info(
      '[AppBloc] AppNotificationTapped event received for notification: ${event.notificationId}',
    );
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
      if (notification.isRead) {
        _logger.fine(
          '[AppBloc] Notification ${event.notificationId} was already read. No action taken.',
        );
        return;
      }

      // Then, update it with the 'readAt' timestamp.
      await _inAppNotificationRepository.update(
        id: notification.id,
        item: notification.copyWith(readAt: DateTime.now()),
        userId: userId,
      );

      _logger.info(
        '[AppBloc] Marked notification ${event.notificationId} as read.',
      );

      // After successfully marking as read, dispatch an event to re-evaluate
      // the total unread count and update the global indicator if necessary.
      add(const AppInAppNotificationMarkedAsRead());
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
    final newCount = state.positiveInteractionCount + 1;
    await _appReviewService.checkEligibilityAndTrigger(
      context: event.context,
      positiveInteractionCount: newCount,
    );
    // The count only updated after the eligibility check is complete.
    emit(state.copyWith(positiveInteractionCount: newCount));
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

  Future<void> _onAppBookmarkToggled(
    AppBookmarkToggled event,
    Emitter<AppState> emit,
  ) async {
    final userContentPreferences = state.userContentPreferences;
    if (userContentPreferences == null) return;

    final currentSaved = List<Headline>.from(
      userContentPreferences.savedHeadlines,
    );

    if (event.isBookmarked) {
      currentSaved.removeWhere((h) => h.id == event.headline.id);
      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.contentUnsaved,
          payload: ContentUnsavedPayload(contentId: event.headline.id),
        ),
      );
    } else {
      final limitationStatus = await _contentLimitationService.checkAction(
        ContentAction.bookmarkHeadline,
      );

      if (limitationStatus != LimitationStatus.allowed) {
        emit(
          state.copyWith(
            limitationStatus: limitationStatus,
            limitedAction: ContentAction.bookmarkHeadline,
          ),
        );
        emit(state.copyWith(clearLimitedAction: true));
        return;
      }
      currentSaved.insert(0, event.headline);
      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.contentSaved,
          payload: ContentSavedPayload(contentId: event.headline.id),
        ),
      );
      add(AppPositiveInteractionOcurred(context: event.context));
    }

    add(
      AppUserContentPreferencesChanged(
        preferences: userContentPreferences.copyWith(
          savedHeadlines: currentSaved,
        ),
      ),
    );
  }

  Future<void> _onAppContentReported(
    AppContentReported event,
    Emitter<AppState> emit,
  ) async {
    final limitationStatus = await _contentLimitationService.checkAction(
      ContentAction.submitReport,
    );

    if (limitationStatus != LimitationStatus.allowed) {
      emit(
        state.copyWith(
          limitationStatus: limitationStatus,
          limitedAction: ContentAction.submitReport,
        ),
      );
      emit(state.copyWith(clearLimitedAction: true));
      return;
    }

    try {
      await _reportRepository.create(item: event.report);
      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.reportSubmitted,
          payload: ReportSubmittedPayload(
            entityType: event.report.entityType,
            entityId: event.report.entityId,
            reason: event.report.reason,
          ),
        ),
      );
    } catch (e, s) {
      _logger.severe('Failed to submit report in AppBloc', e, s);
      // Optionally emit a failure state to show a snackbar.
    }
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
