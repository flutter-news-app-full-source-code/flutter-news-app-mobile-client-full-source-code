import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/inline_ad_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdService extends Mock implements AdService {}

class MockInlineAd extends Mock implements InlineAd {}

class FakeInlineAd extends Fake implements InlineAd {}

void main() {
  group('InlineAdCacheService', () {
    late MockAdService mockAdService;
    late InlineAdCacheService inlineAdCacheService;
    late MockInlineAd mockAd1;
    late MockInlineAd mockAd2;
    late MockInlineAd mockAd3;

    const contextKey1 = 'feed_all';
    const contextKey2 = 'feed_followed';
    const placeholderId1 = 'placeholder_1';
    const placeholderId2 = 'placeholder_2';

    setUpAll(() {
      registerFallbackValue(FakeInlineAd());
    });

    setUp(() {
      mockAdService = MockAdService();
      // The service is a singleton, so we inject the mock via the factory.
      inlineAdCacheService = InlineAdCacheService(adService: mockAdService);

      // Mock the disposeAd call to avoid errors.
      when(() => mockAdService.disposeAd(any())).thenAnswer((_) async {});

      // Clear the cache before each test to ensure isolation.
      inlineAdCacheService.clearAllAds();

      mockAd1 = MockInlineAd();
      mockAd2 = MockInlineAd();
      mockAd3 = MockInlineAd();
    });

    test('getAd returns null for a non-existent ad', () {
      final ad = inlineAdCacheService.getAd(
        contextKey: contextKey1,
        placeholderId: placeholderId1,
      );
      expect(ad, isNull);
    });

    test('setAd stores an ad and getAd retrieves it', () {
      inlineAdCacheService.setAd(
        contextKey: contextKey1,
        placeholderId: placeholderId1,
        ad: mockAd1,
      );

      final retrievedAd = inlineAdCacheService.getAd(
        contextKey: contextKey1,
        placeholderId: placeholderId1,
      );

      expect(retrievedAd, same(mockAd1));
    });

    test('setAd with a new ad disposes the old one', () {
      // Arrange: set an initial ad
      inlineAdCacheService.setAd(
        contextKey: contextKey1,
        placeholderId: placeholderId1,
        ad: mockAd1,
      );

      // Act: set a new ad for the same key
      inlineAdCacheService.setAd(
        contextKey: contextKey1,
        placeholderId: placeholderId1,
        ad: mockAd2,
      );

      // Assert: verify the old ad was disposed
      verify(() => mockAdService.disposeAd(mockAd1)).called(1);

      final retrievedAd = inlineAdCacheService.getAd(
        contextKey: contextKey1,
        placeholderId: placeholderId1,
      );
      expect(retrievedAd, same(mockAd2));
    });

    test('setAd with null removes the entry and disposes the ad', () {
      inlineAdCacheService.setAd(
        contextKey: contextKey1,
        placeholderId: placeholderId1,
        ad: mockAd1,
      );

      inlineAdCacheService.setAd(
        contextKey: contextKey1,
        placeholderId: placeholderId1,
        ad: null,
      );

      verify(() => mockAdService.disposeAd(mockAd1)).called(1);
      final retrievedAd = inlineAdCacheService.getAd(
        contextKey: contextKey1,
        placeholderId: placeholderId1,
      );
      expect(retrievedAd, isNull);
    });

    test('removeAndDisposeAd removes the ad and calls disposeAd', () {
      inlineAdCacheService.setAd(
        contextKey: contextKey1,
        placeholderId: placeholderId1,
        ad: mockAd1,
      );

      inlineAdCacheService.removeAndDisposeAd(
        contextKey: contextKey1,
        placeholderId: placeholderId1,
      );

      verify(() => mockAdService.disposeAd(mockAd1)).called(1);
      final retrievedAd = inlineAdCacheService.getAd(
        contextKey: contextKey1,
        placeholderId: placeholderId1,
      );
      expect(retrievedAd, isNull);
    });

    test('clearAdsForContext clears only the specified context', () {
      // Arrange: set ads in two different contexts
      inlineAdCacheService.setAd(
        contextKey: contextKey1,
        placeholderId: placeholderId1,
        ad: mockAd1,
      );
      inlineAdCacheService.setAd(
        contextKey: contextKey2,
        placeholderId: placeholderId2,
        ad: mockAd2,
      );

      // Act: clear only the first context
      inlineAdCacheService.clearAdsForContext(contextKey: contextKey1);

      // Assert
      verify(() => mockAdService.disposeAd(mockAd1)).called(1);
      verifyNever(() => mockAdService.disposeAd(mockAd2));

      expect(
        inlineAdCacheService.getAd(
          contextKey: contextKey1,
          placeholderId: placeholderId1,
        ),
        isNull,
      );
      expect(
        inlineAdCacheService.getAd(
          contextKey: contextKey2,
          placeholderId: placeholderId2,
        ),
        same(mockAd2),
      );
    });

    test('clearAllAds clears all contexts and disposes all ads', () {
      // Arrange: set ads in multiple contexts
      inlineAdCacheService.setAd(
        contextKey: contextKey1,
        placeholderId: placeholderId1,
        ad: mockAd1,
      );
      inlineAdCacheService.setAd(
        contextKey: contextKey1,
        placeholderId: placeholderId2,
        ad: mockAd2,
      );
      inlineAdCacheService.setAd(
        contextKey: contextKey2,
        placeholderId: placeholderId1,
        ad: mockAd3,
      );

      // Act
      inlineAdCacheService.clearAllAds();

      // Assert
      verify(() => mockAdService.disposeAd(mockAd1)).called(1);
      verify(() => mockAdService.disposeAd(mockAd2)).called(1);
      verify(() => mockAdService.disposeAd(mockAd3)).called(1);

      expect(
        inlineAdCacheService.getAd(
          contextKey: contextKey1,
          placeholderId: placeholderId1,
        ),
        isNull,
      );
      expect(
        inlineAdCacheService.getAd(
          contextKey: contextKey2,
          placeholderId: placeholderId1,
        ),
        isNull,
      );
    });
  });
}
