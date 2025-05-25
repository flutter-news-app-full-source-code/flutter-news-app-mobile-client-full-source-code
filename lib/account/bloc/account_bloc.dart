import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_auth_repository/ht_auth_repository.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_shared/ht_shared.dart'
    show HtHttpException, User, UserContentPreferences;

part 'account_event.dart';
part 'account_state.dart';

/// {@template account_bloc}
/// BLoC responsible for managing the state and logic for the Account feature.
/// {@endtemplate}
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  /// {@macro account_bloc}
  AccountBloc({
    required HtAuthRepository authenticationRepository,
    required HtDataRepository<UserContentPreferences>
    userContentPreferencesRepository,
  }) : _authenticationRepository = authenticationRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       super(const AccountState()) {
    // Listen to authentication state changes from the repository
    _authenticationRepository.authStateChanges.listen(
      (user) => add(_AccountUserChanged(user: user)),
    );

    on<_AccountUserChanged>(_onAccountUserChanged);
    on<AccountLoadContentPreferencesRequested>(
      _onAccountLoadContentPreferencesRequested,
    );
    // Handlers for AccountSettingsNavigationRequested and
    // AccountBackupNavigationRequested are typically handled in the UI layer
    // (e.g., BlocListener navigating) or could emit specific states if needed.
  }

  final HtAuthRepository _authenticationRepository;
  final HtDataRepository<UserContentPreferences>
  _userContentPreferencesRepository;

  /// Handles [_AccountUserChanged] events.
  ///
  /// Updates the state with the current user and triggers loading
  /// of user preferences if the user is authenticated.
  Future<void> _onAccountUserChanged(
    _AccountUserChanged event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(user: event.user));
    if (event.user != null) {
      // User is authenticated, load preferences
      add(AccountLoadContentPreferencesRequested(userId: event.user!.id));
    } else {
      // User is unauthenticated, clear preferences
      emit(state.copyWith());
    }
  }

  /// Handles [AccountLoadContentPreferencesRequested] events.
  ///
  /// Attempts to load the user's content preferences.
  Future<void> _onAccountLoadContentPreferencesRequested(
    AccountLoadContentPreferencesRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(status: AccountStatus.loading));
    try {
      final preferences = await _userContentPreferencesRepository.read(
        id: event.userId,
        userId: event.userId, // Preferences are user-scoped
      );
      emit(
        state.copyWith(status: AccountStatus.success, preferences: preferences),
      );
    } on HtHttpException catch (e) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: 'Failed to load preferences: ${e.message}',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: 'An unexpected error occurred: $e',
        ),
      );
    }
  }
}
