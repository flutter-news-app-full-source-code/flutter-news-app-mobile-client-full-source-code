import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';

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

  /// The action of saving a headline filter.
  saveHeadlineFilter,

  /// The action of pinning a headline filter.
  pinHeadlineFilter,

  /// The action of subscribing to notifications for a headline filter.
  subscribeToHeadlineFilterNotifications,

  /// The action of posting a comment.
  postComment,

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
/// ensuring that rules for actions like bookmarking or following are applied
/// consistently throughout the application.
/// {@endtemplate}
class ContentLimitationService {
  /// {@macro content_limitation_service}
  const ContentLimitationService({required AppBloc appBloc})
    : _appBloc = appBloc;

  final AppBloc _appBloc;

  /// Checks if the current user is allowed to perform a given [action].
  ///
  /// Returns a [LimitationStatus] indicating whether the action is allowed or
  /// if a specific limit has been reached.
  LimitationStatus checkAction(
    ContentAction action, {
    PushNotificationSubscriptionDeliveryType? deliveryType,
  }) {
    final state = _appBloc.state;
    final user = state.user;
    final preferences = state.userContentPreferences;
    final remoteConfig = state.remoteConfig;

    // Fail open: If essential data is missing, allow the action to prevent
    // blocking users due to an incomplete app state.
    if (user == null || preferences == null || remoteConfig == null) {
      return LimitationStatus.allowed;
    }

    final limits = remoteConfig.user.limits;
    final role = user.appRole;

    switch (action) {
      case ContentAction.bookmarkHeadline:
        final count = preferences.savedHeadlines.length;
        final limit = limits.savedHeadlines[role];

        // If no limit is defined for the role, allow the action.
        if (limit == null) return LimitationStatus.allowed;

        if (count >= limit) {
          return _getLimitationStatusForRole(role);
        }

      // Check if the user has reached the limit for saving filters.
      case ContentAction.saveHeadlineFilter:
        final count = preferences.savedHeadlineFilters.length;
        final limitConfig = limits.savedHeadlineFilters[role];

        // If no limit config is defined for the role, allow the action.
        if (limitConfig == null) return LimitationStatus.allowed;

        if (count >= limitConfig.total) {
          return _getLimitationStatusForRole(role);
        }

      case ContentAction.pinHeadlineFilter:
        final count = preferences.savedHeadlineFilters
            .where((filter) => filter.isPinned)
            .length;
        final limit = limits.savedHeadlineFilters[role]?.pinned;

        if (limit == null) return LimitationStatus.allowed;

        if (count >= limit) {
          return _getLimitationStatusForRole(role);
        }

      case ContentAction.subscribeToHeadlineFilterNotifications:
        final subscriptionLimits =
            limits.savedHeadlineFilters[role]?.notificationSubscriptions;

        // If no subscription limits are defined for the role, allow the action.
        if (subscriptionLimits == null) return LimitationStatus.allowed;

        final currentCounts = <PushNotificationSubscriptionDeliveryType, int>{};
        for (final filter in preferences.savedHeadlineFilters) {
          for (final type in filter.deliveryTypes) {
            currentCounts.update(type, (value) => value + 1, ifAbsent: () => 1);
          }
        }

        // If a specific delivery type is provided, check the limit for that
        // type only. This is used by the SaveFilterDialog UI.
        if (deliveryType != null) {
          final limitForType = subscriptionLimits[deliveryType] ?? 0;
          final currentCountForType = currentCounts[deliveryType] ?? 0;

          if (currentCountForType >= limitForType) {
            return _getLimitationStatusForRole(role);
          }
        } else {
          // If no specific type is provided, perform a general check to see
          // if the user can subscribe to *any* notification type. This maintains
          // backward compatibility for broader checks.
          final canSubscribeToAny = subscriptionLimits.entries.any((entry) {
            final limit = entry.value;
            final currentCount = currentCounts[entry.key] ?? 0;
            return currentCount < limit;
          });

          if (!canSubscribeToAny) {
            return _getLimitationStatusForRole(role);
          }
        }

      case ContentAction.followTopic:
      case ContentAction.followSource:
      case ContentAction.followCountry:
        final limit = limits.followedItems[role];

        // Determine the count for the specific item type being followed.
        final int count;
        switch (action) {
          case ContentAction.followTopic:
            count = preferences.followedTopics.length;
          case ContentAction.followSource:
            count = preferences.followedSources.length;
          case ContentAction.followCountry:
            count = preferences.followedCountries.length;
          // These cases are handled above and will not be reached here.
          case ContentAction.bookmarkHeadline:
          case ContentAction.saveHeadlineFilter:
          case ContentAction.pinHeadlineFilter:
          case ContentAction.postComment:
          case ContentAction.subscribeToHeadlineFilterNotifications:
          case ContentAction.submitReport:
            count = 0;
        }

        // If no limit is defined for the role, allow the action.
        if (limit == null) return LimitationStatus.allowed;

        if (count >= limit) {
          return _getLimitationStatusForRole(role);
        }

      case ContentAction.postComment:
        const count = 0; // Not tracked per-session yet.
        final limit = limits.commentsPerDay[role];

        if (limit == null) return LimitationStatus.allowed;
        if (count >= limit) {
          return _getLimitationStatusForRole(role);
        }

      case ContentAction.submitReport:
        const count = 0; // Not tracked per-session yet.
        final limit = limits.reportsPerDay[role];

        if (limit == null) return LimitationStatus.allowed;
        if (count >= limit) {
          return _getLimitationStatusForRole(role);
        }
    }

    // If no limit was hit, the action is allowed.
    return LimitationStatus.allowed;
  }

  /// Maps an [AppUserRole] to the corresponding [LimitationStatus].
  ///
  /// This helper function ensures a consistent mapping when a limit is reached.
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
