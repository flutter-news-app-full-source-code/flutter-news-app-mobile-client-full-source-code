import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:logging/logging.dart';

part 'source_list_event.dart';
part 'source_list_state.dart';

/// {@template source_list_bloc}
/// A BLoC that manages the state of the source list page.
///
/// This BLoC is responsible for fetching, paginating, and filtering sources
/// of a specific [SourceType]. It also handles follow/unfollow actions.
/// {@endtemplate}
class SourceListBloc extends Bloc<SourceListEvent, SourceListState> {
  /// {@macro source_list_bloc}
  SourceListBloc({
    required DataRepository<Source> sourcesRepository,
    required DataRepository<Country> countriesRepository,
    required AppBloc appBloc,
    required ContentLimitationService contentLimitationService,
    required Logger logger,
  }) : _sourcesRepository = sourcesRepository,
       _countriesRepository = countriesRepository,
       _appBloc = appBloc,
       _contentLimitationService = contentLimitationService,
       _logger = logger,
       super(const SourceListState()) {
    on<SourceListStarted>(_onSourceListStarted, transformer: droppable());
    on<SourceListRefreshed>(_onSourceListRefreshed, transformer: droppable());
    on<SourceListLoadMoreRequested>(
      _onSourceListLoadMoreRequested,
      transformer: droppable(),
    );
    on<SourceListCountryFilterChanged>(
      _onSourceListCountryFilterChanged,
      transformer: restartable(),
    );
    on<SourceListFollowToggled>(_onSourceListFollowToggled);
    on<SourceListCountriesLoadMoreRequested>(
      _onSourceListCountriesLoadMoreRequested,
      transformer: droppable(),
    );
  }

  final DataRepository<Source> _sourcesRepository;
  final DataRepository<Country> _countriesRepository;
  final AppBloc _appBloc;
  final ContentLimitationService _contentLimitationService;
  final Logger _logger;

  /// The number of sources to fetch per page.
  static const _pageSize = 20;

  /// The number of countries to fetch per page.
  static const _countriesPageSize = 20;

  /// Handles the initial loading of sources and filter data.
  Future<void> _onSourceListStarted(
    SourceListStarted event,
    Emitter<SourceListState> emit,
  ) async {
    _logger.fine('[SourceListBloc] SourceListStarted event received.');
    emit(
      state.copyWith(
        status: SourceListStatus.loading,
        sourceType: event.sourceType,
      ),
    );

    try {
      // Fetch all available countries for the filter UI and the first page
      // of sources concurrently.
      final results = await Future.wait([
        _countriesRepository.readAll(
          filter: {'hasActiveSources': true},
          sort: [const SortOption('name', SortOrder.asc)],
          pagination: const PaginationOptions(limit: _countriesPageSize),
        ),
        _fetchSources(sourceType: event.sourceType),
      ]);

      final countriesResponse = results[0] as PaginatedResponse<Country>;
      final countries = countriesResponse.items;
      final sources = results[1] as PaginatedResponse<Source>;

      emit(
        state.copyWith(
          status: SourceListStatus.success,
          countries: countries,
          sources: sources.items,
          countriesNextCursor: countriesResponse.cursor,
          nextCursor: sources.cursor,
        ),
      );
    } on HttpException catch (e, s) {
      _logger.severe('[SourceListBloc] Failed to start source list.', e, s);
      emit(state.copyWith(status: SourceListStatus.failure, error: e));
    } catch (e, s) {
      _logger.severe('[SourceListBloc] Failed to start source list.', e, s);
      emit(
        state.copyWith(
          status: SourceListStatus.failure,
          error: UnknownException('$e'),
        ),
      );
    }
  }

  /// Handles refreshing the list of sources.
  Future<void> _onSourceListRefreshed(
    SourceListRefreshed event,
    Emitter<SourceListState> emit,
  ) async {
    _logger.fine('[SourceListBloc] SourceListRefreshed event received.');
    emit(state.copyWith(status: SourceListStatus.loading));

    try {
      final sources = await _fetchSources(
        sourceType: state.sourceType,
        countryIds: state.selectedCountries.map((c) => c.id).toSet(),
      );

      emit(
        state.copyWith(
          status: SourceListStatus.success,
          sources: sources.items,
          nextCursor: sources.cursor,
        ),
      );
    } on HttpException catch (e, s) {
      _logger.severe('[SourceListBloc] Failed to refresh sources.', e, s);
      emit(state.copyWith(status: SourceListStatus.failure, error: e));
    } catch (e, s) {
      _logger.severe('[SourceListBloc] Failed to refresh sources.', e, s);
      emit(
        state.copyWith(
          status: SourceListStatus.failure,
          error: UnknownException('$e'),
        ),
      );
    }
  }

  /// Handles loading the next page of sources for infinite scrolling.
  Future<void> _onSourceListLoadMoreRequested(
    SourceListLoadMoreRequested event,
    Emitter<SourceListState> emit,
  ) async {
    if (!state.hasMore || state.status == SourceListStatus.loadingMore) return;

    _logger.fine('[SourceListBloc] Load more requested.');
    emit(state.copyWith(status: SourceListStatus.loadingMore));

    try {
      final newSources = await _fetchSources(
        sourceType: state.sourceType,
        countryIds: state.selectedCountries.map((c) => c.id).toSet(),
        cursor: state.nextCursor,
      );

      emit(
        state.copyWith(
          status: SourceListStatus.success,
          sources: List.of(state.sources)..addAll(newSources.items),
          nextCursor: newSources.cursor,
        ),
      );
    } on HttpException catch (e, s) {
      _logger.warning('[SourceListBloc] Failed to load more sources.', e, s);
      emit(state.copyWith(status: SourceListStatus.partialFailure, error: e));
    } catch (e, s) {
      _logger.warning('[SourceListBloc] Failed to load more sources.', e, s);
      emit(
        state.copyWith(
          status: SourceListStatus.partialFailure,
          error: UnknownException('$e'),
        ),
      );
    }
  }

