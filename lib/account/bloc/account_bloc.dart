import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';

part 'account_event.dart';
part 'account_state.dart';

/// {@template account_bloc}
/// BLoC responsible for managing the state and logic for the Account feature.
/// {@endtemplate}
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  /// {@macro account_bloc}
  AccountBloc({required HtAuthenticationRepository authenticationRepository})
    : _authenticationRepository = authenticationRepository,
      super(const AccountState()) {
    on<AccountLogoutRequested>(_onLogoutRequested);
    // Handlers for AccountSettingsNavigationRequested and
    // AccountBackupNavigationRequested are typically handled in the UI layer
    // (e.g., BlocListener navigating) or could emit specific states if needed.
    // For now, we only need the logout logic here.
  }

  final HtAuthenticationRepository _authenticationRepository;

  /// Handles the [AccountLogoutRequested] event.
  ///
  /// Attempts to sign out the user using the [HtAuthenticationRepository].
  /// Emits [AccountStatus.loading] before the operation and updates to
  /// [AccountStatus.success] or [AccountStatus.failure] based on the outcome.
  Future<void> _onLogoutRequested(
    AccountLogoutRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(status: AccountStatus.loading));
    try {
      await _authenticationRepository.signOut();
      // No need to emit success here. The AppBloc listening to the
      // repository's user stream will handle the global state change
      // and trigger the necessary UI updates/redirects.
      // We can emit an initial state again if needed for this BLoC's
      // local state.
      emit(state.copyWith(status: AccountStatus.initial));
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: 'Logout failed: $e',
        ),
      );
    }
  }
}
