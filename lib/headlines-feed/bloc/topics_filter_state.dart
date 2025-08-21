part of 'topics_filter_bloc.dart';

/// Enum representing the different statuses of the topic filter data fetching.
enum TopicsFilterStatus {
  /// Initial state, no data loaded yet.
  initial,

  /// Currently fetching the first page of topics.
  loading,

  /// Successfully loaded topics. May be loading more in the background.
  success,

  /// An error occurred while fetching topics.
  failure,

  /// Loading more topics for pagination (infinity scroll).
  loadingMore,
}

/// {@template topics_filter_state}
/// Represents the state for the topic filter feature.
///
/// Contains the list of fetched topics, pagination information,
/// loading/error status.
/// {@endtemplate}
final class TopicsFilterState extends Equatable {
  /// {@macro topics_filter_state}
  const TopicsFilterState({
    this.status = TopicsFilterStatus.initial,
    this.topics = const [],
    this.hasMore = true,
    this.cursor,
    this.error,
  });

  /// The current status of fetching topics.
  final TopicsFilterStatus status;

  /// The list of [Topic] objects fetched so far.
  final List<Topic> topics;

  /// Flag indicating if there are more topics available to fetch.
  final bool hasMore;

  /// The cursor string to fetch the next page of topics.
  /// This is typically the ID of the last fetched topic.
  final String? cursor;

  /// An optional error object if the status is [TopicsFilterStatus.failure].
  final HttpException? error;

  /// The current status of fetching followed topics.
  final TopicsFilterStatus followedTopicsStatus;

  /// The list of [Topic] objects representing the user's followed topics.
  final List<Topic> followedTopics;

  /// Creates a copy of this state with the given fields replaced.
  TopicsFilterState copyWith({
    TopicsFilterStatus? status,
    List<Topic>? topics,
    bool? hasMore,
    String? cursor,
    HttpException? error,
    TopicsFilterStatus? followedTopicsStatus,
    List<Topic>? followedTopics,
    bool clearError = false,
    bool clearCursor = false,
    bool clearFollowedTopicsError = false,
  }) {
    return TopicsFilterState(
      status: status ?? this.status,
      topics: topics ?? this.topics,
      hasMore: hasMore ?? this.hasMore,
      // Allow explicitly setting cursor to null or clearing it
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      // Clear error if requested, otherwise keep existing or use new one
      error: clearError ? null : error ?? this.error,
      followedTopicsStatus: followedTopicsStatus ?? this.followedTopicsStatus,
      followedTopics: followedTopics ?? this.followedTopics,
    );
  }

  @override
  List<Object?> get props => [
    status,
    topics,
    hasMore,
    cursor,
    error,
    followedTopicsStatus,
    followedTopics,
  ];
}
