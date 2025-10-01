import 'package:core/core.dart';

/// {@template user_limit_service}
/// A service that provides utility methods for checking user content limits
/// based on their [AppUserRole] and [UserPreferenceConfig].
/// {@endtemplate}
class UserLimitService {
  /// {@macro user_limit_service}
  const UserLimitService();

  /// Determines if the user has reached the limit for followed topics.
  ///
  /// - [userRole]: The current role of the user.
  /// - [userPreferenceConfig]: The remote configuration for user preferences.
  /// - [followedTopicsCount]: The current number of topics the user is following.
  ///
  /// Returns `true` if the limit is reached, `false` otherwise.
  bool hasReachedFollowedTopicsLimit({
    required AppUserRole userRole,
    required UserPreferenceConfig userPreferenceConfig,
    required int followedTopicsCount,
  }) {
    final limit = _getFollowedItemsLimit(userRole, userPreferenceConfig);
    return followedTopicsCount >= limit;
  }

  /// Determines if the user has reached the limit for followed sources.
  ///
  /// - [userRole]: The current role of the user.
  /// - [userPreferenceConfig]: The remote configuration for user preferences.
  /// - [followedSourcesCount]: The current number of sources the user is following.
  ///
  /// Returns `true` if the limit is reached, `false` otherwise.
  bool hasReachedFollowedSourcesLimit({
    required AppUserRole userRole,
    required UserPreferenceConfig userPreferenceConfig,
    required int followedSourcesCount,
  }) {
    final limit = _getFollowedItemsLimit(userRole, userPreferenceConfig);
    return followedSourcesCount >= limit;
  }

  /// Determines if the user has reached the limit for followed countries.
  ///
  /// - [userRole]: The current role of the user.
  /// - [userPreferenceConfig]: The remote configuration for user preferences.
  /// - [followedCountriesCount]: The current number of countries the user is following.
  ///
  /// Returns `true` if the limit is reached, `false` otherwise.
  bool hasReachedFollowedCountriesLimit({
    required AppUserRole userRole,
    required UserPreferenceConfig userPreferenceConfig,
    required int followedCountriesCount,
  }) {
    final limit = _getFollowedItemsLimit(userRole, userPreferenceConfig);
    return followedCountriesCount >= limit;
  }

  /// Determines if the user has reached the limit for saved headlines.
  ///
  /// - [userRole]: The current role of the user.
  /// - [userPreferenceConfig]: The remote configuration for user preferences.
  /// - [savedHeadlinesCount]: The current number of headlines the user has saved.
  ///
  /// Returns `true` if the limit is reached, `false` otherwise.
  bool hasReachedSavedHeadlinesLimit({
    required AppUserRole userRole,
    required UserPreferenceConfig userPreferenceConfig,
    required int savedHeadlinesCount,
  }) {
    final limit = _getSavedHeadlinesLimit(userRole, userPreferenceConfig);
    return savedHeadlinesCount >= limit;
  }

  /// Retrieves the maximum number of followed items allowed for a given user role.
  int _getFollowedItemsLimit(
    AppUserRole userRole,
    UserPreferenceConfig userPreferenceConfig,
  ) {
    switch (userRole) {
      case AppUserRole.guestUser:
        return userPreferenceConfig.guestFollowedItemsLimit;
      case AppUserRole.standardUser:
        return userPreferenceConfig.authenticatedFollowedItemsLimit;
      case AppUserRole.premiumUser:
        return userPreferenceConfig.premiumFollowedItemsLimit;
    }
  }

  /// Retrieves the maximum number of saved headlines allowed for a given user role.
  int _getSavedHeadlinesLimit(
    AppUserRole userRole,
    UserPreferenceConfig userPreferenceConfig,
  ) {
    switch (userRole) {
      case AppUserRole.guestUser:
        return userPreferenceConfig.guestSavedHeadlinesLimit;
      case AppUserRole.standardUser:
        return userPreferenceConfig.authenticatedSavedHeadlinesLimit;
      case AppUserRole.premiumUser:
        return userPreferenceConfig.premiumSavedHeadlinesLimit;
    }
  }
}
