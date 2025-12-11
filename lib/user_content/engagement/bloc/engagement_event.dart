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
  const EngagementReactionUpdated(this.reactionType, {required this.context});

  /// The new reaction type selected by the user.
  final ReactionType? reactionType;

  final BuildContext context;

  @override
  List<Object?> get props => [reactionType, context];
}

/// {@template engagement_comment_posted}
/// Dispatched when the user posts a new comment.
/// {@endtemplate}
class EngagementCommentPosted extends EngagementEvent {
  /// {@macro engagement_comment_posted}
  const EngagementCommentPosted(this.content, {required this.context});

  /// The text content of the comment.
  final String content;

  final BuildContext context;

  @override
  List<Object> get props => [content, context];
}

/// {@template engagement_comment_updated}
/// Dispatched when the user updates their existing comment.
/// {@endtemplate}
class EngagementCommentUpdated extends EngagementEvent {
  /// {@macro engagement_comment_updated}
  const EngagementCommentUpdated(this.content, {required this.context});

  /// The updated text content of the comment.
  final String content;

  final BuildContext context;

  @override
  List<Object> get props => [content, context];
}
