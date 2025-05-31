part of 'available_sources_bloc.dart';

enum AvailableSourcesStatus { initial, loading, success, failure }

class AvailableSourcesState extends Equatable {
  const AvailableSourcesState({
    this.status = AvailableSourcesStatus.initial,
    this.availableSources = const [],
    this.error,
    // Properties for pagination if added later
    // this.hasMore = true,
    // this.cursor,
  });

  final AvailableSourcesStatus status;
  final List<Source> availableSources;
  final String? error;
  // final bool hasMore;
  // final String? cursor;

  AvailableSourcesState copyWith({
    AvailableSourcesStatus? status,
    List<Source>? availableSources,
    String? error,
    bool clearError = false,
    // bool? hasMore,
    // String? cursor,
    // bool clearCursor = false,
  }) {
    return AvailableSourcesState(
      status: status ?? this.status,
      availableSources: availableSources ?? this.availableSources,
      error: clearError ? null : error ?? this.error,
      // hasMore: hasMore ?? this.hasMore,
      // cursor: clearCursor ? null : (cursor ?? this.cursor),
    );
  }

  @override
  List<Object?> get props => [
    status,
    availableSources,
    error,
    // hasMore, // Add if pagination is implemented
    // cursor, // Add if pagination is implemented
  ];
}
