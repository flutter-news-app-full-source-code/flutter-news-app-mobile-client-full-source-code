import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';

part 'discover_event.dart';
part 'discover_state.dart';

/// {@template discover_bloc}
/// A BLoC that manages the state of the discover feature.
///
/// This BLoC is responsible for fetching all available news sources and
/// grouping them by their respective [SourceType] for display on the
/// discover page.
/// {@endtemplate}
class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  /// {@macro discover_bloc}
  DiscoverBloc({
    required DataRepository<Source> sourcesRepository,
    required Logger logger,
  }) : _sourcesRepository = sourcesRepository,
       _logger = logger,
       super(const DiscoverState()) {
    on<DiscoverStarted>(_onDiscoverStarted);
  }

  final DataRepository<Source> _sourcesRepository;
  final Logger _logger;

  /// Handles the initial fetching and grouping of all sources.
  ///
  /// When [DiscoverStarted] is added, this method fetches all sources from
  /// the repository, groups them into a map by [SourceType], and emits
  /// a success or failure state.
  Future<void> _onDiscoverStarted(
    DiscoverStarted event,
    Emitter<DiscoverState> emit,
  ) async {
    _logger.fine('[DiscoverBloc] DiscoverStarted event received.');
    emit(state.copyWith(status: DiscoverStatus.loading));

    try {
      // Fetch all available sources from the repository.
      final sourcesResponse = await _sourcesRepository.readAll();
      _logger.info(
        '[DiscoverBloc] Successfully fetched ${sourcesResponse.items.length} sources.',
      );

      // Group the fetched sources by their sourceType.
      final groupedSources = groupBy<Source, SourceType>(
        sourcesResponse.items,
        (source) => source.sourceType,
      );

      emit(
        state.copyWith(
          status: DiscoverStatus.success,
          groupedSources: groupedSources,
        ),
      );
    } on HttpException catch (e, s) {
      _logger.severe('[DiscoverBloc] Failed to fetch sources.', e, s);
      emit(state.copyWith(status: DiscoverStatus.failure, error: e));
    } catch (e, s) {
      _logger.severe('[DiscoverBloc] Failed to fetch sources.', e, s);
      emit(
        state.copyWith(
          status: DiscoverStatus.failure,
          error: UnknownException('An unexpected error occurred: $e'),
        ),
      );
    }
  }
}
