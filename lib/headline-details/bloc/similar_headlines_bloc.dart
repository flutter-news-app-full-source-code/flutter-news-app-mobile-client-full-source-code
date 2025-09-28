import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart'
    show
        ContentStatus,
        Headline,
        HttpException,
        PaginationOptions,
        SortOption,
        SortOrder;
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';

part 'similar_headlines_event.dart';
part 'similar_headlines_state.dart';

class SimilarHeadlinesBloc
    extends Bloc<SimilarHeadlinesEvent, SimilarHeadlinesState> {
  SimilarHeadlinesBloc({required DataRepository<Headline> headlinesRepository})
    : _headlinesRepository = headlinesRepository,
      super(SimilarHeadlinesInitial()) {
    on<FetchSimilarHeadlines>(_onFetchSimilarHeadlines);
  }

  final DataRepository<Headline> _headlinesRepository;
  static const int _similarHeadlinesLimit = 5;

  Future<void> _onFetchSimilarHeadlines(
    FetchSimilarHeadlines event,
    Emitter<SimilarHeadlinesState> emit,
  ) async {
    emit(SimilarHeadlinesLoading());
    try {
      final currentHeadline = event.currentHeadline;

      // Filter by topic ID and ensure only active headlines are fetched.
      final filter = <String, dynamic>{
        'topic.id': currentHeadline.topic.id,
        'status': ContentStatus.active.name,
      };

      final response = await _headlinesRepository.readAll(
        filter: filter,
        sort: [const SortOption('updatedAt', SortOrder.desc)],
        // Fetch one extra to check if current is there
        pagination: const PaginationOptions(limit: _similarHeadlinesLimit + 1),
      );

      // Filter out the current headline from the results
      final similarHeadlines = response.items
          .where((headline) => headline.id != currentHeadline.id)
          .toList();

      // Take only the required limit after filtering
      final finalSimilarHeadlines = similarHeadlines
          .take(_similarHeadlinesLimit)
          .toList();

      if (finalSimilarHeadlines.isEmpty) {
        emit(SimilarHeadlinesEmpty());
      } else {
        emit(SimilarHeadlinesLoaded(similarHeadlines: finalSimilarHeadlines));
      }
    } on HttpException catch (e) {
      emit(SimilarHeadlinesError(message: e.message));
    } catch (e) {
      emit(SimilarHeadlinesError(message: 'An unexpected error occurred: $e'));
    }
  }
}
