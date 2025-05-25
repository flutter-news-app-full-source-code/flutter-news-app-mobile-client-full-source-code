part of 'account_bloc.dart';

/// Defines the status of the account state.
enum AccountStatus {
  /// The initial state.
  initial,

  /// An operation is in progress.
  loading,

  /// An operation was successful.
  success,

  /// An operation failed.
  failure,
}

/// {@template account_state}
/// State for the Account feature.
/// {@endtemplate}
final class AccountState extends Equatable {
  /// {@macro account_state}
  const AccountState({
    this.status = AccountStatus.initial,
    this.user,
    this.preferences,
    this.errorMessage,
  });

  /// The current status of the account state.
  final AccountStatus status;

  /// The currently authenticated user.
  final User? user;

  /// The user's content preferences.
  final UserContentPreferences? preferences;

  /// An error message if an operation failed.
  final String? errorMessage;

  /// Creates a copy of this [AccountState] with the given fields replaced.
  AccountState copyWith({
    AccountStatus? status,
    User? user,
    UserContentPreferences? preferences,
    String? errorMessage,
  }) {
    return AccountState(
      status: status ?? this.status,
      user: user ?? this.user,
      preferences: preferences ?? this.preferences,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, preferences, errorMessage];
}
