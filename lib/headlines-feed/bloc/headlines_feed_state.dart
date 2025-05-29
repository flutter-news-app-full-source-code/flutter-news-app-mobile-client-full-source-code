part of 'headlines_feed_bloc.dart';

/// {@template headlines_feed_state}
/// Represents the possible states of the headlines feed feature.
/// {@endtemplate}
sealed class HeadlinesFeedState extends Equatable {
  /// {@macro headlines_feed_state}
  const HeadlinesFeedState();

  @override
  List<Object?> get props => [];
}

/// {@template headlines_feed_initial}
/// The initial state of the headlines feed before any loading has begun.
/// {@endtemplate}
final class HeadlinesFeedInitial extends HeadlinesFeedState {}

/// {@template headlines_feed_loading}
/// State indicating that the headlines feed is currently being fetched,
/// typically shown with a full-screen loading indicator. This is used for
/// initial loads, refreshes, or when applying/clearing filters.
/// {@endtemplate}
final class HeadlinesFeedLoading extends HeadlinesFeedState {}

/// {@template headlines_feed_loading_silently}
/// State indicating that more headlines are being fetched for pagination
/// (infinity scrolling). This state usually doesn't trigger a full-screen
/// loading indicator, allowing the existing list to remain visible while
/// a smaller indicator might be shown at the bottom.
/// {@endtemplate}
final class HeadlinesFeedLoadingSilently extends HeadlinesFeedState {}

/// {@template headlines_feed_loaded}
/// State indicating that a batch of headlines has been successfully loaded.
/// Contains the list of headlines, pagination information, and the currently
/// active filter configuration.
/// {@endtemplate}
final class HeadlinesFeedLoaded extends HeadlinesFeedState {
  /// {@macro headlines_feed_loaded}
  const HeadlinesFeedLoaded({
    this.headlines = const [],
    this.hasMore = true,
    this.cursor,
    this.filter = const HeadlineFilter(),
  });

  /// The list of [Headline] objects currently loaded.
  final List<Headline> headlines;

  /// Flag indicating if there are more headlines available to fetch
  /// via pagination. `true` if more might exist, `false` otherwise.
  final bool hasMore;

  /// The cursor string to be used to fetch the next page of headlines.
  /// Null if there are no more pages or if pagination is not applicable.
  final String? cursor;

  /// The [HeadlineFilter] currently applied to the feed. An empty filter
  /// indicates that no filters are active.
  final HeadlineFilter filter;

  /// Creates a copy of this [HeadlinesFeedLoaded] state with the given fields
  /// replaced with new values.
  HeadlinesFeedLoaded copyWith({
    List<Headline>? headlines,
    bool? hasMore,
    String? cursor,
    HeadlineFilter? filter,
  }) {
    return HeadlinesFeedLoaded(
      headlines: headlines ?? this.headlines,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [headlines, hasMore, cursor, filter];
}

/// {@template headlines_feed_error}
/// State indicating that an error occurred while fetching headlines.
/// Contains an error [message] describing the failure.
/// {@endtemplate}
final class HeadlinesFeedError extends HeadlinesFeedState {
  /// {@macro headlines_feed_error}
  const HeadlinesFeedError({required this.message});

  /// A message describing the error that occurred.
  final String message;

  @override
  List<Object> get props => [message];
}