  /// Handles changes to the country filter.
  Future<void> _onSourceListCountryFilterChanged(
    SourceListCountryFilterChanged event,
    Emitter<SourceListState> emit,
  ) async {
    _logger.fine('[SourceListBloc] Country filter changed.');
    emit(
      state.copyWith(
        status: SourceListStatus.loading,
        selectedCountries: event.selectedCountries,
        sources: [], // Clear existing sources
        nextCursor: null, // Reset pagination
      ),
    );

    try {
      final sources = await _fetchSources(
        sourceType: state.sourceType,
        countryIds: event.selectedCountries.map((c) => c.id).toSet(),
      );

      emit(
        state.copyWith(
          status: SourceListStatus.success,
          sources: sources.items,
          nextCursor: sources.cursor,
        ),
      );
    } on HttpException catch (e, s) {
      _logger.severe('[SourceListBloc] Failed to fetch with new filter.', e, s);
      emit(state.copyWith(status: SourceListStatus.failure, error: e));
    } catch (e, s) {
      _logger.severe('[SourceListBloc] Failed to fetch with new filter.', e, s);
      emit(
        state.copyWith(
          status: SourceListStatus.failure,
          error: UnknownException('$e'),
        ),
      );
    }
  }

  /// Handles toggling the follow status of a source.
  void _onSourceListFollowToggled(
    SourceListFollowToggled event,
    Emitter<SourceListState> emit,
  ) {
    _logger.fine('[SourceListBloc] Follow toggled for ${event.source.id}.');
    final preferences = _appBloc.state.userContentPreferences;
    if (preferences == null) {
      _logger.warning(
        '[SourceListBloc] Cannot toggle follow: preferences are null.',
      );
      return;
    }

    final isFollowing = preferences.followedSources.any(
      (s) => s.id == event.source.id,
    );

    // Only check limits when attempting to follow, not when unfollowing.
    if (!isFollowing) {
      final status = _contentLimitationService.checkAction(
        ContentAction.followSource,
      );
      if (status != LimitationStatus.allowed) {
        _logger.info('[SourceListBloc] Follow limit reached.');
        // The UI is responsible for showing the bottom sheet. The BLoC's job
        // is to not proceed with the action.
        return;
      }
    }

    final newFollowedSources = List<Source>.from(preferences.followedSources);
    if (isFollowing) {
      newFollowedSources.removeWhere((s) => s.id == event.source.id);
    } else {
      newFollowedSources.add(event.source);
    }

    // Dispatch the change to the central AppBloc.
    _appBloc.add(
      AppUserContentPreferencesChanged(
        preferences: preferences.copyWith(followedSources: newFollowedSources),
      ),
    );
  }

  /// A private helper to fetch sources from the repository with filters.
  Future<PaginatedResponse<Source>> _fetchSources({
    required SourceType? sourceType,
    Set<String> countryIds = const {},
    String? cursor,
  }) {
    if (sourceType == null) {
      throw ArgumentError.notNull('sourceType');
    }
    return _sourcesRepository.readAll(
      filter: {
        'sourceType': sourceType.name,
        if (countryIds.isNotEmpty) 'countryId': {r'$in': countryIds.toList()},
      },
      pagination: PaginationOptions(limit: _pageSize, cursor: cursor),
    );
  }

  /// Handles loading the next page of countries for infinite scrolling.
  Future<void> _onSourceListCountriesLoadMoreRequested(
    SourceListCountriesLoadMoreRequested event,
    Emitter<SourceListState> emit,
  ) async {
    if (!state.countriesHasMore ||
        state.status == SourceListStatus.loadingMoreCountries)
      return;

    _logger.fine('Load more countries for source list filter requested.');
    emit(state.copyWith(status: SourceListStatus.loadingMoreCountries));

    try {
      final newCountriesResponse = await _countriesRepository.readAll(
        filter: {'hasActiveSources': true},
        sort: [const SortOption('name', SortOrder.asc)],
        pagination: PaginationOptions(
          limit: _countriesPageSize,
          cursor: state.countriesNextCursor,
        ),
      );

      emit(
        state.copyWith(
          status: SourceListStatus.success,
          countries: List.of(state.countries)
            ..addAll(newCountriesResponse.items),
          countriesNextCursor: newCountriesResponse.cursor,
        ),
      );
    } on HttpException catch (e, s) {
      _logger.warning(
        'Failed to load more countries for source list filter.',
        e,
        s,
      );
      emit(
        state.copyWith(
          status: SourceListStatus.partialCountriesFailure,
          error: e,
        ),
      );
    } catch (e, s) {
      _logger.severe(
        'Unexpected error loading more countries for source list filter.',
        e,
        s,
      );
      emit(
        state.copyWith(
          status: SourceListStatus.failure,
          error: UnknownException('$e'),
        ),
      );
    }
  }
}
