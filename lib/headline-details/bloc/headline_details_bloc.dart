import 'dart:async'; // Ensure async is imported

import 'package:bloc/bloc.dart';
import 'package:ht_headlines_client/ht_headlines_client.dart'; // Import for Headline and Exceptions
import 'package:ht_headlines_repository/ht_headlines_repository.dart';

part 'headline_details_event.dart';
part 'headline_details_state.dart';

class HeadlineDetailsBloc
    extends Bloc<HeadlineDetailsEvent, HeadlineDetailsState> {
  HeadlineDetailsBloc({required HtHeadlinesRepository headlinesRepository})
    : _headlinesRepository = headlinesRepository,
      super(HeadlineDetailsInitial()) {
    on<HeadlineDetailsRequested>(_onHeadlineDetailsRequested);
  }

  final HtHeadlinesRepository _headlinesRepository;

  Future<void> _onHeadlineDetailsRequested(
    HeadlineDetailsRequested event,
    Emitter<HeadlineDetailsState> emit,
  ) async {
    emit(HeadlineDetailsLoading());
    try {
      final headline = await _headlinesRepository.getHeadline(
        id: event.headlineId,
      );
      emit(HeadlineDetailsLoaded(headline: headline!));
    } on HeadlineNotFoundException catch (e) {
      emit(HeadlineDetailsFailure(message: e.message));
    } on HeadlinesFetchException catch (e) {
      emit(HeadlineDetailsFailure(message: e.message));
    } catch (e) {
      emit(HeadlineDetailsFailure(message: 'An unexpected error occurred: $e'));
    }
  }
}
