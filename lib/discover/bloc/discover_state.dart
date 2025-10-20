part of 'discover_bloc.dart';

/// The status of the [DiscoverBloc].
enum DiscoverStatus {
  /// The initial state.
  initial,

  /// The state when loading data.
  loading,

  /// The state when data has been successfully loaded.
  success,

  /// The state when an error has occurred.
  failure,
}

/// {@template discover_state}
/// The state of the discover feature, which holds the grouped sources.
/// {@endtemplate}
final class DiscoverState extends Equatable {
  /// {@macro discover_state}
  const DiscoverState({
    this.status = DiscoverStatus.initial,
    this.groupedSources = const {},
    this.error,
  });

  /// The current status of the discover feature.
  final DiscoverStatus status;

  /// A map of sources grouped by their [SourceType].
  final Map<SourceType, List<Source>> groupedSources;

  /// The error that occurred, if any.
  final Exception? error;

  /// Creates a copy of the current [DiscoverState] with the given fields
  /// replaced with the new values.
  DiscoverState copyWith({
    DiscoverStatus? status,
    Map<SourceType, List<Source>>? groupedSources,
    Exception? error,
    bool clearError = false,
  }) {
    return DiscoverState(
      status: status ?? this.status,
      groupedSources: groupedSources ?? this.groupedSources,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, groupedSources, error];
}
