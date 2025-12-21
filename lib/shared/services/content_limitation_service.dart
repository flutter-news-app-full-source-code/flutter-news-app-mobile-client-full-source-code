import 'dart:async';

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
}

/// Defines the outcome of a content limitation check.
enum LimitationStatus {
  /// The user is permitted to perform the action.
  allowed,

  /// The user has reached the content limit for anonymous (guest) users.
  anonymousLimitReached,

  /// The user has reached the content limit for standard (free) users.
  standardUserLimitReached,

  /// The user has reached the content limit for premium users.
  premiumUserLimitReached,
}

/// {@template content_limitation_service}
/// A service that centralizes the logic for checking if a user can perform
/// a content-related action based on their role and remote configuration limits.
///
/// This service acts as the single source of truth for content limitations,
/// ensuring that rules are applied consistently throughout the application.
///
/// It is a stateful, caching service that proactively fetches daily action
/// counts for the current user to provide fast, client-side limit checks.
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

  // Internal cache for daily action counts.
  int? _commentCount;
  int? _reactionCount;
  int? _reportCount;
  DateTime? _countsLastFetchedAt;
  String? _cachedForUserId;

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
      _fetchDailyCounts(_appBloc.state.user!.id);
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
        _fetchDailyCounts(newUserId);
      }
    }
  }

  void _clearCache() {
    _commentCount = null;
    _reactionCount = null;
    _reportCount = null;
    _countsLastFetchedAt = null;
    _cachedForUserId = null;
  }

  Future<void> _fetchDailyCounts(String userId) async {
    _logger.info('Fetching daily action counts for user $userId...');
    _cachedForUserId = userId;

    try {
      final twentyFourHoursAgo = DateTime.now().subtract(
        const Duration(hours: 24),
      );

      // Fetch all counts concurrently for performance.
      final [commentCount, reactionCount, reportCount] = await Future.wait<int>(
        [
          _engagementRepository.count(
            userId: userId,
            filter: {
              'comment': {r'$exists': true, r'$ne': null},
              'createdAt': {r'$gte': twentyFourHoursAgo.toIso8601String()},
            },
          ),
          _engagementRepository.count(
            userId: userId,
            filter: {
              'reaction': {r'$exists': true, r'$ne': null},
              'createdAt': {r'$gte': twentyFourHoursAgo.toIso8601String()},
            },
          ),
          _reportRepository.count(
            userId: userId,
            filter: {
              'reporterUserId': userId,
              'createdAt': {r'$gte': twentyFourHoursAgo.toIso8601String()},
            },
          ),
        ],
      );

      _commentCount = commentCount;
      _reactionCount = reactionCount;
      _reportCount = reportCount;
      _countsLastFetchedAt = DateTime.now();

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
      // Clear cache on failure to ensure a retry on the next check.
      _clearCache();
    }
  }

  /// Checks if the current user is allowed to perform a given [action].
  ///
  /// Returns a [LimitationStatus] indicating whether the action is allowed or
  /// if a specific limit has been reached.
  Future<LimitationStatus> checkAction(
    ContentAction action, {
    PushNotificationSubscriptionDeliveryType? deliveryType,
  }) async {
    final state = _appBloc.state;
    final user = state.user;
    final preferences = state.userContentPreferences;
    final remoteConfig = state.remoteConfig;

    // Fail open: If essential data is missing, allow the action.
    if (user == null || preferences == null || remoteConfig == null) {
      return LimitationStatus.allowed;
    }

    final limits = remoteConfig.user.limits;
    final role = user.appRole;

    // Business Rule: Guest users are not allowed to engage or report.
    if (role == AppUserRole.guestUser) {
      switch (action) {
        case ContentAction.postComment:
        case ContentAction.reactToContent:
        case ContentAction.submitReport:
          return LimitationStatus.anonymousLimitReached;
        case ContentAction.bookmarkHeadline:
        case ContentAction.followTopic:
        case ContentAction.followSource:
        case ContentAction.followCountry:
        case ContentAction.saveFilter:
        case ContentAction.pinFilter:
        case ContentAction.subscribeToSavedFilterNotifications:
          break; // Continue to normal check for guest.
      }
    }

    // Check daily limits, refreshing cache if necessary.
    final isCacheStale =
        _countsLastFetchedAt == null ||
        DateTime.now().difference(_countsLastFetchedAt!) > _cacheDuration;

    if (isCacheStale && _cachedForUserId == user.id) {
      await _fetchDailyCounts(user.id);
    }

    switch (action) {
      // Persisted preference checks (synchronous)
      case ContentAction.bookmarkHeadline:
        final limit = limits.savedHeadlines[role];
        if (limit != null && preferences.savedHeadlines.length >= limit) {
          _logLimitExceeded(LimitedAction.bookmarkHeadline);
          return _getLimitationStatusForRole(role);
        }

      case ContentAction.followTopic:
      case ContentAction.followSource:
      case ContentAction.followCountry:
        final limit = limits.followedItems[role];
        if (limit == null) return LimitationStatus.allowed;
        final count = switch (action) {
          ContentAction.followTopic => preferences.followedTopics.length,
          ContentAction.followSource => preferences.followedSources.length,
          ContentAction.followCountry => preferences.followedCountries.length,
          _ => 0,
        };
        if (count >= limit) {
          _logLimitExceeded(switch (action) {
            ContentAction.followTopic => LimitedAction.followTopic,
            ContentAction.followSource => LimitedAction.followSource,
            ContentAction.followCountry => LimitedAction.followCountry,
            _ => LimitedAction.followTopic,
          });
          return _getLimitationStatusForRole(role);
        }

      case ContentAction.saveFilter:
        final limit = limits.savedHeadlineFilters[role]?.total;
        if (limit != null && preferences.savedHeadlineFilters.length >= limit) {
          _logLimitExceeded(LimitedAction.saveFilter);
          return _getLimitationStatusForRole(role);
        }

      case ContentAction.pinFilter:
        final limit = limits.savedHeadlineFilters[role]?.pinned;
        if (limit != null &&
            preferences.savedHeadlineFilters.where((f) => f.isPinned).length >=
                limit) {
          _logLimitExceeded(LimitedAction.pinFilter);
          return _getLimitationStatusForRole(role);
        }

      case ContentAction.subscribeToSavedFilterNotifications:
        final subscriptionLimits =
            limits.savedHeadlineFilters[role]?.notificationSubscriptions;
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
          if (currentCountForType >= limitForType) {
            _logLimitExceeded(
              LimitedAction.subscribeToSavedFilterNotifications,
            );
            return _getLimitationStatusForRole(role);
          }
        }

      // Daily action checks (asynchronous, cached)
      case ContentAction.postComment:
        final limit = limits.commentsPerDay[role];
        if (limit != null && (_commentCount ?? 0) >= limit) {
          _logLimitExceeded(LimitedAction.postComment);
          return _getLimitationStatusForRole(role);
        }

      case ContentAction.reactToContent:
        final limit = limits.reactionsPerDay[role];
        if (limit != null && (_reactionCount ?? 0) >= limit) {
          _logLimitExceeded(LimitedAction.reactToContent);
          return _getLimitationStatusForRole(role);
        }

      case ContentAction.submitReport:
        final limit = limits.reportsPerDay[role];
        if (limit != null && (_reportCount ?? 0) >= limit) {
          _logLimitExceeded(LimitedAction.submitReport);
          return _getLimitationStatusForRole(role);
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

  LimitationStatus _getLimitationStatusForRole(AppUserRole role) {
    switch (role) {
      case AppUserRole.guestUser:
        return LimitationStatus.anonymousLimitReached;
      case AppUserRole.standardUser:
        return LimitationStatus.standardUserLimitReached;
      case AppUserRole.premiumUser:
        return LimitationStatus.premiumUserLimitReached;
    }
  }
}
