import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/models/cached_feed.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/services/feed_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockLogger extends Mock implements Logger {}

class FakeHeadline extends Fake implements Headline {}

void main() {
  late FeedCacheService feedCacheService;
  late MockLogger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
    feedCacheService = FeedCacheService(logger: mockLogger);
    // Suppress logs during tests
    when(() => mockLogger.info(any())).thenAnswer((_) {});
  });

  group('FeedCacheService', () {
    const filterKey = 'test_filter';
    final headline = FakeHeadline();
    final cachedFeed = CachedFeed(
      feedItems: [headline],
      hasMore: true,
      cursor: 'cursor1',
      lastRefreshedAt: DateTime.now(),
    );

    test('getFeed returns null for a cache miss', () {
      expect(feedCacheService.getFeed('non_existent_key'), isNull);
      verify(
        () => mockLogger.info('Cache MISS for filter key: "non_existent_key".'),
      ).called(1);
    });

    test('setFeed and getFeed work for a cache hit', () {
      feedCacheService.setFeed(filterKey, cachedFeed);
      final result = feedCacheService.getFeed(filterKey);

      expect(result, equals(cachedFeed));
      verify(
        () => mockLogger.info('Setting cache for filter key: "$filterKey".'),
      ).called(1);
      verify(
        () => mockLogger.info('Cache HIT for filter key: "$filterKey".'),
      ).called(1);
    });

    test('updateFeed replaces an existing entry', () {
      feedCacheService.setFeed(filterKey, cachedFeed);
      final updatedFeed = cachedFeed.copyWith(
        hasMore: false,
        cursor: 'cursor2',
      );
      feedCacheService.updateFeed(filterKey, updatedFeed);

      final result = feedCacheService.getFeed(filterKey);
      expect(result, equals(updatedFeed));
      expect(result?.hasMore, isFalse);
      verify(
        () => mockLogger.info('Updating cache for filter key: "$filterKey".'),
      ).called(1);
    });

    test('removeFeed removes a specific entry from the cache', () {
      feedCacheService.setFeed(filterKey, cachedFeed);
      expect(feedCacheService.getFeed(filterKey), isNotNull);

      feedCacheService.removeFeed(filterKey);
      expect(feedCacheService.getFeed(filterKey), isNull);
      verify(
        () => mockLogger.info(
          'Removing feed from cache for filter key: "$filterKey".',
        ),
      ).called(1);
    });

    test('clearAll removes all entries from the cache', () {
      feedCacheService.setFeed('key1', cachedFeed);
      feedCacheService.setFeed('key2', cachedFeed);

      feedCacheService.clearAll();

      expect(feedCacheService.getFeed('key1'), isNull);
      expect(feedCacheService.getFeed('key2'), isNull);
      verify(
        () => mockLogger.info('Clearing all entries from the feed cache.'),
      ).called(1);
    });
  });
}
