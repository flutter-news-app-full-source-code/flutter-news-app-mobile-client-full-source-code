part of 'user_limit_bloc.dart';

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

/// Base class for all events in the [UserLimitBloc].
sealed class UserLimitEvent extends Equatable {
  const UserLimitEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered to check if a user has exceeded a specific preference limit.
final class CheckLimitRequested extends UserLimitEvent {
  /// Creates a [CheckLimitRequested] event.
  ///
  /// [limitType] specifies which type of limit to check.
  /// [entityId] is optional and can be used for specific item checks
  /// (e.g., checking if a particular item can be followed/saved).
  const CheckLimitRequested({required this.limitType, this.entityId});

  /// The type of limit to check.
  final LimitType limitType;

  /// Optional ID of the entity being checked against the limit.
  final String? entityId;

  @override
  List<Object?> get props => [limitType, entityId];
}

/// Event triggered when a user has taken an action in response to a limit
/// prompt (e.g., dismissed the prompt, initiated account linking, or upgrade).
final class LimitActionTaken extends UserLimitEvent {
  /// Creates a [LimitActionTaken] event.
  const LimitActionTaken();
}
