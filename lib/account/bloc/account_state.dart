part of 'account_bloc.dart';

/// Enum representing the status of the Account feature.
enum AccountStatus { initial, loading, success, failure }

/// Represents the state of the Account feature.
class AccountState extends Equatable {
  const AccountState({this.status = AccountStatus.initial, this.errorMessage});

  /// The current status of the account feature operations.
  final AccountStatus status;

  /// An optional error message if an operation failed.
  final String? errorMessage;

  /// Creates a copy of the current state with updated values.
  AccountState copyWith({AccountStatus? status, String? errorMessage}) {
    return AccountState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
