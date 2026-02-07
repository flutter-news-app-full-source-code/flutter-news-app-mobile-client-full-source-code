import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
// Import AppBloc with an alias to resolve the name collision between
// the local `SavedHeadlineFiltersReordered` event and the one in AppBloc.
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart'
    as app_bloc;
import 'package:logging/logging.dart';

part 'saved_headlines_filters_event.dart';
part 'saved_headlines_filters_state.dart';

/// {@template saved_headlines_filters_bloc}
/// Manages the state for the saved headlines filters management page.
///
/// This BLoC is responsible for loading the list of saved filters, and for
/// handling user actions like reordering and deleting filters. It coordinates
/// with the global [AppBloc] to persist these changes.
/// {@endtemplate}
class SavedHeadlinesFiltersBloc
    extends Bloc<SavedHeadlinesFiltersEvent, SavedHeadlinesFiltersState> {
  /// {@macro saved_headlines_filters_bloc}
  SavedHeadlinesFiltersBloc({required app_bloc.AppBloc appBloc})
    : _appBloc = appBloc,
      _logger = Logger('SavedHeadlinesFiltersBloc'),
      super(const SavedHeadlinesFiltersState()) {
    on<SavedHeadlinesFiltersDataLoaded>(
      _onDataLoaded,
      transformer: restartable(),
    );
    on<SavedHeadlinesFiltersReordered>(
      _onFiltersReordered,
      transformer: sequential(),
    );
    on<SavedHeadlinesFiltersDeleted>(
      _onFilterDeleted,
      transformer: sequential(),
    );

    // Listen to the AppBloc for changes to the saved filters list.
    _appBlocSubscription = _appBloc.stream.listen((app_bloc.AppState appState) {
      if (appState.userContentPreferences?.savedHeadlineFilters != null &&
          appState.userContentPreferences!.savedHeadlineFilters !=
              state.filters) {
        // If the global list changes, update this BLoC's state.
        add(const SavedHeadlinesFiltersDataLoaded());
      }
    });

    // Load initial data.
    add(const SavedHeadlinesFiltersDataLoaded());
  }

  final app_bloc.AppBloc _appBloc;
  final Logger _logger;
  late final StreamSubscription<app_bloc.AppState> _appBlocSubscription;

  /// Handles loading the initial list of saved filters from the AppBloc.
  void _onDataLoaded(
    SavedHeadlinesFiltersDataLoaded event,
    Emitter<SavedHeadlinesFiltersState> emit,
  ) {
    _logger.fine('Loading saved headline filters from AppBloc.');
    final filters =
        _appBloc.state.userContentPreferences?.savedHeadlineFilters ?? [];
    emit(
      SavedHeadlinesFiltersState(
        status: SavedHeadlinesFiltersStatus.success,
        filters: filters,
      ),
    );
    _logger.info(
      'Loaded ${filters.length} saved headline filters from AppBloc.',
    );
  }

  /// Handles reordering the filters and dispatches an update to the AppBloc.
  void _onFiltersReordered(
    SavedHeadlinesFiltersReordered event,
    Emitter<SavedHeadlinesFiltersState> emit,
  ) {
    _logger.fine('Reordering saved headline filters.');
    // Optimistically update the UI.
    emit(state.copyWith(filters: event.reorderedFilters));
    // Dispatch the event to the AppBloc to persist the change.
    // The `app_bloc` alias is used here to explicitly dispatch the event
    // defined in `app_event.dart`, not the local one.
    _appBloc.add(
      app_bloc.SavedHeadlineFiltersReordered(
        reorderedFilters: event.reorderedFilters,
      ),
    );
  }

  /// Handles deleting a filter and dispatches an update to the AppBloc.
  void _onFilterDeleted(
    SavedHeadlinesFiltersDeleted event,
    Emitter<SavedHeadlinesFiltersState> emit,
  ) {
    _logger.fine('Deleting saved headline filter with id: ${event.filterId}');
    // Dispatch the event to the AppBloc to persist the change.
    // The `app_bloc` alias is used here to explicitly dispatch the event
    // defined in `app_event.dart`.
    _appBloc.add(app_bloc.SavedHeadlineFilterDeleted(filterId: event.filterId));
    _logger.info(
      'Dispatched delete event to AppBloc for filter id: ${event.filterId}',
    );
  }

  @override
  Future<void> close() {
    _appBlocSubscription.cancel();
    return super.close();
  }
}
