import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:logging/logging.dart';
import 'package:stream_transform/stream_transform.dart';

part 'headlines_search_event.dart';
part 'headlines_search_state.dart';

/// A transformer that debounces events to prevent rapid-fire processing.
///
/// This is particularly useful for search queries to avoid sending a request
/// for every keystroke.
EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

/// {@template headline_search_bloc}
/// Manages the state for the headline search feature.
///
/// This BLoC handles incoming search queries, debounces them, fetches
/// matching headlines from the repository, and emits the corresponding state.
/// {@endtemplate}
class HeadlineSearchBloc
    extends Bloc<HeadlineSearchEvent, HeadlineSearchState> {
  /// {@macro headline_search_bloc}
  HeadlineSearchBloc({
    required DataRepository<Headline> headlinesRepository,
    required AnalyticsService analyticsService,
  }) : _headlinesRepository = headlinesRepository,
       _analyticsService = analyticsService,
       _logger = Logger('HeadlineSearchBloc'),
       super(const HeadlineSearchState()) {
    on<HeadlineSearchQueryChanged>(
      _onHeadlineSearchQueryChanged,
      // Apply a debounce transformer to prevent excessive API calls.
      transformer: debounce(const Duration(milliseconds: 350)),
    );
  }

  final DataRepository<Headline> _headlinesRepository;
  final AnalyticsService _analyticsService;
  final Logger _logger;

  /// Handles the [HeadlineSearchQueryChanged] event.
  ///
  /// When the query changes, this method fetches headlines from the repository
  /// that match the query.
  Future<void> _onHeadlineSearchQueryChanged(
    HeadlineSearchQueryChanged event,
    Emitter<HeadlineSearchState> emit,
  ) async {
    final query = event.query;

    // If the query is empty or too short, reset to the initial state.
    // This prevents heavy, inefficient searches on the backend for 1 or 2
    // character queries.
    if (query.length < 3) {
      return emit(
        const HeadlineSearchState(status: HeadlineSearchStatus.initial),
      );
    }

    _logger.info('Searching for headlines with query: "$query"');

    // Emit loading state before starting the search.
    emit(state.copyWith(status: HeadlineSearchStatus.loading));

    try {
      // Fetch headlines from the repository using a regex filter for a
      // case-insensitive, partial match on the title.
      final response = await _headlinesRepository.readAll(
        filter: {
          'title': {
            // Use regex for partial matching.
            r'$regex': query,
            // 'i' option for case-insensitivity.
            r'$options': 'i',
          },
        },
        pagination: const PaginationOptions(limit: 20),
      );

      // Analytics: Track search performed
      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.searchPerformed,
          payload: SearchPerformedPayload(
            query: query,
            resultCount: response.items.length,
          ),
        ),
      );

      // On success, emit the new state with the fetched headlines.
      emit(
        state.copyWith(
          status: HeadlineSearchStatus.success,
          headlines: response.items,
        ),
      );
    } on HttpException catch (e) {
      emit(state.copyWith(status: HeadlineSearchStatus.failure, error: e));
    }
  }
}
