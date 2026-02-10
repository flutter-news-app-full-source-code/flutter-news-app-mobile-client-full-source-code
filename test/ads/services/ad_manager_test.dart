import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_placeholder.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/native_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/inline_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/interstitial_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/rewarded_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/providers/ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockAdProvider extends Mock implements AdProvider {}

class MockNoOpAdProvider extends Mock implements AdProvider {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockLogger extends Mock implements Logger {}

class MockAdConfig extends Mock implements AdConfig {}

class MockAdPlatformIdentifiers extends Mock implements AdPlatformIdentifiers {}

class MockFeedAdConfiguration extends Mock implements FeedAdConfiguration {}

class MockNavigationAdConfiguration extends Mock
    implements NavigationAdConfiguration {}

class MockFeedAdFrequencyConfig extends Mock implements FeedAdFrequencyConfig {}

class MockInlineAd extends Mock implements InlineAd {}

class MockNativeAd extends Mock implements NativeAd {}

class MockInterstitialAd extends Mock implements InterstitialAd {}

class MockRewardedAd extends Mock implements RewardedAd {}

class MockUser extends Mock implements User {}

class MockUserRewards extends Mock implements UserRewards {}

class FakeAdThemeStyle extends Fake implements AdThemeStyle {}

class FakeAdPlatformIdentifiers extends Fake implements AdPlatformIdentifiers {}

class FakeAnalyticsEventPayload extends Fake implements AnalyticsEventPayload {}

void main() {
  group('AdManager', () {
    late AdManager adManager;
    late MockAdProvider mockAdMobProvider;
    late MockNoOpAdProvider mockNoOpProvider;
    late MockAnalyticsService mockAnalyticsService;
    late MockLogger mockLogger;
    late MockAdConfig mockAdConfig;
    late MockAdPlatformIdentifiers mockAdPlatformIdentifiers;
    late MockFeedAdConfiguration mockFeedAdConfig;
    late MockNavigationAdConfiguration mockNavAdConfig;
    late MockFeedAdFrequencyConfig mockFeedAdFrequencyConfig;

    setUpAll(() {
      registerFallbackValue(FakeAdThemeStyle());
      registerFallbackValue(FakeAnalyticsEventPayload());
      registerFallbackValue(FakeAdPlatformIdentifiers());
      registerFallbackValue(AnalyticsEvent.adClicked);
      registerFallbackValue(RewardType.adFree);
    });

    setUp(() {
      mockAdMobProvider = MockAdProvider();
      mockNoOpProvider = MockNoOpAdProvider();
      mockAnalyticsService = MockAnalyticsService();
      mockLogger = MockLogger();
      mockAdConfig = MockAdConfig();
      mockAdPlatformIdentifiers = MockAdPlatformIdentifiers();
      mockFeedAdConfig = MockFeedAdConfiguration();
      mockNavAdConfig = MockNavigationAdConfiguration();
      mockFeedAdFrequencyConfig = MockFeedAdFrequencyConfig();

      when(() => mockAdConfig.enabled).thenReturn(true);
      when(
        () => mockAdConfig.primaryAdPlatform,
      ).thenReturn(AdPlatformType.admob);
      when(
        () => mockAdConfig.platformAdIdentifiers,
      ).thenReturn({AdPlatformType.admob: mockAdPlatformIdentifiers});
      when(() => mockAdConfig.feedAdConfiguration).thenReturn(mockFeedAdConfig);
      when(
        () => mockAdConfig.navigationAdConfiguration,
      ).thenReturn(mockNavAdConfig);

      when(() => mockFeedAdConfig.enabled).thenReturn(true);
      when(
        () => mockFeedAdConfig.visibleTo,
      ).thenReturn({AccessTier.guest: mockFeedAdFrequencyConfig});

      when(() => mockNavAdConfig.enabled).thenReturn(true);
      when(() => mockNavAdConfig.visibleTo).thenReturn({
        AccessTier.guest: const NavigationAdFrequencyConfig(
          internalNavigationsBeforeShowingInterstitialAd: 3,
          externalNavigationsBeforeShowingInterstitialAd: 1,
        ),
      });

      when(() => mockAdMobProvider.initialize()).thenAnswer((_) async {});
      when(() => mockNoOpProvider.initialize()).thenAnswer((_) async {});
      when(
        () => mockAnalyticsService.logEvent(
          any(),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      adManager = AdManager(
        initialConfig: mockAdConfig,
        adProviders: {AdPlatformType.admob: mockAdMobProvider},
        noOpProvider: mockNoOpProvider,
        analyticsService: mockAnalyticsService,
        logger: mockLogger,
      );
    });

    group('initialize', () {
      test('initializes providers when ads are enabled', () async {
        when(() => mockAdConfig.enabled).thenReturn(true);
        await adManager.initialize();
        verify(() => mockAdMobProvider.initialize()).called(1);
        verify(() => mockNoOpProvider.initialize()).called(1);
      });

      test('does not initialize providers when ads are disabled', () async {
        final disabledAdManager = AdManager(
          initialConfig: null,
          adProviders: {AdPlatformType.admob: mockAdMobProvider},
          noOpProvider: mockNoOpProvider,
          analyticsService: mockAnalyticsService,
          logger: mockLogger,
        );
        await disabledAdManager.initialize();
        verifyNever(() => mockAdMobProvider.initialize());
        verifyNever(() => mockNoOpProvider.initialize());
      });
    });

    group('disposeAd', () {
      test('disposes InlineAd using the correct provider', () async {
        final ad = MockInlineAd();
        when(() => ad.provider).thenReturn(AdPlatformType.admob);
        when(() => ad.adObject).thenReturn(Object());
        when(() => mockAdMobProvider.disposeAd(any())).thenAnswer((_) async {});

        await adManager.disposeAd(ad);

        verify(() => mockAdMobProvider.disposeAd(ad.adObject)).called(1);
      });

      test('disposes InterstitialAd using the correct provider', () async {
        final ad = MockInterstitialAd();
        when(() => ad.provider).thenReturn(AdPlatformType.admob);
        when(() => ad.adObject).thenReturn(Object());
        when(() => mockAdMobProvider.disposeAd(any())).thenAnswer((_) async {});

        await adManager.disposeAd(ad);

        verify(() => mockAdMobProvider.disposeAd(ad.adObject)).called(1);
      });

      test('disposes RewardedAd using the correct provider', () async {
        final ad = MockRewardedAd();
        when(() => ad.provider).thenReturn(AdPlatformType.admob);
        when(() => ad.adObject).thenReturn(Object());
        when(() => mockAdMobProvider.disposeAd(any())).thenAnswer((_) async {});

        await adManager.disposeAd(ad);

        verify(() => mockAdMobProvider.disposeAd(ad.adObject)).called(1);
      });
    });

    group('getFeedAd', () {
      setUp(() {
        if (Platform.isAndroid) {
          when(
            () => mockAdPlatformIdentifiers.androidNativeAdId,
          ).thenReturn('android-native-id');
        } else {
          when(
            () => mockAdPlatformIdentifiers.iosNativeAdId,
          ).thenReturn('ios-native-id');
        }
      });

      test('returns null if ads are globally disabled', () async {
        when(() => mockAdConfig.enabled).thenReturn(false);
        final result = await adManager.getFeedAd(
          adConfig: mockAdConfig,
          adType: AdType.native,
          adThemeStyle: FakeAdThemeStyle(),
          userTier: AccessTier.guest,
        );
        expect(result, isNull);
      });

      test('returns null if feed ads are disabled for user tier', () async {
        when(() => mockFeedAdConfig.visibleTo).thenReturn({});
        final result = await adManager.getFeedAd(
          adConfig: mockAdConfig,
          adType: AdType.native,
          adThemeStyle: FakeAdThemeStyle(),
          userTier: AccessTier.guest,
        );
        expect(result, isNull);
      });

      test('successfully loads and returns a native ad', () async {
        final mockAd = MockNativeAd();
        when(
          () => mockAdMobProvider.loadNativeAd(
            adPlatformIdentifiers: any(named: 'adPlatformIdentifiers'),
            adId: any(named: 'adId'),
            adThemeStyle: any(named: 'adThemeStyle'),
            feedItemImageStyle: any(named: 'feedItemImageStyle'),
          ),
        ).thenAnswer((_) async => mockAd);

        final result = await adManager.getFeedAd(
          adConfig: mockAdConfig,
          adType: AdType.native,
          adThemeStyle: FakeAdThemeStyle(),
          userTier: AccessTier.guest,
        );

        expect(result, same(mockAd));
        verify(
          () => mockAdMobProvider.loadNativeAd(
            adPlatformIdentifiers: mockAdPlatformIdentifiers,
            adId: any(named: 'adId'),
            adThemeStyle: any(named: 'adThemeStyle'),
            feedItemImageStyle: any(named: 'feedItemImageStyle'),
          ),
        ).called(1);
      });

      test('retries loading on failure and eventually returns null', () async {
        when(
          () => mockAdMobProvider.loadNativeAd(
            adPlatformIdentifiers: any(named: 'adPlatformIdentifiers'),
            adId: any(named: 'adId'),
            adThemeStyle: any(named: 'adThemeStyle'),
            feedItemImageStyle: any(named: 'feedItemImageStyle'),
          ),
        ).thenAnswer((_) async => null);

        final result = await adManager.getFeedAd(
          adConfig: mockAdConfig,
          adType: AdType.native,
          adThemeStyle: FakeAdThemeStyle(),
          userTier: AccessTier.guest,
        );

        expect(result, isNull);
        verify(
          () => mockAdMobProvider.loadNativeAd(
            adPlatformIdentifiers: any(named: 'adPlatformIdentifiers'),
            adId: any(named: 'adId'),
            adThemeStyle: any(named: 'adThemeStyle'),
            feedItemImageStyle: any(named: 'feedItemImageStyle'),
          ),
        ).called(3); // 1 initial + 2 retries
      });
    });

    group('injectFeedAdPlaceholders', () {
      late List<FeedItem> feedItems;
      late MockUser mockUser;
      late RemoteConfig remoteConfig;
      late MockUserRewards mockUserRewards;

      setUp(() {
        feedItems = List.generate(
          20,
          (i) => Headline.fromJson(const {
            'id': 'id',
            'title': 'title',
            'url': 'url',
            'imageUrl': 'imageUrl',
            'source': {
              'id': 'id',
              'name': 'name',
              'description': 'description',
              'url': 'url',
              'logoUrl': 'logoUrl',
              'language': {
                'id': 'id',
                'code': 'en',
                'name': 'English',
                'nativeName': 'English',
                'createdAt': '2024-01-01T00:00:00.000Z',
                'updatedAt': '2024-01-01T00:00:00.000Z',
                'status': 'active',
              },
              'headquarters': {
                'id': 'id',
                'isoCode': 'US',
                'name': 'USA',
                'flagUrl': 'url',
                'createdAt': '2024-01-01T00:00:00.000Z',
                'updatedAt': '2024-01-01T00:00:00.000Z',
                'status': 'active',
              },
              'createdAt': '2024-01-01T00:00:00.000Z',
              'updatedAt': '2024-01-01T00:00:00.000Z',
              'status': 'active',
              'sourceType': 'newsAgency',
            },
            'eventCountry': {
              'id': 'id',
              'isoCode': 'US',
              'name': 'USA',
              'flagUrl': 'url',
              'createdAt': '2024-01-01T00:00:00.000Z',
              'updatedAt': '2024-01-01T00:00:00.000Z',
              'status': 'active',
            },
            'topic': {
              'id': 'id',
              'name': 'name',
              'description': 'description',
              'iconUrl': 'iconUrl',
              'createdAt': '2024-01-01T00:00:00.000Z',
              'updatedAt': '2024-01-01T00:00:00.000Z',
              'status': 'active',
            },
            'createdAt': '2024-01-01T00:00:00.000Z',
            'updatedAt': '2024-01-01T00:00:00.000Z',
            'status': 'active',
            'isBreaking': false,
            'type': 'headline',
          }),
        );
        mockUser = MockUser();
        mockUserRewards = MockUserRewards();
        remoteConfig = RemoteConfig.fromJson(const {
          'id': 'config',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-01T00:00:00.000Z',
          'app': {
            'maintenance': {'isUnderMaintenance': false},
            'update': {
              'latestAppVersion': '1.0.0',
              'isLatestVersionOnly': false,
              'iosUpdateUrl': 'url',
              'androidUpdateUrl': 'url',
            },
            'general': {'termsOfServiceUrl': 'url', 'privacyPolicyUrl': 'url'},
          },
          'features': {
            'analytics': {
              'enabled': true,
              'activeProvider': 'firebase',
              'disabledEvents': <dynamic>[],
              'eventSamplingRates': <String, dynamic>{},
            },
            'ads': {
              'enabled': true,
              'primaryAdPlatform': 'admob',
              'platformAdIdentifiers': {
                'admob': {
                  'androidNativeAdId': 'android-native-id',
                  'iosNativeAdId': 'ios-native-id',
                },
              },
              'feedAdConfiguration': {
                'enabled': true,
                'adType': 'native',
                'visibleTo': {
                  'guest': {'adFrequency': 5, 'adPlacementInterval': 3},
                },
              },
              'navigationAdConfiguration': {
                'enabled': true,
                'visibleTo': {
                  'guest': {
                    'internalNavigationsBeforeShowingInterstitialAd': 3,
                    'externalNavigationsBeforeShowingInterstitialAd': 1,
                  },
                },
              },
            },
            'pushNotifications': {
              'enabled': true,
              'primaryProvider': 'firebase',
              'deliveryConfigs': <String, dynamic>{},
            },
            'feed': <String, dynamic>{
              'itemClickBehavior': 'default',
              'decorators': <String, dynamic>{},
            },
            'community': {
              'enabled': true,
              'engagement': {
                'enabled': true,
                'engagementMode': 'reactionsAndComments',
              },
              'reporting': {
                'enabled': true,
                'headlineReportingEnabled': true,
                'sourceReportingEnabled': true,
                'commentReportingEnabled': true,
              },
              'appReview': {
                'enabled': true,
                'interactionCycleThreshold': 5,
                'initialPromptCooldownDays': 30,
                'eligiblePositiveInteractions': <dynamic>[],
                'isNegativeFeedbackFollowUpEnabled': true,
                'isPositiveFeedbackFollowUpEnabled': true,
              },
            },
            'rewards': {
              'enabled': true,
              'rewards': {
                'adFree': {'enabled': true, 'durationDays': 1},
              },
            },
          },
          'user': {
            'limits': {
              'followedItems': {'guest': 10},
              'savedHeadlines': {'guest': 10},
              'savedHeadlineFilters': {
                'guest': {'total': 5, 'pinned': 2},
              },
              'savedSourceFilters': {
                'guest': {'total': 5, 'pinned': 2},
              },
              'reactionsPerDay': {'guest': 20},
              'commentsPerDay': {'guest': 5},
              'reportsPerDay': {'guest': 5},
            },
          },
        });
        when(() => mockUser.tier).thenReturn(AccessTier.guest);
        when(() => mockUserRewards.isRewardActive(any())).thenReturn(false);
      });

      test('does not inject ads if user has adFree reward', () async {
        when(
          () => mockUserRewards.isRewardActive(RewardType.adFree),
        ).thenReturn(true);

        final result = await adManager.injectFeedAdPlaceholders(
          feedItems: feedItems,
          user: mockUser,
          remoteConfig: remoteConfig,
          imageStyle: FeedItemImageStyle.smallThumbnail,
          adThemeStyle: FakeAdThemeStyle(),
          userRewards: mockUserRewards,
        );

        expect(result.whereType<AdPlaceholder>().length, 0);
      });

      test(
        'injects ad placeholders correctly based on frequency and interval',
        () async {
          final result = await adManager.injectFeedAdPlaceholders(
            feedItems: feedItems,
            user: mockUser,
            remoteConfig: remoteConfig,
            imageStyle: FeedItemImageStyle.smallThumbnail,
            adThemeStyle: FakeAdThemeStyle(),
            userRewards: mockUserRewards,
          );

          // Expected positions: after item 3 (index 3), after item 8 (index 9), after item 13 (index 15), after item 18 (index 21)
          // adPlacementInterval = 3, adFrequency = 5
          // 1, 2, 3, AD, 4, 5, 6, 7, 8, AD, 9, 10, 11, 12, 13, AD, 14, 15, 16, 17, 18, AD
          expect(result.whereType<AdPlaceholder>().length, 4);
          expect(result[3], isA<AdPlaceholder>());
          expect(result[9], isA<AdPlaceholder>());
          expect(result[15], isA<AdPlaceholder>());
          expect(result[21], isA<AdPlaceholder>());
        },
      );
    });
  });
}
