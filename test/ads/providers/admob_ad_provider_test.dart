import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/providers/admob_ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

// Mocks for dependencies
class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockLogger extends Mock implements Logger {}

// Fakes for AdMob classes
class FakeAdRequest extends Fake implements admob.AdRequest {}

const dummyAdThemeStyle = AdThemeStyle(
  mainBackgroundColor: Colors.white,
  cornerRadius: 8,
  callToActionTextColor: Colors.white,
  callToActionBackgroundColor: Colors.blue,
  callToActionTextSize: 16,
  primaryTextColor: Colors.black,
  primaryBackgroundColor: Colors.transparent,
  primaryTextSize: 18,
  secondaryTextColor: Colors.grey,
  secondaryBackgroundColor: Colors.transparent,
  secondaryTextSize: 14,
  tertiaryTextColor: Colors.grey,
  tertiaryBackgroundColor: Colors.transparent,
  tertiaryTextSize: 12,
);

class FakeAdPlatformIdentifiers extends Fake implements AdPlatformIdentifiers {}

class FakeAnalyticsEventPayload extends Fake implements AnalyticsEventPayload {}

class FakeNativeAdListener extends Fake implements admob.NativeAdListener {}

class FakeBannerAdListener extends Fake implements admob.BannerAdListener {}

class FakeNativeTemplateStyle extends Fake
    implements admob.NativeTemplateStyle {}

// Mocks for AdMob Ad objects
class MockAdmobNativeAd extends Mock implements admob.NativeAd {}

class MockAdmobBannerAd extends Mock implements admob.BannerAd {}

class MockAdmobInterstitialAd extends Mock implements admob.InterstitialAd {}

class MockAdmobRewardedAd extends Mock implements admob.RewardedAd {}

class MockAdMobWrapper extends Mock implements AdMobWrapper {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdMobAdProvider', () {
    late AdMobAdProvider adMobAdProvider;
    late MockAnalyticsService mockAnalyticsService;
    late MockLogger mockLogger;
    late MockAdMobWrapper mockAdMobWrapper;

    setUpAll(() {
      registerFallbackValue(admob.InitializationStatus({}));
      registerFallbackValue(FakeAdRequest());
      registerFallbackValue(dummyAdThemeStyle);
      registerFallbackValue(FakeAdPlatformIdentifiers());
      registerFallbackValue(FakeAnalyticsEventPayload());
      registerFallbackValue(AnalyticsEvent.adClicked);
      registerFallbackValue(FakeNativeAdListener());
      registerFallbackValue(FakeBannerAdListener());
      registerFallbackValue(FakeNativeTemplateStyle());
      registerFallbackValue(admob.AdSize.banner);
    });

    setUp(() {
      mockAnalyticsService = MockAnalyticsService();
      mockLogger = MockLogger();
      mockAdMobWrapper = MockAdMobWrapper();

      adMobAdProvider = AdMobAdProvider(
        analyticsService: mockAnalyticsService,
        logger: mockLogger,
        adMobWrapper: mockAdMobWrapper,
      );

      // Stub the analytics service to avoid errors.
      when(
        () => mockAnalyticsService.logEvent(
          any(),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});
    });

    test('initialize calls AdMobWrapper.initialize', () async {
      when(
        () => mockAdMobWrapper.initialize(),
      ).thenAnswer((_) async => admob.InitializationStatus({}));
      await adMobAdProvider.initialize();
      verify(() => mockAdMobWrapper.initialize()).called(1);
    });

