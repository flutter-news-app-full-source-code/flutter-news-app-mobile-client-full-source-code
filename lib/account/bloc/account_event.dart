part of 'account_bloc.dart';

/// {@template account_event}
/// Base class for Account events.
/// {@endtemplate}
sealed class AccountEvent extends Equatable {
  /// {@macro account_event}
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

/// {@template _account_user_changed}
/// Internal event triggered when the authenticated user changes.
/// {@endtemplate}
final class _AccountUserChanged extends AccountEvent {
  /// {@macro _account_user_changed}
  const _AccountUserChanged({required this.user});

  /// The current authenticated user, or null if unauthenticated.
  final User? user;

  @override
  List<Object?> get props => [user];
}

/// {@template account_load_content_preferences_requested}
/// Event triggered when the user's content preferences need to be loaded.
/// {@endtemplate}
final class AccountLoadContentPreferencesRequested extends AccountEvent {
  /// {@macro account_load_content_preferences_requested}
  const AccountLoadContentPreferencesRequested({required this.userId});

  /// The ID of the user whose content preferences should be loaded.
  final String userId;

  @override
  List<Object> get props => [userId];
}
