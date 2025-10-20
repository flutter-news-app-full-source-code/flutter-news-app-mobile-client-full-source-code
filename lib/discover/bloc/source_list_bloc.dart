import 'dart:async';

import 'package:bloc/bloc.dart';
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
    on<SourceListStarted>(_onSourceListStarted);
    on<SourceListRefreshed>(_onSourceListRefreshed);
    on<SourceListLoadMoreRequested>(_onSourceListLoadMoreRequested);
    on<SourceListCountryFilterChanged>(_onSourceListCountryFilterChanged);
    on<SourceListFollowToggled>(_onSourceListFollowToggled);
  }

  final DataRepository<Source> _sourcesRepository;
  final DataRepository<Country> _countriesRepository;
  final AppBloc _appBloc;
  final ContentLimitationService _contentLimitationService;
  final Logger _logger;

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
      final [allCountries, sources] = await Future.wait([
        _countriesRepository.readAll(),
        _fetchSources(sourceType: event.sourceType),
      ]);

      emit(
        state.copyWith(
          status: SourceListStatus.success,
          allCountries: allCountries as List<Country>,
          sources: sources,
          hasMore: sources.length == _sourcesRepository.itemsPerPage,
        ),
      );
    } catch (e, s) {
      _logger.severe('[SourceListBloc] Failed to start source list.', e, s);
      emit(
        state.copyWith(status: SourceListStatus.failure, error: e as Exception),
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
        sourceType: state.sourceType!,
        countryIds: state.selectedCountries.map((c) => c.id).toSet(),
      );

      emit(
        state.copyWith(
          status: SourceListStatus.success,
          sources: sources,
          hasMore: sources.length == _sourcesRepository.itemsPerPage,
        ),
      );
    } catch (e, s) {
      _logger.severe('[SourceListBloc] Failed to refresh sources.', e, s);
      emit(
        state.copyWith(status: SourceListStatus.failure, error: e as Exception),
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
      final nextPage =
          (state.sources.length / _sourcesRepository.itemsPerPage).floor() + 1;
      final newSources = await _fetchSources(
        sourceType: state.sourceType!,
        countryIds: state.selectedCountries.map((c) => c.id).toSet(),
        page: nextPage,
      );

      emit(
        state.copyWith(
          status: SourceListStatus.success,
          sources: List.of(state.sources)..addAll(newSources),
          hasMore: newSources.length == _sourcesRepository.itemsPerPage,
        ),
      );
    } catch (e, s) {
      _logger.warning('[SourceListBloc] Failed to load more sources.', e, s);
      emit(
        state.copyWith(
          status: SourceListStatus.partialFailure,
          error: e as Exception,
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
        hasMore: true, // Reset pagination
      ),
    );

    try {
      final sources = await _fetchSources(
        sourceType: state.sourceType!,
        countryIds: event.selectedCountries.map((c) => c.id).toSet(),
      );

      emit(
        state.copyWith(
          status: SourceListStatus.success,
          sources: sources,
          hasMore: sources.length == _sourcesRepository.itemsPerPage,
        ),
      );
    } catch (e, s) {
      _logger.severe('[SourceListBloc] Failed to fetch with new filter.', e, s);
      emit(
        state.copyWith(status: SourceListStatus.failure, error: e as Exception),
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
  Future<List<Source>> _fetchSources({
    required SourceType sourceType,
    Set<String> countryIds = const {},
    int page = 1,
  }) {
    return _sourcesRepository.readAll(
      filter: {
        'sourceType': sourceType.name,
        if (countryIds.isNotEmpty) 'countryIds': countryIds.join(','),
      },
      page: page,
    );
  }
}
