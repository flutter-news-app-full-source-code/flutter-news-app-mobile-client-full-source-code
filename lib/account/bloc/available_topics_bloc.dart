import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';

part 'available_topics_event.dart';
part 'available_topics_state.dart';

class AvailableTopicsBloc
    extends Bloc<AvailableTopicsEvent, AvailableTopicsState> {
  AvailableTopicsBloc({required DataRepository<Topic> topicsRepository})
    : _topicsRepository = topicsRepository,
      super(const AvailableTopicsState()) {
    on<FetchAvailableTopics>(_onFetchAvailableTopics);
  }

  final DataRepository<Topic> _topicsRepository;

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
      // TODO(fulleni): Add pagination if necessary for very large datasets.
      final response = await _topicsRepository.readAll(
        sort: [const SortOption('name', SortOrder.asc)],
      );
      emit(
        state.copyWith(
          status: AvailableTopicsStatus.success,
          availableTopics: response.items,
          clearError: true,
        ),
      );
    } on HttpException catch (e) {
      emit(
        state.copyWith(status: AvailableTopicsStatus.failure, error: e.message),
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
