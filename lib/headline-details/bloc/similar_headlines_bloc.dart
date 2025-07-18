import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_shared/ht_shared.dart'
    show Headline, HtHttpException, PaginationOptions;

part 'similar_headlines_event.dart';
part 'similar_headlines_state.dart';

class SimilarHeadlinesBloc
    extends Bloc<SimilarHeadlinesEvent, SimilarHeadlinesState> {
  SimilarHeadlinesBloc({
    required HtDataRepository<Headline> headlinesRepository,
  }) : _headlinesRepository = headlinesRepository,
       super(SimilarHeadlinesInitial()) {
    on<FetchSimilarHeadlines>(_onFetchSimilarHeadlines);
  }

  final HtDataRepository<Headline> _headlinesRepository;
  static const int _similarHeadlinesLimit = 5;

  Future<void> _onFetchSimilarHeadlines(
    FetchSimilarHeadlines event,
    Emitter<SimilarHeadlinesState> emit,
  ) async {
    emit(SimilarHeadlinesLoading());
    try {
      final currentHeadline = event.currentHeadline;

      final filter = <String, dynamic>{'topic.id': currentHeadline.topic.id};

      final response = await _headlinesRepository.readAll(
        filter: filter,
        pagination: const PaginationOptions(
          limit:
              _similarHeadlinesLimit +
              1, // Fetch one extra to check if current is there
        ),
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
    } on HtHttpException catch (e) {
      emit(SimilarHeadlinesError(message: e.message));
    } catch (e) {
      emit(SimilarHeadlinesError(message: 'An unexpected error occurred: $e'));
    }
  }
}
