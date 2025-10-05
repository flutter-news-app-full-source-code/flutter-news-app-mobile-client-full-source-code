import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';

/// Defines the types of user preferences that have limits.
enum LimitType {
  /// Represents the limit for followed topics.
  followedTopics,

  /// Represents the limit for followed sources.
  followedSources,

  /// Represents the limit for followed countries.
  followedCountries,

  /// Represents the limit for saved headlines.
  savedHeadlines,
}

/// Defines the possible actions a user can take when a limit is exceeded.
enum LimitAction {
  /// No specific action is required or offered.
  none,

  /// The user should be prompted to link their account.
  linkAccount,

  /// The user should be prompted to upgrade to a premium subscription.
  upgradeToPremium,
}

/// {@template limit_exceeded}
/// Represents that a specific user preference limit has been exceeded.
///
/// This object contains details about the limit that was hit, the user's role,
/// and the recommended action for the user to take.
/// {@endtemplate}
class LimitExceeded {
  /// {@macro limit_exceeded}
  const LimitExceeded({
    required this.limitType,
    required this.userRole,
    required this.action,
  });

  /// The type of limit that was exceeded.
  final LimitType limitType;

  /// The role of the user who exceeded the limit.
  final AppUserRole userRole;

  /// The recommended action for the user to take.
  final LimitAction action;
}

/// {@template user_limit_service}
/// A service that encapsulates the logic for checking user preference limits.
///
/// This service provides a method to determine if a user has exceeded
/// limits for followed items or saved headlines based on their [AppUserRole]
/// and the [RemoteConfig]. It returns a [LimitExceeded] object if a limit
/// is reached, guiding the UI to prompt users for appropriate actions.
/// {@endtemplate}
class UserLimitService {
  /// {@macro user_limit_service}
  UserLimitService({required AppBloc appBloc}) : _appBloc = appBloc;

  final AppBloc _appBloc;

  /// Checks if the user has exceeded a specific preference limit.
  ///
  /// - [limitType]: Specifies which type of limit to check.
  /// - [entityId]: Optional ID of the entity being checked against the limit.
  ///   This is used to determine if an item is being added or removed.
  ///
  /// Returns a [LimitExceeded] object if a limit is hit, otherwise returns `null`.
  LimitExceeded? checkLimit({
    required LimitType limitType,
    String? entityId,
  }) {
    final currentUser = _appBloc.state.user;
    final userPreferences = _appBloc.state.userContentPreferences;
    final remoteConfig = _appBloc.state.remoteConfig;

    // If any essential data is missing, we cannot perform the check.
    // This should ideally not happen if the AppBloc is in a stable state.
    if (currentUser == null || userPreferences == null || remoteConfig == null) {
      // In a real application, this might throw an exception or log a severe error.
      // For now, we'll treat it as no limit exceeded to avoid blocking.
      return null;
    }

    final userRole = currentUser.appRole;
    final userPreferenceConfig = remoteConfig.userPreferenceConfig;

    int currentCount = 0;
    int limit = 0;
    LimitAction action = LimitAction.none;

    switch (limitType) {
      case LimitType.followedTopics:
        currentCount = userPreferences.followedTopics.length;
        switch (userRole) {
          case AppUserRole.guestUser:
            limit = userPreferenceConfig.guestFollowedItemsLimit;
            action = LimitAction.linkAccount;
          case AppUserRole.standardUser:
            limit = userPreferenceConfig.authenticatedFollowedItemsLimit;
            action = LimitAction.upgradeToPremium;
          case AppUserRole.premiumUser:
            limit = userPreferenceConfig.premiumFollowedItemsLimit;
            action = LimitAction.none; // Premium users have no practical limit
        }
        // If entityId is provided, check if it's already followed.
        // If it is, this is an unfollow action, so no limit check is needed.
        if (entityId != null &&
            userPreferences.followedTopics.any((t) => t.id == entityId)) {
          return null;
        }
      case LimitType.followedSources:
        currentCount = userPreferences.followedSources.length;
        switch (userRole) {
          case AppUserRole.guestUser:
            limit = userPreferenceConfig.guestFollowedItemsLimit;
            action = LimitAction.linkAccount;
          case AppUserRole.standardUser:
            limit = userPreferenceConfig.authenticatedFollowedItemsLimit;
            action = LimitAction.upgradeToPremium;
          case AppUserRole.premiumUser:
            limit = userPreferenceConfig.premiumFollowedItemsLimit;
            action = LimitAction.none;
        }
        if (entityId != null &&
            userPreferences.followedSources.any((s) => s.id == entityId)) {
          return null;
        }
      case LimitType.followedCountries:
        currentCount = userPreferences.followedCountries.length;
        switch (userRole) {
          case AppUserRole.guestUser:
            limit = userPreferenceConfig.guestFollowedItemsLimit;
            action = LimitAction.linkAccount;
          case AppUserRole.standardUser:
            limit = userPreferenceConfig.authenticatedFollowedItemsLimit;
            action = LimitAction.upgradeToPremium;
          case AppUserRole.premiumUser:
            limit = userPreferenceConfig.premiumFollowedItemsLimit;
            action = LimitAction.none;
        }
        if (entityId != null &&
            userPreferences.followedCountries.any((c) => c.id == entityId)) {
          return null;
        }
      case LimitType.savedHeadlines:
        currentCount = userPreferences.savedHeadlines.length;
        switch (userRole) {
          case AppUserRole.guestUser:
            limit = userPreferenceConfig.guestSavedHeadlinesLimit;
            action = LimitAction.linkAccount;
          case AppUserRole.standardUser:
            limit = userPreferenceConfig.authenticatedSavedHeadlinesLimit;
            action = LimitAction.upgradeToPremium;
          case AppUserRole.premiumUser:
            limit = userPreferenceConfig.premiumSavedHeadlinesLimit;
            action = LimitAction.none;
        }
        if (entityId != null &&
            userPreferences.savedHeadlines.any((h) => h.id == entityId)) {
          return null;
        }
    }

    // If the current count is at or above the limit, and an action is required,
    // then the limit is exceeded.
    if (currentCount >= limit && action != LimitAction.none) {
      return LimitExceeded(
        limitType: limitType,
        userRole: userRole,
        action: action,
      );
    }

    return null; // No limit exceeded
  }
}
