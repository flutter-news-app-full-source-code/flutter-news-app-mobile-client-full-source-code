import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_shared/ht_shared.dart';

part 'available_topics_event.dart';
part 'available_topics_state.dart';

class AvailableTopicsBloc
    extends Bloc<AvailableTopicsEvent, AvailableTopicsState> {
  AvailableTopicsBloc({required HtDataRepository<Topic> topicsRepository})
      : _topicsRepository = topicsRepository,
        super(const AvailableTopicsState()) {
    on<FetchAvailableTopics>(_onFetchAvailableTopics);
  }

  final HtDataRepository<Topic> _topicsRepository;

  Future<void> _onFetchAvailableTopics(
    FetchAvailableTopics event,
    Emitter<AvailableTopicsState> emit,
  ) async {
    if (state.status == AvailableTopicsStatus.loading ||
        state.status == AvailableTopicsStatus.success) {
      return;
    }
    emit(state.copyWith(status: AvailableTopicsStatus.loading));
    try {
      final response = await _topicsRepository.readAll();
      emit(
        state.copyWith(
          status: AvailableTopicsStatus.success,
          availableTopics: response.items,
          clearError: true,
        ),
      );
    } on HtHttpException catch (e) {
      emit(
        state.copyWith(
          status: AvailableTopicsStatus.failure,
          error: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AvailableTopicsStatus.failure,
          error: 'An unexpected error occurred while fetching topics.',
        ),
      );
    }
  }
}
