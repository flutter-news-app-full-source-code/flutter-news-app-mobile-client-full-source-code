import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:ht_categories_client/ht_categories_client.dart';
import 'package:ht_categories_repository/ht_categories_repository.dart';
// For PaginatedResponse

part 'categories_filter_event.dart';
part 'categories_filter_state.dart';

/// {@template categories_filter_bloc}
/// Manages the state for fetching and displaying categories for filtering.
///
/// Handles initial fetching and pagination of categories using the
/// provided [HtCategoriesRepository].
/// {@endtemplate}
class CategoriesFilterBloc
    extends Bloc<CategoriesFilterEvent, CategoriesFilterState> {
  /// {@macro categories_filter_bloc}
  ///
  /// Requires a [HtCategoriesRepository] to interact with the data layer.
  CategoriesFilterBloc({required HtCategoriesRepository categoriesRepository})
    : _categoriesRepository = categoriesRepository,
      super(const CategoriesFilterState()) {
    on<CategoriesFilterRequested>(
      _onCategoriesFilterRequested,
      transformer: restartable(), // Only process the latest request
    );
    on<CategoriesFilterLoadMoreRequested>(
      _onCategoriesFilterLoadMoreRequested,
      transformer: droppable(), // Ignore new requests while one is processing
    );
  }

  final HtCategoriesRepository _categoriesRepository;

  /// Number of categories to fetch per page.
  static const _categoriesLimit = 20;

  /// Handles the initial request to fetch categories.
  Future<void> _onCategoriesFilterRequested(
    CategoriesFilterRequested event,
    Emitter<CategoriesFilterState> emit,
  ) async {
    // Prevent fetching if already loading or successful (unless forced refresh)
    if (state.status == CategoriesFilterStatus.loading ||
        state.status == CategoriesFilterStatus.success) {
      // Optionally add logic here for forced refresh if needed
      return;
    }

    emit(state.copyWith(status: CategoriesFilterStatus.loading));

    try {
      final response = await _categoriesRepository.getCategories(
        limit: _categoriesLimit,
      );
      emit(
        state.copyWith(
          status: CategoriesFilterStatus.success,
          categories: response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
          clearError: true, // Clear any previous error
        ),
      );
    } on GetCategoriesFailure catch (e) {
      emit(state.copyWith(status: CategoriesFilterStatus.failure, error: e));
    } catch (e) {
      // Catch unexpected errors
      emit(state.copyWith(status: CategoriesFilterStatus.failure, error: e));
    }
  }

  /// Handles the request to load more categories for pagination.
  Future<void> _onCategoriesFilterLoadMoreRequested(
    CategoriesFilterLoadMoreRequested event,
    Emitter<CategoriesFilterState> emit,
  ) async {
    // Only proceed if currently successful and has more items
    if (state.status != CategoriesFilterStatus.success || !state.hasMore) {
      return;
    }

    emit(state.copyWith(status: CategoriesFilterStatus.loadingMore));

    try {
      final response = await _categoriesRepository.getCategories(
        limit: _categoriesLimit,
        startAfterId: state.cursor, // Use the cursor from the current state
      );
      emit(
        state.copyWith(
          status: CategoriesFilterStatus.success,
          // Append new categories to the existing list
          categories: List.of(state.categories)..addAll(response.items),
          hasMore: response.hasMore,
          cursor: response.cursor,
        ),
      );
    } on GetCategoriesFailure catch (e) {
      // Keep existing data but indicate failure
      emit(
        state.copyWith(
          status:
              CategoriesFilterStatus
                  .failure, // Or a specific 'loadMoreFailure' status?
          error: e,
        ),
      );
    } catch (e) {
      // Catch unexpected errors
      emit(state.copyWith(status: CategoriesFilterStatus.failure, error: e));
    }
  }
}
