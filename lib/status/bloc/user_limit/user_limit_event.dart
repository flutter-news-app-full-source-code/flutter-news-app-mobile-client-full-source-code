part of 'user_limit_bloc.dart';

/// Base class for all events in the [UserLimitBloc].
sealed class UserLimitEvent extends Equatable {
  const UserLimitEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when a user has taken an action in response to a limit
/// prompt (e.g., dismissed the prompt, initiated account linking, or upgrade).
final class LimitActionTaken extends UserLimitEvent {
  /// Creates a [LimitActionTaken] event.
  const LimitActionTaken();
}

/// Event triggered to signal that a user limit has been exceeded and
/// the UI should react accordingly.
final class LimitExceededTriggered extends UserLimitEvent {
  /// Creates a [LimitExceededTriggered] event.
  ///
  /// [limitType] specifies which type of limit was exceeded.
  /// [userRole] is the role of the user who exceeded the limit.
  /// [action] is the recommended action for the user to take.
  const LimitExceededTriggered({
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

  @override
  List<Object?> get props => [limitType, userRole, action];
}
