import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
// Hide Category
import 'package:ht_auth_repository/ht_auth_repository.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_shared/ht_shared.dart';

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
    on<AccountFollowCategoryToggled>(_onFollowCategoryToggled);
    on<AccountFollowSourceToggled>(_onFollowSourceToggled);
    on<AccountFollowCountryToggled>(_onFollowCountryToggled);
    on<AccountSaveHeadlineToggled>(_onSaveHeadlineToggled);
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
    emit(state.copyWith(status: AccountStatus.loading)); // Indicate loading
    try {
      final preferences = await _userContentPreferencesRepository.read(
        id: event.userId,
        userId: event.userId,
      );
      emit(
        state.copyWith(status: AccountStatus.success, preferences: preferences),
      );
    } on NotFoundException { // Specifically handle NotFound
      emit(
        state.copyWith(
          status: AccountStatus.success, // It's a success, just no data
          preferences: UserContentPreferences(id: event.userId), // Provide default/empty
        ),
      );
    } on HtHttpException catch (e) { // Handle other HTTP errors
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: 'Failed to load preferences: ${e.message}',
          preferences: null, // Ensure preferences are cleared on failure
        ),
      );
    } catch (e) { // Catch-all for other unexpected errors
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: 'An unexpected error occurred: $e',
          preferences: null, // Ensure preferences are cleared on failure
        ),
      );
    }
  }

  Future<void> _persistPreferences(
    UserContentPreferences preferences,
    Emitter<AccountState> emit,
  ) async {
    if (state.user == null) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: 'User not authenticated to save preferences.',
        ),
      );
      return;
    }
    try {
      await _userContentPreferencesRepository.update(
        id: state.user!.id, // ID of the preferences object is the user's ID
        item: preferences,
        userId: state.user!.id,
      );
      // Optimistic update already done, emit success if needed for UI feedback
      // emit(state.copyWith(status: AccountStatus.success));
    } on HtHttpException catch (e) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: 'Failed to save preferences: ${e.message}',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: 'An unexpected error occurred while saving: $e',
        ),
      );
    }
  }

  Future<void> _onFollowCategoryToggled(
    AccountFollowCategoryToggled event,
    Emitter<AccountState> emit,
  ) async {
    if (state.preferences == null || state.user == null) return;

    final currentPrefs = state.preferences!;
    final updatedFollowedCategories = List<Category>.from(
      currentPrefs.followedCategories,
    );

    final isCurrentlyFollowing = updatedFollowedCategories.any(
      (category) => category.id == event.category.id,
    );

    if (isCurrentlyFollowing) {
      updatedFollowedCategories.removeWhere(
        (category) => category.id == event.category.id,
      );
    } else {
      updatedFollowedCategories.add(event.category);
    }

    final newPreferences = currentPrefs.copyWith(
      followedCategories: updatedFollowedCategories,
    );
    emit(state.copyWith(preferences: newPreferences));
    await _persistPreferences(newPreferences, emit);
  }

  Future<void> _onFollowSourceToggled(
    AccountFollowSourceToggled event,
    Emitter<AccountState> emit,
  ) async {
    if (state.preferences == null || state.user == null) return;

    final currentPrefs = state.preferences!;
    final updatedFollowedSources = List<Source>.from(
      currentPrefs.followedSources,
    );

    final isCurrentlyFollowing = updatedFollowedSources.any(
      (source) => source.id == event.source.id,
    );

    if (isCurrentlyFollowing) {
      updatedFollowedSources.removeWhere(
        (source) => source.id == event.source.id,
      );
    } else {
      updatedFollowedSources.add(event.source);
    }

    final newPreferences = currentPrefs.copyWith(
      followedSources: updatedFollowedSources,
    );
    emit(state.copyWith(preferences: newPreferences));
    await _persistPreferences(newPreferences, emit);
  }

  Future<void> _onFollowCountryToggled(
    AccountFollowCountryToggled event,
    Emitter<AccountState> emit,
  ) async {
    if (state.preferences == null || state.user == null) return;

    final currentPrefs = state.preferences!;
    final updatedFollowedCountries = List<Country>.from(
      currentPrefs.followedCountries,
    );

    final isCurrentlyFollowing = updatedFollowedCountries.any(
      (country) => country.id == event.country.id,
    );

    if (isCurrentlyFollowing) {
      updatedFollowedCountries.removeWhere(
        (country) => country.id == event.country.id,
      );
    } else {
      updatedFollowedCountries.add(event.country);
    }

    final newPreferences = currentPrefs.copyWith(
      followedCountries: updatedFollowedCountries,
    );
    emit(state.copyWith(preferences: newPreferences));
    await _persistPreferences(newPreferences, emit);
  }

  Future<void> _onSaveHeadlineToggled(
    AccountSaveHeadlineToggled event,
    Emitter<AccountState> emit,
  ) async {
    if (state.preferences == null || state.user == null) return;

    final currentPrefs = state.preferences!;
    final updatedSavedHeadlines = List<Headline>.from(
      currentPrefs.savedHeadlines,
    );

    final isCurrentlySaved = updatedSavedHeadlines.any(
      (headline) => headline.id == event.headline.id,
    );

    if (isCurrentlySaved) {
      updatedSavedHeadlines.removeWhere(
        (headline) => headline.id == event.headline.id,
      );
    } else {
      updatedSavedHeadlines.add(event.headline);
    }

    final newPreferences = currentPrefs.copyWith(
      savedHeadlines: updatedSavedHeadlines,
    );
    emit(state.copyWith(preferences: newPreferences));
    await _persistPreferences(newPreferences, emit);
  }
}
