import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:logging/logging.dart';

part 'headlines_filter_event.dart';
part 'headlines_filter_state.dart';

/// {@template headlines_filter_bloc}
/// Manages the state for the centralized headlines filter feature.
///
/// This BLoC is responsible for fetching all available filter options
/// (topics, sources, countries) and managing the user's temporary selections
/// as they interact with the filter UI. It also integrates with the [AppBloc]
/// to access user-specific content preferences for "followed items" functionality.
/// {@endtemplate}
class HeadlinesFilterBloc extends Bloc<HeadlinesFilterEvent, HeadlinesFilterState> {
  /// {@macro headlines_filter_bloc}
  ///
  /// Requires repositories for topics, sources, and countries, as well as
  /// the [AppBloc] to access user content preferences.
  HeadlinesFilterBloc({
    required DataRepository<Topic> topicsRepository,
    required DataRepository<Source> sourcesRepository,
    required DataRepository<Country> countriesRepository,
    required AppBloc appBloc,
  })  : _topicsRepository = topicsRepository,
        _sourcesRepository = sourcesRepository,
        _countriesRepository = countriesRepository,
        _appBloc = appBloc,
        _logger = Logger('HeadlinesFilterBloc'),
        super(const HeadlinesFilterState()) {
    on<FilterDataLoaded>(_onFilterDataLoaded, transformer: restartable());
    on<FilterTopicToggled>(_onFilterTopicToggled);
    on<FilterSourceToggled>(_onFilterSourceToggled);
    on<FilterCountryToggled>(_onFilterCountryToggled);
    on<FollowedItemsFilterToggled>(_onFollowedItemsFilterToggled);
    on<FilterSelectionsCleared>(_onFilterSelectionsCleared);
  }

  final DataRepository<Topic> _topicsRepository;
  final DataRepository<Source> _sourcesRepository;
  final DataRepository<Country> _countriesRepository;
  final AppBloc _appBloc;
  final Logger _logger;

  /// Handles the [FilterDataLoaded] event, fetching all necessary filter data.
  ///
  /// This method fetches all available topics, sources, and countries.
  /// It also initializes the selected items based on the `initialSelected`
  /// lists provided in the event, typically from the current filter state
  /// of the `HeadlinesFeedBloc`.
  Future<void> _onFilterDataLoaded(
    FilterDataLoaded event,
    Emitter<HeadlinesFilterState> emit,
  ) async {
    if (state.status == HeadlinesFilterStatus.loading ||
        state.status == HeadlinesFilterStatus.success) {
      return;
    }

    emit(state.copyWith(status: HeadlinesFilterStatus.loading));

    try {
      final allTopicsResponse = await _topicsRepository.readAll(
        sort: [const SortOption('name', SortOrder.asc)],
      );
      final allSourcesResponse = await _sourcesRepository.readAll(
        sort: [const SortOption('name', SortOrder.asc)],
      );
      final allCountriesResponse = await _countriesRepository.readAll(
        filter: {'hasActiveSources': true}, // Only countries with active sources
        sort: [const SortOption('name', SortOrder.asc)],
      );

      emit(
        state.copyWith(
          status: HeadlinesFilterStatus.success,
          allTopics: allTopicsResponse.items,
          allSources: allSourcesResponse.items,
          allCountries: allCountriesResponse.items,
          selectedTopics: Set.from(event.initialSelectedTopics),
          selectedSources: Set.from(event.initialSelectedSources),
          selectedCountries: Set.from(event.initialSelectedCountries),
          isUsingFollowedItems: event.isUsingFollowedItems,
          clearError: true,
        ),
      );
    } on HttpException catch (e) {
      _logger.severe('Failed to load filter data (HttpException): $e');
      emit(state.copyWith(status: HeadlinesFilterStatus.failure, error: e));
    } catch (e, s) {
      _logger.severe('Unexpected error loading filter data.', e, s);
      emit(
        state.copyWith(
          status: HeadlinesFilterStatus.failure,
          error: UnknownException(e.toString()),
        ),
      );
    }
  }

  /// Handles the [FilterTopicToggled] event, updating the selected topics.
  void _onFilterTopicToggled(
    FilterTopicToggled event,
    Emitter<HeadlinesFilterState> emit,
  ) {
    final updatedSelectedTopics = Set<Topic>.from(state.selectedTopics);
    if (event.isSelected) {
      updatedSelectedTopics.add(event.topic);
    } else {
      updatedSelectedTopics.remove(event.topic);
    }
    emit(
      state.copyWith(
        selectedTopics: updatedSelectedTopics,
        isUsingFollowedItems: false, // Toggling individual item clears followed filter
      ),
    );
  }

  /// Handles the [FilterSourceToggled] event, updating the selected sources.
  void _onFilterSourceToggled(
    FilterSourceToggled event,
    Emitter<HeadlinesFilterState> emit,
  ) {
    final updatedSelectedSources = Set<Source>.from(state.selectedSources);
    if (event.isSelected) {
      updatedSelectedSources.add(event.source);
    } else {
      updatedSelectedSources.remove(event.source);
    }
    emit(
      state.copyWith(
        selectedSources: updatedSelectedSources,
        isUsingFollowedItems: false, // Toggling individual item clears followed filter
      ),
    );
  }

  /// Handles the [FilterCountryToggled] event, updating the selected countries.
  void _onFilterCountryToggled(
    FilterCountryToggled event,
    Emitter<HeadlinesFilterState> emit,
  ) {
    final updatedSelectedCountries = Set<Country>.from(state.selectedCountries);
    if (event.isSelected) {
      updatedSelectedCountries.add(event.country);
    } else {
      updatedSelectedCountries.remove(event.country);
    }
    emit(
      state.copyWith(
        selectedCountries: updatedSelectedCountries,
        isUsingFollowedItems: false, // Toggling individual item clears followed filter
      ),
    );
  }

  /// Handles the [FollowedItemsFilterToggled] event, applying or clearing
  /// followed items as filters.
  void _onFollowedItemsFilterToggled(
    FollowedItemsFilterToggled event,
    Emitter<HeadlinesFilterState> emit,
  ) {
    if (event.isUsingFollowedItems) {
      final userPreferences = _appBloc.state.userContentPreferences;
      emit(
        state.copyWith(
          selectedTopics: Set.from(userPreferences?.followedTopics ?? []),
          selectedSources: Set.from(userPreferences?.followedSources ?? []),
          selectedCountries: Set.from(userPreferences?.followedCountries ?? []),
          isUsingFollowedItems: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedTopics: {},
          selectedSources: {},
          selectedCountries: {},
          isUsingFollowedItems: false,
        ),
      );
    }
  }

  /// Handles the [FilterSelectionsCleared] event, clearing all filter selections.
  void _onFilterSelectionsCleared(
    FilterSelectionsCleared event,
    Emitter<HeadlinesFilterState> emit,
  ) {
    emit(
      state.copyWith(
        selectedTopics: {},
        selectedSources: {},
        selectedCountries: {},
        isUsingFollowedItems: false,
      ),
    );
  }
}
