part of 'headlines_feed_bloc.dart';

/// {@template headlines_feed_state}
/// Base class for all states related to the headlines feed.
/// {@endtemplate}
sealed class HeadlinesFeedState extends Equatable {
  /// {@macro headlines_feed_state}
  const HeadlinesFeedState();

  @override
  List<Object> get props => [];
}

/// {@template headlines_feed_initial}
/// The initial state of the headlines feed.
/// {@endtemplate}
final class HeadlinesFeedInitial extends HeadlinesFeedState {}

/// {@template headlines_feed_loading}
/// State indicating that the headlines feed is being loaded.
/// {@endtemplate}
final class HeadlinesFeedLoading extends HeadlinesFeedState {}

/// {@template headlines_feed_loaded}
/// State indicating that the headlines feed has been loaded successfully.
/// {@endtemplate}
final class HeadlinesFeedLoaded extends HeadlinesFeedState {
  /// {@macro headlines_feed_loaded}
  const HeadlinesFeedLoaded({
    required this.headlines,
    required this.hasMore,
    this.cursor,
  });

  /// The headlines data.
  final List<Headline> headlines;

  /// Indicates if there are more headlines.
  final bool hasMore;

  /// The cursor for the next page.
  final String? cursor;

  @override
  List<Object> get props => [headlines, hasMore, cursor ?? ''];
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
