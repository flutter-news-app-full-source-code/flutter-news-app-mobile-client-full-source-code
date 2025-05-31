import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_shared/ht_shared.dart'
    show Headline, HtHttpException, NotFoundException;

part 'headline_details_event.dart';
part 'headline_details_state.dart';

class HeadlineDetailsBloc
    extends Bloc<HeadlineDetailsEvent, HeadlineDetailsState> {
  HeadlineDetailsBloc({required HtDataRepository<Headline> headlinesRepository})
    : _headlinesRepository = headlinesRepository,
      super(HeadlineDetailsInitial()) {
    on<FetchHeadlineById>(_onFetchHeadlineById);
    on<HeadlineProvided>(_onHeadlineProvided);
  }

  final HtDataRepository<Headline> _headlinesRepository;

  Future<void> _onFetchHeadlineById(
    FetchHeadlineById event,
    Emitter<HeadlineDetailsState> emit,
  ) async {
    emit(HeadlineDetailsLoading());
    try {
      final headline = await _headlinesRepository.read(id: event.headlineId);
      emit(HeadlineDetailsLoaded(headline: headline));
    } on NotFoundException catch (e) {
      emit(HeadlineDetailsFailure(message: e.message));
    } on HtHttpException catch (e) {
      emit(HeadlineDetailsFailure(message: e.message));
    } catch (e) {
      emit(HeadlineDetailsFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  void _onHeadlineProvided(
    HeadlineProvided event,
    Emitter<HeadlineDetailsState> emit,
  ) {
    emit(HeadlineDetailsLoaded(headline: event.headline));
  }
}
