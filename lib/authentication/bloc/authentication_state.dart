part of 'authentication_bloc.dart';

/// {@template authentication_state}
/// Base class for authentication states.
/// {@endtemplate}
sealed class AuthenticationState extends Equatable {
  /// {@macro authentication_state}
  const AuthenticationState();

  @override
  List<Object> get props => [];
}

/// {@template authentication_initial}
/// The initial authentication state.
/// {@endtemplate}
final class AuthenticationInitial extends AuthenticationState {}

/// {@template authentication_loading}
/// A state indicating that an authentication operation is in progress.
/// {@endtemplate}
final class AuthenticationLoading extends AuthenticationState {}

/// {@template authentication_authenticated}
/// Represents a successful authentication.
/// {@endtemplate}
final class AuthenticationAuthenticated extends AuthenticationState {
  /// {@macro authentication_authenticated}
  const AuthenticationAuthenticated({required this.user});

  /// The authenticated [User] object.
  final User user;

  @override
  List<Object> get props => [user];
}

/// {@template authentication_unauthenticated}
/// Represents an unauthenticated state.
/// {@endtemplate}
final class AuthenticationUnauthenticated extends AuthenticationState {}

/// {@template authentication_request_code_loading}
/// State indicating that the sign-in code is being requested.
/// {@endtemplate}
final class AuthenticationRequestCodeLoading extends AuthenticationState {}

/// {@template authentication_code_sent_success}
/// State indicating that the sign-in code was sent successfully.
/// {@endtemplate}
final class AuthenticationCodeSentSuccess extends AuthenticationState {
  /// {@macro authentication_code_sent_success}
  const AuthenticationCodeSentSuccess({required this.email});

  /// The email address the code was sent to.
  final String email;

  @override
  List<Object> get props => [email];
}

/// {@template authentication_failure}
/// Represents an authentication failure.
/// {@endtemplate}
final class AuthenticationFailure extends AuthenticationState {
  /// {@macro authentication_failure}
  const AuthenticationFailure(this.errorMessage);

  /// The error message describing the authentication failure.
  final String errorMessage;

  @override
  List<Object> get props => [errorMessage];
}
