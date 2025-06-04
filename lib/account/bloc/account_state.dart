part of 'account_bloc.dart';

enum AccountStatus { initial, loading, success, failure }

class AccountState extends Equatable {
  const AccountState({
    this.status = AccountStatus.initial,
    this.user,
    this.preferences,
    this.errorMessage,
  });

  final AccountStatus status;
  final User? user;
  final UserContentPreferences? preferences;
  final String? errorMessage;

  AccountState copyWith({
    AccountStatus? status,
    User? user,
    UserContentPreferences? preferences,
    String? errorMessage,
    bool clearUser = false,
    bool clearPreferences = false,
    bool clearErrorMessage = false,
  }) {
    return AccountState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      preferences: clearPreferences ? null : preferences ?? this.preferences,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, preferences, errorMessage];
}
