part of 'account_bloc.dart';

enum AccountStatus { initial, loading, success, failure }

class AccountState extends Equatable {
  const AccountState({
    this.status = AccountStatus.initial,
    this.user,
    this.preferences,
    this.error,
  });

  final AccountStatus status;
  final User? user;
  final UserContentPreferences? preferences;
  final HtHttpException? error;

  AccountState copyWith({
    AccountStatus? status,
    User? user,
    UserContentPreferences? preferences,
    HtHttpException? error,
    bool clearUser = false,
    bool clearPreferences = false,
    bool clearError = false,
  }) {
    return AccountState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      preferences: clearPreferences ? null : preferences ?? this.preferences,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, user, preferences, error];
}
