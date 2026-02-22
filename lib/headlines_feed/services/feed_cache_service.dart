import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/models/cached_feed.dart';
import 'package:logging/logging.dart';

/// {@template feed_cache_service}
/// A service class responsible for all in-memory caching operations for the
/// headlines feed.
///
/// This service manages a session-based cache that stores fully decorated
/// feed data for different filter configurations. The cache is cleared only
/// when the application is fully terminated.
/// {@endtemplate}
class FeedCacheService {
  /// {@macro feed_cache_service}
  FeedCacheService({Logger? logger})
    : _logger = logger ?? Logger('FeedCacheService');

  final Logger _logger;

  /// The internal in-memory cache.
  ///
  /// The key is a deterministic string generated from a [HeadlineFilter],
  /// and the value is the corresponding [CachedFeed] object.
  final Map<String, CachedFeed> _cache = {};

  /// Retrieves a [CachedFeed] object from the cache using the provided
  /// [filterKey].
  ///
  /// Returns the cached feed if it exists, otherwise returns `null`.
  CachedFeed? getFeed(String filterKey) {
    final cachedFeed = _cache[filterKey];
    if (cachedFeed != null) {
      _logger.info('Cache HIT for filter key: "$filterKey".');
    } else {
      _logger.info('Cache MISS for filter key: "$filterKey".');
    }
    return cachedFeed;
  }

  /// Adds or updates a [CachedFeed] object in the cache for the given
  /// [filterKey].
  void setFeed(String filterKey, CachedFeed feed) {
    _logger.info('Setting cache for filter key: "$filterKey".');
    _cache[filterKey] = feed;
  }

  /// A convenience method to replace an existing cache entry with an
  /// [updatedFeed].
  ///
  /// This is functionally identical to [setFeed] but can be more expressive
  /// in contexts where an existing entry is being modified (e.g., pagination
  /// or prepending new items).
  void updateFeed(String filterKey, CachedFeed updatedFeed) {
    _logger.info('Updating cache for filter key: "$filterKey".');
    _cache[filterKey] = updatedFeed;
  }

  /// Removes a specific feed from the cache using its [filterKey].
  ///
  /// This allows for explicit cache invalidation for a single feed, which can
  /// be useful when user preferences change in a way that should force a full
  /// reload for a specific view (e.g., after logging out).
  void removeFeed(String filterKey) {
    _logger.info('Removing feed from cache for filter key: "$filterKey".');
    _cache.remove(filterKey);
  }

  /// Clears the entire feed cache.
  ///
  /// This is currently not used in the session-based caching strategy but is
  /// provided for future flexibility or debugging purposes.
  void clearAll() {
    _logger.info('Clearing all entries from the feed cache.');
    _cache.clear();
  }
}
