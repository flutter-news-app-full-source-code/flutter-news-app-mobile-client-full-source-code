import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';

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
        super(HeadlinesFeedInitial()) {
    on<HeadlinesFeedFetchRequested>(
      _onHeadlinesFeedFetchRequested,
      transformer: sequential(),
    );
    on<HeadlinesFeedRefreshRequested>(
      _onHeadlinesFeedRefreshRequested,
      transformer: restartable(),
    );
  }

  final HtHeadlinesRepository _headlinesRepository;

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
        );
        emit(
          HeadlinesFeedLoaded(
            headlines: currentState.headlines + response.items,
            hasMore: response.hasMore,
            cursor: response.cursor,
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
        final response = await _headlinesRepository.getHeadlines(limit: 20);
        emit(
          HeadlinesFeedLoaded(
            headlines: response.items,
            hasMore: response.hasMore,
            cursor: response.cursor,
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
      final response = await _headlinesRepository.getHeadlines(limit: 20);
      emit(
        HeadlinesFeedLoaded(
          headlines: response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
        ),
      );
    } on HeadlinesFetchException catch (e) {
      emit(HeadlinesFeedError(message: e.message));
    } catch (_) {
      emit(const HeadlinesFeedError(message: 'An unexpected error occurred'));
    }
  }
}
