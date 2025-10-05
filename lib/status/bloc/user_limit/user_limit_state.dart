part of 'user_limit_bloc.dart';

/// Defines the possible actions a user can take when a limit is exceeded.
enum LimitAction {
  /// No specific action is required or offered.
  none,

  /// The user should be prompted to link their account.
  linkAccount,

  /// The user should be prompted to upgrade to a premium subscription.
  upgradeToPremium,
}

/// Base class for all states in the [UserLimitBloc].
sealed class UserLimitState extends Equatable {
  const UserLimitState();

  @override
  List<Object?> get props => [];
}

/// The initial state of the [UserLimitBloc].
final class UserLimitInitial extends UserLimitState {}

/// State indicating that a user limit check is in progress.
final class UserLimitLoading extends UserLimitState {}

/// State indicating that a user limit check was successful and no limit was exceeded.
final class UserLimitSuccess extends UserLimitState {}

/// State indicating that a user limit check failed due to an error.
final class UserLimitFailure extends UserLimitState {
  /// Creates a [UserLimitFailure] state.
  ///
  /// [exception] is the error that occurred during the limit check.
  const UserLimitFailure({required this.exception});

  /// The exception that caused the failure.
  final HttpException exception;

  @override
  List<Object?> get props => [exception];
}

/// State indicating that a specific user preference limit has been exceeded.
final class LimitExceeded extends UserLimitState {
  /// Creates a [LimitExceeded] state.
  ///
  /// [limitType] specifies which type of limit was exceeded.
  /// [userRole] is the role of the user who exceeded the limit.
  /// [action] is the recommended action for the user to take.
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

  @override
  List<Object?> get props => [limitType, userRole, action];
}
