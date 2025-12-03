part of 'engagement_bloc.dart';

/// Base class for all engagement events.
abstract class EngagementEvent extends Equatable {
  const EngagementEvent();

  @override
  List<Object?> get props => [];
}

/// {@template engagement_started}
/// Dispatched to initialize the bloc and fetch initial engagement data.
/// {@endtemplate}
class EngagementStarted extends EngagementEvent {
  /// {@macro engagement_started}
  const EngagementStarted();
}

/// {@template engagement_reaction_updated}
/// Dispatched when the user selects or updates their reaction.
/// {@endtemplate}
class EngagementReactionUpdated extends EngagementEvent {
  /// {@macro engagement_reaction_updated}
  const EngagementReactionUpdated(this.reactionType);

  /// The new reaction type selected by the user.
  final ReactionType? reactionType;

  @override
  List<Object?> get props => [reactionType];
}

/// {@template engagement_comment_posted}
/// Dispatched when the user posts a new comment.
/// {@endtemplate}
class EngagementCommentPosted extends EngagementEvent {
  /// {@macro engagement_comment_posted}
  const EngagementCommentPosted(this.content);

  /// The text content of the comment.
  final String content;

  @override
  List<Object> get props => [content];
}

/// {@template engagement_quick_reaction_toggled}
/// Dispatched when a user taps a quick reaction (like/dislike) on the feed.
/// {@endtemplate}
class EngagementQuickReactionToggled extends EngagementEvent {
  /// {@macro engagement_quick_reaction_toggled}
  const EngagementQuickReactionToggled(this.reactionType);

  final ReactionType reactionType;

  @override
  List<Object> get props => [reactionType];
}
