import 'dart:async';
import 'dart:math';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:logging/logging.dart';

/// Defines the specific type of content-related action a user is trying to
/// perform, which may be subject to limitations.
enum ContentAction {
  /// The action of bookmarking a headline.
  bookmarkHeadline,

  /// The action of following a topic.
  followTopic,

  /// The action of following a source.
  followSource,

  /// The action of following a country.
  followCountry,

  /// The action of saving a filter.
  saveFilter,

  /// The action of pinning a filter.
  pinFilter,

  /// The action of subscribing to notifications for a saved filter.
  subscribeToSavedFilterNotifications,

  /// The action of posting a comment.
  postComment,

  /// The action of reacting to a piece of content.
  reactToContent,

  /// The action of submitting a report.
  submitReport,

  /// The action of editing a user's profile.
  editProfile,
}

/// Defines the outcome of a content limitation check.
enum LimitationStatus {
  /// The user is permitted to perform the action.
  allowed,

  /// The user has reached the content limit for anonymous (guest) users.
  anonymousLimitReached,

  /// The user has reached the content limit for standard (free) users.
  standardUserLimitReached,
}

/// Defines the initialization status of the daily count cache.
enum _CacheInitializationStatus { pending, succeeded, failed }

/// {@template content_limitation_service}
/// A service that centralizes the logic for checking if a user can perform
/// a content-related action based on their role and remote configuration limits.
///
/// This service acts as the single source of truth for content limitations,
/// ensuring that rules are applied consistently throughout the application.
///
/// It is a stateful, caching service that proactively fetches daily action
/// counts for the current user to provide fast, client-side limit checks.
/// It is designed to be resilient, failing open if the initial count fetch fails.
/// {@endtemplate}
class ContentLimitationService {
  /// {@macro content_limitation_service}
  ContentLimitationService({
    required DataRepository<Engagement> engagementRepository,
    required DataRepository<Report> reportRepository,
    required AnalyticsService analyticsService,
    required Duration cacheDuration,
    required Logger logger,
  }) : _engagementRepository = engagementRepository,
       _reportRepository = reportRepository,
       _analyticsService = analyticsService,
       _cacheDuration = cacheDuration,
       _logger = logger;

  final DataRepository<Engagement> _engagementRepository;
  final DataRepository<Report> _reportRepository;
  final AnalyticsService _analyticsService;
  final Duration _cacheDuration;
  final Logger _logger;

  late final AppBloc _appBloc;
  StreamSubscription<AppState>? _appBlocSubscription;
  Future<void>? _fetchDailyCountsFuture;

  // Internal cache for daily action counts.
  int? _commentCount;
  int? _reactionCount;
  int? _reportCount;
  DateTime? _countsLastFetchedAt;
  _CacheInitializationStatus _initializationStatus =
      _CacheInitializationStatus.pending;
  String? _cachedForUserId;
  int _retryAttempt = 0;

  /// Initializes the service by subscribing to AppBloc state changes.
  ///
  /// This triggers the proactive fetching of daily action counts whenever the
  /// user's authentication state changes.
  void init({required AppBloc appBloc}) {
    _logger.info('ContentLimitationService initializing...');
    _appBloc = appBloc;
    _appBlocSubscription = appBloc.stream.listen(_onAppStateChanged);
    // Trigger initial fetch if a user is already present.
    if (appBloc.state.user != null) {
      _fetchDailyCountsFuture = _fetchDailyCounts(appBloc.state.user!.id);
      unawaited(_fetchDailyCountsFuture);
    }
  }

  /// Disposes of the service, cancelling any active subscriptions.
  void dispose() {
    _logger.info('ContentLimitationService disposing...');
    _appBlocSubscription?.cancel();
  }

  void _onAppStateChanged(AppState appState) {
    final newUserId = appState.user?.id;

    // If the user ID has changed (login/logout/transition), clear the cache
    // and potentially trigger a new fetch.
    if (newUserId != _cachedForUserId) {
      _logger.info(
        'User changed from $_cachedForUserId to $newUserId. '
        'Clearing daily action count cache.',
      );
      _clearCache();
      if (newUserId != null) {
        _fetchDailyCountsFuture = _fetchDailyCounts(newUserId);
        unawaited(_fetchDailyCountsFuture);
      }
    }
  }

