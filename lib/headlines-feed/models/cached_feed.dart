import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// {@template cached_feed}
/// A model class to encapsulate a cached feed entry.
///
/// It contains the list of fully decorated [FeedItem]s, pagination information,
/// and a timestamp for pull-to-refresh throttling.
/// {@endtemplate}
@immutable
class CachedFeed extends Equatable {
  /// {@macro cached_feed}
  const CachedFeed({
    required this.feedItems,
    required this.hasMore,
    required this.lastRefreshedAt,
    this.cursor,
  });

  /// The cached list of fully decorated feed items.
  final List<FeedItem> feedItems;

  /// A flag indicating if more items can be paginated.
  final bool hasMore;

  /// The pagination cursor for the next page.
  final String? cursor;

  /// A timestamp to track the last successful refresh for throttling.
  final DateTime lastRefreshedAt;

  /// Creates a copy of this [CachedFeed] but with the given fields replaced
  /// with the new values.
  CachedFeed copyWith({
    List<FeedItem>? feedItems,
    bool? hasMore,
    String? cursor,
    DateTime? lastRefreshedAt,
    bool clearCursor = false,
  }) {
    return CachedFeed(
      feedItems: feedItems ?? this.feedItems,
      hasMore: hasMore ?? this.hasMore,
      cursor: clearCursor ? null : cursor ?? this.cursor,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
    );
  }

  @override
  List<Object?> get props => [feedItems, hasMore, cursor, lastRefreshedAt];

  @override
  String toString() {
    return 'CachedFeed('
        'feedItems: ${feedItems.length} items, '
        'hasMore: $hasMore, '
        'cursor: $cursor, '
        'lastRefreshedAt: $lastRefreshedAt'
        ')';
  }
}
