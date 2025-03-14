import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/headlines-feed/models/headline_filter.dart';

part 'headlines_feed_event.dart';
part 'headlines_feed_state.dart';

/// {@template headlines_feed_bloc}
/// A Bloc that manages the headlines feed.
///
/// It handles fetching and refreshing headlines data using the
/// [HtHeadlinesRepository].
/// {@endtemplate}
class HeadlinesFeedBloc extends Bloc<HeadlinesFeedEvent, HeadlinesFeedState> {
  /// {@macro headlines_feed_bloc}
  HeadlinesFeedBloc({required HtHeadlinesRepository headlinesRepository})
      : _headlinesRepository = headlinesRepository,
        super(HeadlinesFeedLoading()) {
    on<HeadlinesFeedFetchRequested>(
      _onHeadlinesFeedFetchRequested,
      transformer: sequential(),
    );
    on<HeadlinesFeedRefreshRequested>(
      _onHeadlinesFeedRefreshRequested,
      transformer: restartable(),
    );
    on<HeadlinesFeedFilterChanged>(
      _onHeadlinesFeedFilterChanged,
    );
  }

  final HtHeadlinesRepository _headlinesRepository;

  Future<void> _onHeadlinesFeedFilterChanged(
    HeadlinesFeedFilterChanged event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    emit(HeadlinesFeedLoading());
    try {
      final response = await _headlinesRepository.getHeadlines(
        limit: 20,
        category: event.category, // Pass category directly
        source: event.source, // Pass source directly
        eventCountry: event.eventCountry, // Pass eventCountry directly
      );
      final newFilter = (state is HeadlinesFeedLoaded)
          ? (state as HeadlinesFeedLoaded).filter.copyWith(
                category: event.category,
                source: event.source,
                eventCountry: event.eventCountry,
              )
          : HeadlineFilter(
              category: event.category,
              source: event.source,
              eventCountry: event.eventCountry,
            );
      emit(
        HeadlinesFeedLoaded(
          headlines: response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
          filter: newFilter,
        ),
      );
    } on HeadlinesFetchException catch (e) {
      emit(HeadlinesFeedError(message: e.message));
    } catch (_) {
      emit(const HeadlinesFeedError(message: 'An unexpected error occurred'));
    }
  }

  /// Handles [HeadlinesFeedFetchRequested] events.
  ///
  /// Fetches headlines from the repository and emits
  /// [HeadlinesFeedLoading], and either [HeadlinesFeedLoaded] or
  /// [HeadlinesFeedError] states.
  Future<void> _onHeadlinesFeedFetchRequested(
    HeadlinesFeedFetchRequested event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    if (state is HeadlinesFeedLoaded &&
        (state as HeadlinesFeedLoaded).hasMore) {
      final currentState = state as HeadlinesFeedLoaded;
      emit(HeadlinesFeedLoading());
      try {
        final response = await _headlinesRepository.getHeadlines(
          limit: 20,
          startAfterId: currentState.cursor,
          category: currentState.filter.category, // Use existing filter
          source: currentState.filter.source, // Use existing filter
          eventCountry: currentState.filter.eventCountry, // Use existing filter
        );
        emit(
          HeadlinesFeedLoaded(
            headlines: currentState.headlines + response.items,
            hasMore: response.hasMore,
            cursor: response.cursor,
            filter: currentState.filter,
          ),
        );
      } on HeadlinesFetchException catch (e) {
        emit(HeadlinesFeedError(message: e.message));
      } catch (_) {
        emit(const HeadlinesFeedError(message: 'An unexpected error occurred'));
      }
    } else {
      emit(HeadlinesFeedLoading());
      try {
        final response = await _headlinesRepository.getHeadlines(
          limit: 20,
          category: state is HeadlinesFeedLoaded
              ? (state as HeadlinesFeedLoaded).filter.category
              : null,
          source: state is HeadlinesFeedLoaded
              ? (state as HeadlinesFeedLoaded).filter.source
              : null,
          eventCountry: state is HeadlinesFeedLoaded
              ? (state as HeadlinesFeedLoaded).filter.eventCountry
              : null,
        );
        emit(
          HeadlinesFeedLoaded(
            headlines: response.items,
            hasMore: response.hasMore,
            cursor: response.cursor,
            filter: state is HeadlinesFeedLoaded
                ? (state as HeadlinesFeedLoaded).filter
                : const HeadlineFilter(),
          ),
        );
      } on HeadlinesFetchException catch (e) {
        emit(HeadlinesFeedError(message: e.message));
      } catch (_) {
        emit(const HeadlinesFeedError(message: 'An unexpected error occurred'));
      }
    }
  }

  /// Handles [HeadlinesFeedRefreshRequested] events.
  ///
  /// Fetches headlines from the repository and emits
  /// [HeadlinesFeedLoading], and either [HeadlinesFeedLoaded] or
  /// [HeadlinesFeedError] states.
  ///
  /// Uses `restartable` transformer to ensure that only the latest
  /// refresh request is processed.
  Future<void> _onHeadlinesFeedRefreshRequested(
    HeadlinesFeedRefreshRequested event,
    Emitter<HeadlinesFeedState> emit,
  ) async {
    emit(HeadlinesFeedLoading());
    try {
      final response = await _headlinesRepository.getHeadlines(
        limit: 20,
        category: state is HeadlinesFeedLoaded
            ? (state as HeadlinesFeedLoaded).filter.category
            : null,
        source: state is HeadlinesFeedLoaded
            ? (state as HeadlinesFeedLoaded).filter.source
            : null,
        eventCountry: state is HeadlinesFeedLoaded
            ? (state as HeadlinesFeedLoaded).filter.eventCountry
            : null,
      );
      emit(
        HeadlinesFeedLoaded(
          headlines: response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
          filter: state is HeadlinesFeedLoaded
              ? (state as HeadlinesFeedLoaded).filter
              : const HeadlineFilter(),
        ),
      );
    } on HeadlinesFetchException catch (e) {
      emit(HeadlinesFeedError(message: e.message));
    } catch (_) {
      emit(const HeadlinesFeedError(message: 'An unexpected error occurred'));
    }
  }
}
