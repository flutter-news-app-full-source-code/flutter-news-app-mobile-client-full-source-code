import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/config.dart'
    as local_config;
import 'package:logging/logging.dart';

part 'account_event.dart';
part 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc({
    required AuthRepository authenticationRepository,
    required DataRepository<UserContentPreferences>
    userContentPreferencesRepository,
    required local_config.AppEnvironment environment,
    Logger? logger,
  }) : _authenticationRepository = authenticationRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _environment = environment,
       _logger = logger ?? Logger('AccountBloc'),
       super(const AccountState()) {
    // Listen to user changes from AuthRepository
    _userSubscription = _authenticationRepository.authStateChanges.listen((
      user,
    ) {
      add(AccountUserChanged(user));
    });

    // Listen to changes in UserContentPreferences from the repository.
    // This ensures the AccountBloc's state is updated whenever preferences
    // are created, updated, or deleted, resolving any synchronization issue.
    _userContentPreferencesSubscription = _userContentPreferencesRepository
        .entityUpdated
        .where((type) => type == UserContentPreferences)
        .listen((_) {
      // If there's a current user, reload their preferences.
      if (state.user?.id != null) {
        add(AccountLoadUserPreferences(userId: state.user!.id));
      }
    });

    // Register event handlers
    on<AccountUserChanged>(_onAccountUserChanged);
    on<AccountLoadUserPreferences>(_onAccountLoadUserPreferences);
    on<AccountSaveHeadlineToggled>(_onAccountSaveHeadlineToggled);
    on<AccountFollowTopicToggled>(_onAccountFollowTopicToggled);
    on<AccountFollowSourceToggled>(_onAccountFollowSourceToggled);
    on<AccountFollowCountryToggled>(_onAccountFollowCountryToggled);
    on<AccountClearUserPreferences>(_onAccountClearUserPreferences);
  }

  final AuthRepository _authenticationRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final local_config.AppEnvironment _environment;
  final Logger _logger;
  late StreamSubscription<User?> _userSubscription;
  late StreamSubscription<Type> _userContentPreferencesSubscription;

  Future<void> _onAccountUserChanged(
    AccountUserChanged event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(user: event.user));
    if (event.user != null) {
      add(AccountLoadUserPreferences(userId: event.user!.id));
    } else {
      // Clear preferences if user is null (logged out)
      emit(
        state.copyWith(clearPreferences: true, status: AccountStatus.initial),
      );
    }
  }

  Future<void> _onAccountLoadUserPreferences(
    AccountLoadUserPreferences event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(status: AccountStatus.loading));
    try {
      final preferences = await _userContentPreferencesRepository.read(
        id: event.userId,
        userId: event.userId,
      );
      emit(
        state.copyWith(
          status: AccountStatus.success,
          preferences: _sortPreferences(preferences),
          clearError: true,
        ),
      );
    } on NotFoundException {
      // If preferences not found, create a default one for the user.
      final defaultPreferences = UserContentPreferences(
        id: event.userId,
        followedCountries: const [],
        followedSources: const [],
        followedTopics: const [],
        savedHeadlines: const [],
      );
      try {
        await _userContentPreferencesRepository.create(
          item: defaultPreferences,
          userId: event.userId,
        );
        emit(
          state.copyWith(
            preferences: _sortPreferences(defaultPreferences),
            clearError: true,
            status: AccountStatus.success,
          ),
        );
      } on ConflictException {
        // If a conflict occurs during creation (e.g., another process
        // created it concurrently), attempt to read it again to get the existing
        // one. This can happen if the migration service created it right after
        // the second NotFoundException.
        _logger.info(
          '[AccountBloc] Conflict during creation of UserContentPreferences. '
          'Attempting to re-read.',
        );
        final existingPreferences = await _userContentPreferencesRepository
            .read(id: event.userId, userId: event.userId);
        emit(
          state.copyWith(
            status: AccountStatus.success,
            preferences: _sortPreferences(existingPreferences),
            clearError: true,
          ),
        );
      } on HttpException catch (e) {
        _logger.severe(
          'Failed to create default preferences with HttpException: $e',
        );
        emit(state.copyWith(status: AccountStatus.failure, error: e));
      } catch (e, st) {
        _logger.severe(
          'Failed to create default preferences with unexpected error: $e',
          e,
          st,
        );
        emit(
          state.copyWith(
            status: AccountStatus.failure,
            error: OperationFailedException(
              'Failed to create default preferences: $e',
            ),
          ),
        );
      }
    } on HttpException catch (e) {
      _logger.severe(
        'AccountLoadUserPreferences failed with HttpException: $e',
      );
      emit(state.copyWith(status: AccountStatus.failure, error: e));
    } catch (e, st) {
      _logger.severe(
        'AccountLoadUserPreferences failed with unexpected error: $e',
        e,
        st,
      );
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          error: OperationFailedException('An unexpected error occurred: $e'),
        ),
      );
    }
  }

  Future<void> _onAccountFollowCountryToggled(
    AccountFollowCountryToggled event,
    Emitter<AccountState> emit,
  ) async {
    if (state.user == null || state.preferences == null) return;
    emit(state.copyWith(status: AccountStatus.loading));

    final currentPrefs = state.preferences!;
    final isCurrentlyFollowed = currentPrefs.followedCountries.any(
      (c) => c.id == event.country.id,
    );
    final List<Country> updatedFollowedCountries;

    updatedFollowedCountries = isCurrentlyFollowed
        ? (List.from(currentPrefs.followedCountries)
            ..removeWhere((c) => c.id == event.country.id))
        : (List.from(currentPrefs.followedCountries)..add(event.country));

    final updatedPrefs = currentPrefs.copyWith(
      followedCountries: updatedFollowedCountries,
    );

    try {
      final sortedPrefs = _sortPreferences(updatedPrefs);
      await _userContentPreferencesRepository.update(
        id: state.user!.id,
        item: sortedPrefs,
        userId: state.user!.id,
      );
      emit(
        state.copyWith(
          status: AccountStatus.success,
          preferences: sortedPrefs,
          clearError: true,
        ),
      );
    } on HttpException catch (e) {
      _logger.severe(
        'AccountFollowCountryToggled failed with HttpException: $e',
      );
      emit(state.copyWith(status: AccountStatus.failure, error: e));
    } catch (e, st) {
      _logger.severe(
        'AccountFollowCountryToggled failed with unexpected error: $e',
        e,
        st,
      );
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          error: OperationFailedException(
            'Failed to update followed countries: $e',
          ),
        ),
      );
    }
  }

  Future<void> _onAccountSaveHeadlineToggled(
    AccountSaveHeadlineToggled event,
    Emitter<AccountState> emit,
  ) async {
    if (state.user == null || state.preferences == null) return;
    emit(state.copyWith(status: AccountStatus.loading));

    final currentPrefs = state.preferences!;
    final isCurrentlySaved = currentPrefs.savedHeadlines.any(
      (h) => h.id == event.headline.id,
    );
    final List<Headline> updatedSavedHeadlines;

    if (isCurrentlySaved) {
      updatedSavedHeadlines = List.from(currentPrefs.savedHeadlines)
        ..removeWhere((h) => h.id == event.headline.id);
    } else {
      updatedSavedHeadlines = List.from(currentPrefs.savedHeadlines)
        ..add(event.headline);
    }

    final updatedPrefs = currentPrefs.copyWith(
      savedHeadlines: updatedSavedHeadlines,
    );

    try {
      final sortedPrefs = _sortPreferences(updatedPrefs);
      await _userContentPreferencesRepository.update(
        id: state.user!.id,
        item: sortedPrefs,
        userId: state.user!.id,
      );
      emit(
        state.copyWith(
          status: AccountStatus.success,
          preferences: sortedPrefs,
          clearError: true,
        ),
      );
    } on HttpException catch (e) {
      _logger.severe(
        'AccountSaveHeadlineToggled failed with HttpException: $e',
      );
      emit(state.copyWith(status: AccountStatus.failure, error: e));
    } catch (e, st) {
      _logger.severe(
        'AccountSaveHeadlineToggled failed with unexpected error: $e',
        e,
        st,
      );
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          error: OperationFailedException(
            'Failed to update saved headlines: $e',
          ),
        ),
      );
    }
  }

  Future<void> _onAccountFollowTopicToggled(
    AccountFollowTopicToggled event,
    Emitter<AccountState> emit,
  ) async {
    if (state.user == null || state.preferences == null) return;
    emit(state.copyWith(status: AccountStatus.loading));

    final currentPrefs = state.preferences!;
    final isCurrentlyFollowed = currentPrefs.followedTopics.any(
      (t) => t.id == event.topic.id,
    );
    final List<Topic> updatedFollowedTopics;

    updatedFollowedTopics = isCurrentlyFollowed
        ? (List.from(currentPrefs.followedTopics)
            ..removeWhere((t) => t.id == event.topic.id))
        : (List.from(currentPrefs.followedTopics)..add(event.topic));

    final updatedPrefs = currentPrefs.copyWith(
      followedTopics: updatedFollowedTopics,
    );

    try {
      final sortedPrefs = _sortPreferences(updatedPrefs);
      await _userContentPreferencesRepository.update(
        id: state.user!.id,
        item: sortedPrefs,
        userId: state.user!.id,
      );
      emit(
        state.copyWith(
          status: AccountStatus.success,
          preferences: sortedPrefs,
          clearError: true,
        ),
      );
    } on HttpException catch (e) {
      _logger.severe('AccountFollowTopicToggled failed with HttpException: $e');
      emit(state.copyWith(status: AccountStatus.failure, error: e));
    } catch (e, st) {
      _logger.severe(
        'AccountFollowTopicToggled failed with unexpected error: $e',
        e,
        st,
      );
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          error: OperationFailedException(
            'Failed to update followed topics: $e',
          ),
        ),
      );
    }
  }

  Future<void> _onAccountFollowSourceToggled(
    AccountFollowSourceToggled event,
    Emitter<AccountState> emit,
  ) async {
    if (state.user == null || state.preferences == null) return;
    emit(state.copyWith(status: AccountStatus.loading));

    final currentPrefs = state.preferences!;
    final isCurrentlyFollowed = currentPrefs.followedSources.any(
      (s) => s.id == event.source.id,
    );
    final List<Source> updatedFollowedSources;

    if (isCurrentlyFollowed) {
      updatedFollowedSources = List.from(currentPrefs.followedSources)
        ..removeWhere((s) => s.id == event.source.id);
    } else {
      updatedFollowedSources = List.from(currentPrefs.followedSources)
        ..add(event.source);
    }

    final updatedPrefs = currentPrefs.copyWith(
      followedSources: updatedFollowedSources,
    );

    try {
      final sortedPrefs = _sortPreferences(updatedPrefs);
      await _userContentPreferencesRepository.update(
        id: state.user!.id,
        item: sortedPrefs,
        userId: state.user!.id,
      );
      emit(
        state.copyWith(
          status: AccountStatus.success,
          preferences: sortedPrefs,
          clearError: true,
        ),
      );
    } on HttpException catch (e) {
      _logger.severe(
        'AccountFollowSourceToggled failed with HttpException: $e',
      );
      emit(state.copyWith(status: AccountStatus.failure, error: e));
    } catch (e, st) {
      _logger.severe(
        'AccountFollowSourceToggled failed with unexpected error: $e',
        e,
        st,
      );
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          error: OperationFailedException(
            'Failed to update followed sources: $e',
          ),
        ),
      );
    }
  }

  Future<void> _onAccountClearUserPreferences(
    AccountClearUserPreferences event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(status: AccountStatus.loading));
    try {
      // Create a new default preferences object to "clear" existing ones
      final defaultPreferences = UserContentPreferences(
        id: event.userId,
        followedCountries: const [],
        followedSources: const [],
        followedTopics: const [],
        savedHeadlines: const [],
      );
      await _userContentPreferencesRepository.update(
        id: event.userId,
        item: defaultPreferences,
        userId: event.userId,
      );
      emit(
        state.copyWith(
          status: AccountStatus.success,
          preferences: defaultPreferences,
          clearError: true,
        ),
      );
    } on HttpException catch (e) {
      _logger.severe(
        'AccountClearUserPreferences failed with HttpException: $e',
      );
      emit(state.copyWith(status: AccountStatus.failure, error: e));
    } catch (e, st) {
      _logger.severe(
        'AccountClearUserPreferences failed with unexpected error: $e',
        e,
        st,
      );
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          error: OperationFailedException(
            'Failed to clear user preferences: $e',
          ),
        ),
      );
    }
  }

  /// Sorts the lists within UserContentPreferences locally.
  ///
  /// This client-side sorting is necessary due to a backend limitation that
  /// does not support sorting for saved or followed content lists. This
  /// approach remains efficient as these lists are fetched all at once and
  /// are kept small by user account-type limits.
  UserContentPreferences _sortPreferences(UserContentPreferences preferences) {
    // Sort saved headlines by updatedAt descending (newest first)
    final sortedHeadlines = List<Headline>.from(preferences.savedHeadlines)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Sort followed topics by name ascending
    final sortedTopics = List<Topic>.from(preferences.followedTopics)
      ..sort((a, b) => a.name.compareTo(b.name));

    // Sort followed sources by name ascending
    final sortedSources = List<Source>.from(preferences.followedSources)
      ..sort((a, b) => a.name.compareTo(b.name));

    // Sort followed countries by name ascending
    final sortedCountries = List<Country>.from(preferences.followedCountries)
      ..sort((a, b) => a.name.compareTo(b.name));

    return preferences.copyWith(
      savedHeadlines: sortedHeadlines,
      followedTopics: sortedTopics,
      followedSources: sortedSources,
      followedCountries: sortedCountries,
    );
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    _userContentPreferencesSubscription.cancel();
    return super.close();
  }
}