    group('loadNativeAd', () {
      test('returns null if adId is null or empty', () async {
        final result = await adMobAdProvider.loadNativeAd(
          adPlatformIdentifiers: FakeAdPlatformIdentifiers(),
          adId: null,
          adThemeStyle: dummyAdThemeStyle,
        );
        expect(result, isNull);
      });

      test('returns NativeAd when loading succeeds', () async {
        final mockNativeAd = MockAdmobNativeAd();
        when(mockNativeAd.load).thenAnswer((_) async {});

        // Intercept the creation to capture the listener
        when(
          () => mockAdMobWrapper.createNativeAd(
            adUnitId: any(named: 'adUnitId'),
            listener: any(named: 'listener'),
            request: any(named: 'request'),
            nativeTemplateStyle: any(named: 'nativeTemplateStyle'),
          ),
        ).thenAnswer((invocation) {
          final listener =
              invocation.namedArguments[#listener] as admob.NativeAdListener;
          // Simulate success callback immediately
          listener.onAdLoaded!(mockNativeAd);
          return mockNativeAd;
        });

        final result = await adMobAdProvider.loadNativeAd(
          adPlatformIdentifiers: FakeAdPlatformIdentifiers(),
          adId: 'test_ad_id',
          adThemeStyle: dummyAdThemeStyle,
        );

        expect(result, isNotNull);
        expect(result!.provider, AdPlatformType.admob);
        verify(mockNativeAd.load).called(1);
      });

      test('returns null when loading fails', () async {
        final mockNativeAd = MockAdmobNativeAd();
        when(mockNativeAd.load).thenAnswer((_) async {});

        when(
          () => mockAdMobWrapper.createNativeAd(
            adUnitId: any(named: 'adUnitId'),
            listener: any(named: 'listener'),
            request: any(named: 'request'),
            nativeTemplateStyle: any(named: 'nativeTemplateStyle'),
          ),
        ).thenAnswer((invocation) {
          final listener =
              invocation.namedArguments[#listener] as admob.NativeAdListener;
          // Simulate failure callback
          listener.onAdFailedToLoad!(
            mockNativeAd,
            admob.LoadAdError(0, '', '', null),
          );
          return mockNativeAd;
        });

        final result = await adMobAdProvider.loadNativeAd(
          adPlatformIdentifiers: FakeAdPlatformIdentifiers(),
          adId: 'test_ad_id',
          adThemeStyle: dummyAdThemeStyle,
        );

        expect(result, isNull);
      });
    });

    group('loadBannerAd', () {
      test('returns null if adId is null or empty', () async {
        final result = await adMobAdProvider.loadBannerAd(
          adPlatformIdentifiers: FakeAdPlatformIdentifiers(),
          adId: '',
          adThemeStyle: dummyAdThemeStyle,
        );
        expect(result, isNull);
      });

      test('returns BannerAd when loading succeeds', () async {
        final mockBannerAd = MockAdmobBannerAd();
        when(mockBannerAd.load).thenAnswer((_) async {});

        when(
          () => mockAdMobWrapper.createBannerAd(
            adUnitId: any(named: 'adUnitId'),
            size: any(named: 'size'),
            listener: any(named: 'listener'),
            request: any(named: 'request'),
          ),
        ).thenAnswer((invocation) {
          final listener =
              invocation.namedArguments[#listener] as admob.BannerAdListener;
          listener.onAdLoaded!(mockBannerAd);
          return mockBannerAd;
        });

        final result = await adMobAdProvider.loadBannerAd(
          adPlatformIdentifiers: FakeAdPlatformIdentifiers(),
          adId: 'test_banner_id',
          adThemeStyle: dummyAdThemeStyle,
        );

        expect(result, isNotNull);
        expect(result!.provider, AdPlatformType.admob);
        verify(mockBannerAd.load).called(1);
      });

      test('returns null when loading fails', () async {
        final mockBannerAd = MockAdmobBannerAd();
        when(mockBannerAd.load).thenAnswer((_) async {});

        when(
          () => mockAdMobWrapper.createBannerAd(
            adUnitId: any(named: 'adUnitId'),
            size: any(named: 'size'),
            listener: any(named: 'listener'),
            request: any(named: 'request'),
          ),
        ).thenAnswer((invocation) {
          final listener =
              invocation.namedArguments[#listener] as admob.BannerAdListener;
          listener.onAdFailedToLoad!(
            mockBannerAd,
            admob.LoadAdError(0, '', '', null),
          );
          return mockBannerAd;
        });

        final result = await adMobAdProvider.loadBannerAd(
          adPlatformIdentifiers: FakeAdPlatformIdentifiers(),
          adId: 'test_banner_id',
          adThemeStyle: dummyAdThemeStyle,
        );

        expect(result, isNull);
      });
    });

    group('loadInterstitialAd', () {
      test('returns null if adId is null or empty', () async {
        final result = await adMobAdProvider.loadInterstitialAd(
          adPlatformIdentifiers: FakeAdPlatformIdentifiers(),
          adId: null,
          adThemeStyle: dummyAdThemeStyle,
        );
        expect(result, isNull);
      });

      // NOTE: Testing the static `InterstitialAd.load` method is not feasible
      // with standard mocking tools like mocktail. This would require either
      // wrapping the static call in an injectable class (which we cannot do
      // without modifying the source) or using platform channel mocks.
      // Therefore, we focus on testing the guard clauses and trust the
      // underlying SDK.
    });

    group('loadRewardedAd', () {
      test('returns null if adId is null or empty', () async {
        final result = await adMobAdProvider.loadRewardedAd(
          adPlatformIdentifiers: FakeAdPlatformIdentifiers(),
          adId: null,
          adThemeStyle: dummyAdThemeStyle,
        );
        expect(result, isNull);
      });

      // NOTE: Similar to InterstitialAd, testing the static `RewardedAd.load`
      // is not practical in this context.
    });

    group('disposeAd', () {
      test('calls dispose on admob.NativeAd', () async {
        final mockAd = MockAdmobNativeAd();
        when(mockAd.dispose).thenAnswer((_) async {});
        await adMobAdProvider.disposeAd(mockAd);
        verify(mockAd.dispose).called(1);
      });

      test('calls dispose on admob.BannerAd', () async {
        final mockAd = MockAdmobBannerAd();
        when(mockAd.dispose).thenAnswer((_) async {});
        await adMobAdProvider.disposeAd(mockAd);
        verify(mockAd.dispose).called(1);
      });

      test('calls dispose on admob.InterstitialAd', () async {
        final mockAd = MockAdmobInterstitialAd();
        when(mockAd.dispose).thenAnswer((_) async {});
        await adMobAdProvider.disposeAd(mockAd);
        verify(mockAd.dispose).called(1);
      });

      test('calls dispose on admob.RewardedAd', () async {
        final mockAd = MockAdmobRewardedAd();
        when(mockAd.dispose).thenAnswer((_) async {});
        await adMobAdProvider.disposeAd(mockAd);
        verify(mockAd.dispose).called(1);
      });

      test('does not throw if object is not a known admob.Ad type', () async {
        final notAnAd = Object();
        await expectLater(adMobAdProvider.disposeAd(notAnAd), completes);
        verify(
          () => mockLogger.warning(
            any(that: contains('Attempted to dispose a non-AdMob ad object')),
          ),
        ).called(1);
      });
    });

    group('_createNativeTemplateStyle', () {
      test('creates correct style for small template', () {
        final adThemeStyle = AdThemeStyle.fromTheme(ThemeData.light());
        final result = adMobAdProvider.createNativeTemplateStyle(
          templateType: admob.TemplateType.small,
          adThemeStyle: adThemeStyle,
        );
        expect(result.templateType, admob.TemplateType.small);
        expect(result.mainBackgroundColor, adThemeStyle.mainBackgroundColor);
      });

      test('creates correct style for medium template', () {
        final adThemeStyle = AdThemeStyle.fromTheme(ThemeData.dark());
        final result = adMobAdProvider.createNativeTemplateStyle(
          templateType: admob.TemplateType.medium,
          adThemeStyle: adThemeStyle,
        );
        expect(result.templateType, admob.TemplateType.medium);
        expect(
          result.primaryTextStyle?.backgroundColor,
          adThemeStyle.primaryBackgroundColor,
        );
      });
    });
  });
}
