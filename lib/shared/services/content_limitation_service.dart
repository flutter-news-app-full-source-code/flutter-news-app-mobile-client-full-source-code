
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
abstract class ContentLimitationService {
  /// Checks if the current user is allowed to perform a given [action].
  ///
  /// Returns a [LimitationStatus] indicating whether the action is allowed or
  /// if a specific limit has been reached.
  Future<LimitationStatus> checkAction(ContentAction action);
}
