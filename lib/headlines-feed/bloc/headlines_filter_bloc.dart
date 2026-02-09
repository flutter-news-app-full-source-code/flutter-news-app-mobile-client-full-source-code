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
class HeadlinesFilterBloc
    extends Bloc<HeadlinesFilterEvent, HeadlinesFilterState> {
  /// {@macro headlines_filter_bloc}
  ///
  /// Requires repositories for topics, sources, and countries, as well as
  /// the [AppBloc] to access user content preferences.
  HeadlinesFilterBloc({
    required DataRepository<Topic> topicsRepository,
    required DataRepository<Source> sourcesRepository,
    required DataRepository<Country> countriesRepository,
  }) : _topicsRepository = topicsRepository,
       _sourcesRepository = sourcesRepository,
       _countriesRepository = countriesRepository,
       _logger = Logger('HeadlinesFilterBloc'),
       super(const HeadlinesFilterState()) {
    on<FilterDataLoaded>(_onFilterDataLoaded, transformer: restartable());
    on<FilterTopicToggled>(_onFilterTopicToggled);
    on<FilterSourceToggled>(_onFilterSourceToggled);
    on<FilterCountryToggled>(_onFilterCountryToggled);
    on<FilterSelectionsCleared>(_onFilterSelectionsCleared);
    on<FilterSourceCriteriaChanged>(_onFilterSourceCriteriaChanged);
  }

  final DataRepository<Topic> _topicsRepository;
  final DataRepository<Source> _sourcesRepository;
  final DataRepository<Country> _countriesRepository;
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
      // Use Future.wait to fetch all data in parallel for better performance.
      final [
        allTopicsResponse,
        allSourcesResponse,
        allEventCountriesResponse,
        allHeadquarterCountriesResponse,
      ] = await Future.wait([
        _topicsRepository.readAll(
          filter: {'status': ContentStatus.active.name},
          sort: [const SortOption('name', SortOrder.asc)],
        ),
        _sourcesRepository.readAll(
          filter: {'status': ContentStatus.active.name},
          sort: [const SortOption('name', SortOrder.asc)],
        ),
        // Fetch countries for headline events (only those with active sources).
        _countriesRepository.readAll(
          filter: {'hasActiveSources': true},
          sort: [const SortOption('name', SortOrder.asc)],
        ),
        // Fetch all countries for source headquarters filter (no filter).
        _countriesRepository.readAll(
          sort: [const SortOption('name', SortOrder.asc)],
        ),
      ]);

      emit(
        state.copyWith(
          status: HeadlinesFilterStatus.success,
          allTopics: (allTopicsResponse as PaginatedResponse<Topic>).items,
          allSources: (allSourcesResponse as PaginatedResponse<Source>).items,
          allCountries:
              (allEventCountriesResponse as PaginatedResponse<Country>).items,
          allHeadquarterCountries:
              (allHeadquarterCountriesResponse as PaginatedResponse<Country>)
                  .items,
          allSourceTypes: SourceType.values,
          selectedTopics: Set.from(event.initialSelectedTopics),
          selectedSources: Set.from(event.initialSelectedSources),
          selectedCountries: Set.from(event.initialSelectedCountries),
          clearError: true,
        ),
      );
      _logger.info(
        'Successfully loaded filter data with ${state.allTopics.length} topics, '
        '${state.allSources.length} sources, and ${state.allCountries.length} countries.',
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
    _logger.finer(
      'Toggling topic "${event.topic.name}" to ${event.isSelected}.',
    );
    if (event.isSelected) {
      updatedSelectedTopics.add(event.topic);
    } else {
      updatedSelectedTopics.remove(event.topic);
    }
    emit(state.copyWith(selectedTopics: updatedSelectedTopics));
  }

  /// Handles the [FilterSourceToggled] event, updating the selected sources.
  void _onFilterSourceToggled(
    FilterSourceToggled event,
    Emitter<HeadlinesFilterState> emit,
  ) {
    final updatedSelectedSources = Set<Source>.from(state.selectedSources);
    _logger.finer(
      'Toggling source "${event.source.name}" to ${event.isSelected}.',
    );
    if (event.isSelected) {
      updatedSelectedSources.add(event.source);
    } else {
      updatedSelectedSources.remove(event.source);
    }
    emit(state.copyWith(selectedSources: updatedSelectedSources));
  }

  /// Handles the [FilterCountryToggled] event, updating the selected countries.
  void _onFilterCountryToggled(
    FilterCountryToggled event,
    Emitter<HeadlinesFilterState> emit,
  ) {
    final updatedSelectedCountries = Set<Country>.from(state.selectedCountries);
    _logger.finer(
      'Toggling country "${event.country.name}" to ${event.isSelected}.',
    );
    if (event.isSelected) {
      updatedSelectedCountries.add(event.country);
    } else {
      updatedSelectedCountries.remove(event.country);
    }
    emit(state.copyWith(selectedCountries: updatedSelectedCountries));
  }

  /// Handles the [FilterSelectionsCleared] event, clearing all filter selections.
  void _onFilterSelectionsCleared(
    FilterSelectionsCleared event,
    Emitter<HeadlinesFilterState> emit,
  ) {
    _logger.info('Clearing all filter selections.');
    emit(
      state.copyWith(
        selectedTopics: {},
        selectedSources: {},
        selectedCountries: {},
      ),
    );
  }

  /// Handles the [FilterSourceCriteriaChanged] event, updating the UI-only
  /// filter criteria for the source list.
  void _onFilterSourceCriteriaChanged(
    FilterSourceCriteriaChanged event,
    Emitter<HeadlinesFilterState> emit,
  ) {
    _logger.finer(
      'Updating source filter criteria. Countries: ${event.selectedCountries?.length}, Types: ${event.selectedSourceTypes?.length}',
    );
    emit(
      state.copyWith(
        selectedSourceHeadquarterCountries:
            event.selectedCountries ?? state.selectedSourceHeadquarterCountries,
        selectedSourceTypes:
            event.selectedSourceTypes ?? state.selectedSourceTypes,
      ),
    );
  }
}
