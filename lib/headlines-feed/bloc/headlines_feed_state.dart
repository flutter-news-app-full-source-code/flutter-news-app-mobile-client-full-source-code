part of 'headlines_feed_bloc.dart';

enum HeadlinesFeedStatus { initial, loading, success, failure, loadingMore }

class HeadlinesFeedState extends Equatable {
  const HeadlinesFeedState({
    this.status = HeadlinesFeedStatus.initial,
    this.feedItems = const [],
    this.hasMore = true,
    this.cursor,
    this.filter = const HeadlineFilter(),
    this.error,
    this.navigationUrl,
  });

  final HeadlinesFeedStatus status;
  final List<FeedItem> feedItems;
  final bool hasMore;
  final String? cursor;
  final HeadlineFilter filter;
  final HttpException? error;

  /// A URL to navigate to, typically set when a call-to-action is tapped.
  /// The UI should consume this and then clear it.
  final String? navigationUrl;

  HeadlinesFeedState copyWith({
    HeadlinesFeedStatus? status,
    List<FeedItem>? feedItems,
    bool? hasMore,
    String? cursor,
    HeadlineFilter? filter,
    HttpException? error,
    String? navigationUrl,
    bool clearCursor = false,
    bool clearNavigationUrl = false,
  }) {
    return HeadlinesFeedState(
      status: status ?? this.status,
      feedItems: feedItems ?? this.feedItems,
      hasMore: hasMore ?? this.hasMore,
      cursor: clearCursor ? null : cursor ?? this.cursor,
      filter: filter ?? this.filter,
      error: error ?? this.error,
      navigationUrl: clearNavigationUrl ? null : navigationUrl ?? this.navigationUrl,
    );
  }

  @override
  List<Object?> get props => [
    status,
    feedItems,
    hasMore,
    cursor,
    filter,
    error,
    navigationUrl,
  ];
}
