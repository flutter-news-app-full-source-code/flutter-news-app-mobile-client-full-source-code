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
  const AuthenticationAuthenticated(this.user);

  /// The authenticated [User] object.
  final User user;

  @override
  List<Object> get props => [user];
}

/// {@template authentication_unauthenticated}
/// Represents an unauthenticated state.
/// {@endtemplate}
final class AuthenticationUnauthenticated extends AuthenticationState {}

/// {@template authentication_link_sending}
/// State indicating that the sign-in link is being sent.
/// {@endtemplate}
final class AuthenticationLinkSending extends AuthenticationState {}

/// {@template authentication_link_sent_success}
/// State indicating that the sign-in link was sent successfully.
/// {@endtemplate}
final class AuthenticationLinkSentSuccess extends AuthenticationState {}

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
