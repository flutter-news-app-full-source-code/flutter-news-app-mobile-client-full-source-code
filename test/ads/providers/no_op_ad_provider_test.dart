import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/providers/no_op_ad_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockLogger extends Mock implements Logger {}

class MockAdThemeStyle extends Mock implements AdThemeStyle {}

class MockAdPlatformIdentifiers extends Mock implements AdPlatformIdentifiers {}

void main() {
  group('NoOpAdProvider', () {
    late NoOpAdProvider noOpAdProvider;
    late MockLogger mockLogger;

    setUp(() {
      mockLogger = MockLogger();
      noOpAdProvider = NoOpAdProvider(logger: mockLogger);
      registerFallbackValue(MockAdThemeStyle());
      registerFallbackValue(MockAdPlatformIdentifiers());
    });

    test('initialize completes successfully', () async {
      await expectLater(noOpAdProvider.initialize(), completes);
      verify(() => mockLogger.fine('Initializing NoOpAdProvider.')).called(1);
    });

    test('loadNativeAd returns null', () async {
      final result = await noOpAdProvider.loadNativeAd(
        adPlatformIdentifiers: MockAdPlatformIdentifiers(),
        adId: 'test-id',
        adThemeStyle: MockAdThemeStyle(),
      );
      expect(result, isNull);
      verify(
        () => mockLogger.fine(
          'NoOpAdProvider: loadNativeAd called. Returning null.',
        ),
      ).called(1);
    });

    test('loadBannerAd returns null', () async {
      final result = await noOpAdProvider.loadBannerAd(
        adPlatformIdentifiers: MockAdPlatformIdentifiers(),
        adId: 'test-id',
        adThemeStyle: MockAdThemeStyle(),
      );
      expect(result, isNull);
      verify(
        () => mockLogger.fine(
          'NoOpAdProvider: loadBannerAd called. Returning null.',
        ),
      ).called(1);
    });

    test('loadInterstitialAd returns null', () async {
      final result = await noOpAdProvider.loadInterstitialAd(
        adPlatformIdentifiers: MockAdPlatformIdentifiers(),
        adId: 'test-id',
        adThemeStyle: MockAdThemeStyle(),
      );
      expect(result, isNull);
      verify(
        () => mockLogger.fine(
          'NoOpAdProvider: loadInterstitialAd called. Returning null.',
        ),
      ).called(1);
    });

    test('loadRewardedAd returns null', () async {
      final result = await noOpAdProvider.loadRewardedAd(
        adPlatformIdentifiers: MockAdPlatformIdentifiers(),
        adId: 'test-id',
        adThemeStyle: MockAdThemeStyle(),
      );
      expect(result, isNull);
      verify(
        () => mockLogger.fine(
          'NoOpAdProvider: loadRewardedAd called. Returning null.',
        ),
      ).called(1);
    });

    test('disposeAd completes successfully', () async {
      await expectLater(noOpAdProvider.disposeAd(Object()), completes);
      verify(
        () => mockLogger.fine('NoOpAdProvider: disposeAd called.'),
      ).called(1);
    });
  });
}
