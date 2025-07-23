import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart' show Headline, HttpException, UnknownException;
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';

part 'headline_details_event.dart';
part 'headline_details_state.dart';

class HeadlineDetailsBloc
    extends Bloc<HeadlineDetailsEvent, HeadlineDetailsState> {
  HeadlineDetailsBloc({required DataRepository<Headline> headlinesRepository})
    : _headlinesRepository = headlinesRepository,
      super(HeadlineDetailsInitial()) {
    on<FetchHeadlineById>(_onFetchHeadlineById);
    on<HeadlineProvided>(_onHeadlineProvided);
  }

  final DataRepository<Headline> _headlinesRepository;

  Future<void> _onFetchHeadlineById(
    FetchHeadlineById event,
    Emitter<HeadlineDetailsState> emit,
  ) async {
    emit(HeadlineDetailsLoading());
    try {
      final headline = await _headlinesRepository.read(id: event.headlineId);
      emit(HeadlineDetailsLoaded(headline: headline));
    } on HttpException catch (e) {
      emit(HeadlineDetailsFailure(exception: e));
    } catch (e) {
      emit(
        HeadlineDetailsFailure(
          exception: UnknownException('An unexpected error occurred: $e'),
        ),
      );
    }
  }

  void _onHeadlineProvided(
    HeadlineProvided event,
    Emitter<HeadlineDetailsState> emit,
  ) {
    emit(HeadlineDetailsLoaded(headline: event.headline));
  }
}
