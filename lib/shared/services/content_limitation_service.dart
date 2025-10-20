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

  /// The action of saving a filter.
  saveFilter,
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
  LimitationStatus checkAction(ContentAction action) {
    final state = _appBloc.state;
    final user = state.user;
    final preferences = state.userContentPreferences;
    final remoteConfig = state.remoteConfig;

    // Fail open: If essential data is missing, allow the action to prevent
    // blocking users due to an incomplete app state.
    if (user == null || preferences == null || remoteConfig == null) {
      return LimitationStatus.allowed;
    }

    final limits = remoteConfig.userPreferenceConfig;
    final role = user.appRole;

    switch (action) {
      case ContentAction.bookmarkHeadline:
        final count = preferences.savedHeadlines.length;
        final int limit;
        switch (role) {
          case AppUserRole.guestUser:
            limit = limits.guestSavedHeadlinesLimit;
          case AppUserRole.standardUser:
            limit = limits.authenticatedSavedHeadlinesLimit;
          case AppUserRole.premiumUser:
            limit = limits.premiumSavedHeadlinesLimit;
        }
        if (count >= limit) {
          return _getLimitationStatusForRole(role);
        }

      // Check if the user has reached the limit for saving filters.
      case ContentAction.saveFilter:
        final count = preferences.savedFilters.length;
        final int limit;
        switch (role) {
          case AppUserRole.guestUser:
            limit = limits.guestSavedFiltersLimit;
          case AppUserRole.standardUser:
            limit = limits.authenticatedSavedFiltersLimit;
          case AppUserRole.premiumUser:
            limit = limits.premiumSavedFiltersLimit;
        }
        if (count >= limit) {
          return _getLimitationStatusForRole(role);
        }
      case ContentAction.followTopic:
      case ContentAction.followSource:
      case ContentAction.followCountry:
        final int limit;
        switch (role) {
          case AppUserRole.guestUser:
            limit = limits.guestFollowedItemsLimit;
          case AppUserRole.standardUser:
            limit = limits.authenticatedFollowedItemsLimit;
          case AppUserRole.premiumUser:
            limit = limits.premiumFollowedItemsLimit;
        }

        // Determine the count for the specific item type being followed.
        final int count;
        switch (action) {
          case ContentAction.followTopic:
            count = preferences.followedTopics.length;
          case ContentAction.followSource:
            count = preferences.followedSources.length;
          case ContentAction.followCountry:
            count = preferences.followedCountries.length;
          case ContentAction.bookmarkHeadline:
            // This case is handled above and will not be reached here.
            count = 0;
          case ContentAction.saveFilter:
            // This case is handled above and will not be reached here.
            count = 0;
        }

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
