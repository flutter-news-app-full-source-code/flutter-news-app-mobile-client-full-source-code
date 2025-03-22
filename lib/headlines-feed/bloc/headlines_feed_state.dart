part of 'headlines_feed_bloc.dart';

/// {@template headlines_feed_state}
/// Base class for all states related to the headlines feed.
/// {@endtemplate}
sealed class HeadlinesFeedState extends Equatable {
  /// {@macro headlines_feed_state}
  const HeadlinesFeedState();

  @override
  List<Object?> get props => [];
}

/// {@template headlines_feed_loading}
/// State indicating that the headlines feed is being loaded.
/// {@endtemplate}
final class HeadlinesFeedLoading extends HeadlinesFeedState {}

/// {@template headlines_feed_loading}
/// State indicating that the headlines feed is being loaded
/// without a full screen loading widget being showed.
///
/// usefull for inifinity scrolling fetches beyonf the first one
/// {@endtemplate}
final class HeadlinesFeedLoadingSilently extends HeadlinesFeedState {}

/// {@template headlines_feed_loaded}
/// State indicating that the headlines feed has been loaded successfully,
/// potentially with applied filters.
/// {@endtemplate}
final class HeadlinesFeedLoaded extends HeadlinesFeedState {
  /// {@macro headlines_feed_loaded}
  const HeadlinesFeedLoaded({
    this.headlines = const [],
    this.hasMore = true,
    this.cursor,
    this.filter = const HeadlineFilter(),
  });

  /// The headlines data.
  final List<Headline> headlines;

  /// Indicates if there are more headlines.
  final bool hasMore;

  /// The cursor for the next page.
  final String? cursor;

  /// The filter applied to the headlines.
  final HeadlineFilter filter;

  /// Creates a copy of this [HeadlinesFeedLoaded] with the given fields
  /// replaced with the new values.
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
/// State indicating that an error occurred while loading the headlines feed.
/// {@endtemplate}
final class HeadlinesFeedError extends HeadlinesFeedState {
  /// {@macro headlines_feed_error}
  const HeadlinesFeedError({required this.message});

  /// The error message.
  final String message;

  @override
  List<Object> get props => [message];
}