  /// Resets all cached daily counts and status indicators.
  void _clearCache() {
    _commentCount = null;
    _reactionCount = null;
    _reportCount = null;
    _countsLastFetchedAt = null;
    _cachedForUserId = null;
    _initializationStatus = _CacheInitializationStatus.pending;
    _retryAttempt = 0;
    _fetchDailyCountsFuture = null;
  }

  /// Fetches the daily action counts (reactions, comments, reports) for a
  /// given user by querying all relevant records from the last 24 hours and
  /// counting them locally. This works around the unimplemented `count` method.
  Future<void> _fetchDailyCounts(String userId) async {
    _logger.info('Attempting to fetch daily action counts for user $userId...');
    _cachedForUserId = userId;
    _initializationStatus = _CacheInitializationStatus.pending;

    try {
      final twentyFourHoursAgo = DateTime.now().subtract(
        const Duration(hours: 24),
      );

      // Use readAll to fetch all pages of engagements and reports.
      final [engagementItems, reportItems] = await Future.wait([
        _fetchAllPaginatedItems(_engagementRepository, userId, {
          'createdAt': {r'$gte': twentyFourHoursAgo.toIso8601String()},
        }),
        _fetchAllPaginatedItems(_reportRepository, userId, {
          'reporterUserId': userId,
          'createdAt': {r'$gte': twentyFourHoursAgo.toIso8601String()},
        }),
      ]);

      // Count locally.
      final commentCount = (engagementItems as List<Engagement>)
          .where((e) => e.comment != null)
          .length;
      final reactionCount = engagementItems
          .where((e) => e.reaction != null)
          .length;
      final reportCount = (reportItems as List<Report>).length;

      _commentCount = commentCount;
      _reactionCount = reactionCount;
      _reportCount = reportCount;
      _countsLastFetchedAt = DateTime.now();
      _initializationStatus = _CacheInitializationStatus.succeeded;
      _retryAttempt = 0; // Reset retry attempts on success.

      _logger.info(
        'Successfully fetched daily counts for user $userId: '
        'Comments: $_commentCount, Reactions: $_reactionCount, Reports: $_reportCount',
      );
    } catch (e, s) {
      _logger.severe(
        'Failed to fetch daily action counts for user $userId.',
        e,
        s,
      );
      _clearCache();
      _initializationStatus = _CacheInitializationStatus.failed;
    }
  }

  /// A helper function that fetches all items from a paginated endpoint.
  ///
  /// It repeatedly calls `repository.readAll` using the cursor from each
  /// response until `hasMore` is `false`, accumulating all items into a
  /// single list.
  Future<List<T>> _fetchAllPaginatedItems<T>(
    DataRepository<T> repository,
    String userId,
    Map<String, dynamic> filter,
  ) async {
    final allItems = <T>[];
    String? cursor;
    var hasMore = true;

    while (hasMore) {
      final response = await repository.readAll(
        userId: userId,
        filter: filter,
        pagination: PaginationOptions(cursor: cursor, limit: 100),
      );
      allItems.addAll(response.items);
      hasMore = response.hasMore;
      cursor = response.cursor;
    }
    return allItems;
  }

  /// Schedules a retry of the `_fetchDailyCounts` method with an exponential
  /// backoff strategy.
  ///
  /// This is used when the service is in a `failed` state to prevent the app
  /// from being permanently unable to check limits without a restart.
  void _scheduleRetry(String userId) {
    _retryAttempt++;
    // Exponential backoff: 2s, 8s, 18s, 32s, 50s, then caps at 60s.
    final delaySeconds = min(2 * _retryAttempt * _retryAttempt, 60);
    _logger.info(
      'Scheduling daily count fetch retry attempt #$_retryAttempt in $delaySeconds seconds.',
    );
    Future.delayed(Duration(seconds: delaySeconds), () {
      // Only attempt the fetch if the user hasn't changed in the meantime.
      if (_cachedForUserId == userId) {
        unawaited(_fetchDailyCounts(userId));
      }
    });
  }

