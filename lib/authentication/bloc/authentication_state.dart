part of 'authentication_bloc.dart';

/// Enum representing the different statuses of the authentication process.
enum AuthenticationStatus {
  /// The initial state before any authentication has been attempted.
  initial,

  /// The user is successfully authenticated.
  authenticated,

  /// The user is not authenticated.
  unauthenticated,

  /// An authentication operation is in progress (e.g., verifying code, signing out).
  loading,

  /// A request to send a sign-in code is in progress.
  requestCodeInProgress,

  /// The sign-in code has been successfully sent.
  requestCodeSuccess,

  /// An authentication operation has failed.
  failure,
}

/// {@template authentication_state}
/// Represents the state of the authentication process.
///
/// This class uses a status enum [AuthenticationStatus] to represent the
/// current state, making state management more predictable. It holds the
/// authenticated user, the email for the code verification flow, and any
/// exception that occurred during a failure.
/// {@endtemplate}
class AuthenticationState extends Equatable {
  /// {@macro authentication_state}
  const AuthenticationState({
    this.status = AuthenticationStatus.initial,
    this.user,
    this.email,
    this.exception,
    this.cooldownEndTime,
  });

  /// The current status of the authentication process.
  final AuthenticationStatus status;

  /// The authenticated user. Null if not authenticated.
  final User? user;

  /// The email address used in the sign-in code flow.
  final String? email;

  /// The exception that occurred, if any.
  final HttpException? exception;

  /// The time when the cooldown for requesting a new code ends.
  final DateTime? cooldownEndTime;

  /// Creates a copy of the current [AuthenticationState] with updated values.
  AuthenticationState copyWith({
    AuthenticationStatus? status,
    User? user,
    String? email,
    HttpException? exception,
    DateTime? cooldownEndTime,
    bool clearCooldownEndTime = false,
  }) {
    return AuthenticationState(
      status: status ?? this.status,
      user: user ?? this.user,
      email: email ?? this.email,
      exception: exception ?? this.exception,
      cooldownEndTime: clearCooldownEndTime
          ? null
          : cooldownEndTime ?? this.cooldownEndTime,
    );
  }

  @override
  List<Object?> get props => [status, user, email, exception, cooldownEndTime];
}