  /// Invalidates the daily count cache and triggers a background refresh.
  ///
  /// This is called by BLoCs when a server-side `ForbiddenException` is caught,
  /// indicating the client's cache is out of sync.
  void invalidateAndForceRefresh() {
    final userId = _appBloc.state.user?.id;
    if (userId == null) return;

    _logger.info(
      'Invalidating daily counts cache and forcing refresh for user $userId.',
    );
    _clearCache();
    unawaited(_fetchDailyCounts(userId));
  }

  /// Checks if the current user is allowed to perform a given [action].
  ///
  /// Returns a [LimitationStatus] indicating whether the action is allowed or
  /// if a specific limit has been reached.
  Future<LimitationStatus> checkAction(
    ContentAction action, {
    PushNotificationSubscriptionDeliveryType? deliveryType,
  }) async {
    _logger.fine(
      'Checking action limit for: ${action.name}, user: ${_appBloc.state.user?.id}',
    );

    final state = _appBloc.state;
    final user = state.user!; // User is guaranteed to be non-null here.
    final preferences = state.userContentPreferences;
    final remoteConfig = state.remoteConfig;

    // If the initial fetch is still pending, wait for it to complete.
    // This handles the race condition on app startup where an action is
    // checked before the initial counts are available.
    if (_initializationStatus == _CacheInitializationStatus.pending &&
        _fetchDailyCountsFuture != null) {
      await _fetchDailyCountsFuture;
    }

    // Fail open: If essential data is missing, allow the action.
    if (preferences == null || remoteConfig == null) {
      _logger.warning(
        'Cannot check action limits: Preferences or RemoteConfig is null. Allowing action by default.',
      );
      return LimitationStatus.allowed;
    }

    final limits = remoteConfig.user.limits;
    final tier = user.tier;

    // Check daily limits, handling cache state.
    final isCacheStale =
        _countsLastFetchedAt == null ||
        DateTime.now().difference(_countsLastFetchedAt!) > _cacheDuration;

    if (isCacheStale &&
        _cachedForUserId == user.id &&
        _initializationStatus != _CacheInitializationStatus.pending) {
      // Asynchronously refresh in the background, but don't wait.
      // Use the current (potentially stale) data for the check.
      _logger.info(
        'Daily count cache is stale. Triggering background refresh.',
      );
      unawaited(_fetchDailyCounts(user.id));
    }

    switch (action) {
      // Persisted preference checks (synchronous)
      case ContentAction.bookmarkHeadline:
        final limit = limits.savedHeadlines[tier];
        _logger.finer(
          'Bookmark limit check for tier "$tier": ${preferences.savedHeadlines.length}/$limit',
        );
        if (limit != null && preferences.savedHeadlines.length >= limit) {
          _logLimitExceeded(LimitedAction.bookmarkHeadline);
          return getLimitationStatusForTier(tier);
        }

      case ContentAction.followTopic:
      case ContentAction.followSource:
      case ContentAction.followCountry:
        final limit = limits.followedItems[tier];
        _logger.finer(
          'Follow limit check for tier "$tier" and action "${action.name}"',
        );
        if (limit == null) return LimitationStatus.allowed;
        final count = switch (action) {
          ContentAction.followTopic => preferences.followedTopics.length,
          ContentAction.followSource => preferences.followedSources.length,
          ContentAction.followCountry => preferences.followedCountries.length,
          _ => 0,
        };
        _logger.finer('Current count: $count, Limit: $limit');
        if (count >= limit) {
          _logLimitExceeded(switch (action) {
            ContentAction.followTopic => LimitedAction.followTopic,
            ContentAction.followSource => LimitedAction.followSource,
            ContentAction.followCountry => LimitedAction.followCountry,
            _ => LimitedAction.followTopic,
          });
          return getLimitationStatusForTier(tier);
        }

      case ContentAction.saveFilter:
        final limit = limits.savedHeadlineFilters[tier]?.total;
        _logger.finer(
          'Save filter limit check for tier "$tier": ${preferences.savedHeadlineFilters.length}/$limit',
        );
        if (limit != null && preferences.savedHeadlineFilters.length >= limit) {
          _logLimitExceeded(LimitedAction.saveFilter);
          return getLimitationStatusForTier(tier);
        }

      case ContentAction.pinFilter:
        final limit = limits.savedHeadlineFilters[tier]?.pinned;
        final pinnedCount = preferences.savedHeadlineFilters
            .where((f) => f.isPinned)
            .length;
        _logger.finer(
          'Pin filter limit check for tier "$tier": $pinnedCount/$limit',
        );
        if (limit != null &&
            preferences.savedHeadlineFilters.where((f) => f.isPinned).length >=
                limit) {
          _logLimitExceeded(LimitedAction.pinFilter);
          return getLimitationStatusForTier(tier);
        }

      case ContentAction.subscribeToSavedFilterNotifications:
        final subscriptionLimits =
            limits.savedHeadlineFilters[tier]?.notificationSubscriptions;
        _logger.finer(
          'Notification subscription limit check for tier "$tier", type "$deliveryType"',
        );
        if (subscriptionLimits == null) return LimitationStatus.allowed;

        final currentCounts = <PushNotificationSubscriptionDeliveryType, int>{};
        for (final filter in preferences.savedHeadlineFilters) {
          for (final type in filter.deliveryTypes) {
            currentCounts.update(type, (v) => v + 1, ifAbsent: () => 1);
          }
        }

        if (deliveryType != null) {
          final limitForType = subscriptionLimits[deliveryType] ?? 0;
          final currentCountForType = currentCounts[deliveryType] ?? 0;
          _logger.finer(
            'Current subscriptions for type "$deliveryType": $currentCountForType, Limit: $limitForType',
          );
          if (currentCountForType >= limitForType) {
            _logLimitExceeded(
              LimitedAction.subscribeToSavedFilterNotifications,
            );
            return getLimitationStatusForTier(tier);
          }
        }

      // Daily action checks (asynchronous, cached)
      case ContentAction.editProfile:
        // Currently, editing a profile is always allowed and not subject to
        // daily limits. This case is added for completeness.
        return LimitationStatus.allowed;
      case ContentAction.postComment:
      case ContentAction.reactToContent:
      case ContentAction.submitReport:
        // If the initial fetch failed, fail-open to allow the action.
        // The server will be the final authority.
        if (_initializationStatus == _CacheInitializationStatus.failed) {
          _logger.warning(
            'Daily count cache initialization failed. Allowing action ${action.name} by default.',
          );
          // Schedule a retry in the background with exponential backoff.
          _scheduleRetry(user.id);
          return LimitationStatus.allowed;
        }

        final (count, limit) = switch (action) {
          ContentAction.postComment => (
            _commentCount,
            limits.commentsPerDay[tier],
          ),
          ContentAction.reactToContent => (
            _reactionCount,
            limits.reactionsPerDay[tier],
          ),
          ContentAction.submitReport => (
            _reportCount,
            limits.reportsPerDay[tier],
          ),
          _ => (null, null),
        };

        _logger.finer(
          'Daily limit check for ${action.name} on tier "$tier": ${count ?? 0}/$limit',
        );

        if (limit != null && (count ?? 0) >= limit) {
          _logLimitExceeded(switch (action) {
            ContentAction.postComment => LimitedAction.postComment,
            ContentAction.reactToContent => LimitedAction.reactToContent,
            ContentAction.submitReport => LimitedAction.submitReport,
            _ => LimitedAction.reactToContent,
          });
          return getLimitationStatusForTier(tier);
        }
    }

    return LimitationStatus.allowed;
  }

  void _logLimitExceeded(LimitedAction limitType) {
    _analyticsService.logEvent(
      AnalyticsEvent.limitExceeded,
      payload: LimitExceededPayload(limitType: limitType),
    );
  }

  /// Returns the correct [LimitationStatus] based on the user's [AccessTier].
  LimitationStatus getLimitationStatusForTier(AccessTier tier) {
    switch (tier) {
      case AccessTier.guest:
        return LimitationStatus.anonymousLimitReached;
      case AccessTier.standard:
        return LimitationStatus.standardUserLimitReached;
    }
  }
}
