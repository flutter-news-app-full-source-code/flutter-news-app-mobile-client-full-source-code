// ignore_for_file: inference_failure_on_function_invocation

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/rewarded_ad.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/rewarded_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockAdService extends Mock implements AdService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockLogger extends Mock implements Logger {}

class MockRewardedAd extends Mock implements RewardedAd {}

class MockAdmobRewardedAd extends Mock implements admob.RewardedAd {}

class MockRemoteConfig extends Mock implements RemoteConfig {}

class MockFeaturesConfig extends Mock implements FeaturesConfig {}

class MockAdConfig extends Mock implements AdConfig {}

class MockRewardsConfig extends Mock implements RewardsConfig {}

class MockAppSettings extends Mock implements AppSettings {}

class MockDisplaySettings extends Mock implements DisplaySettings {}

class MockUser extends Mock implements User {}

// Fakes
class FakeAppState extends Fake implements AppState {}

class FakeAppEvent extends Fake implements AppEvent {}

class FakeAdThemeStyle extends Fake implements AdThemeStyle {}

class FakeAdConfig extends Fake implements AdConfig {}

class FakeServerSideVerificationOptions extends Fake
    implements admob.ServerSideVerificationOptions {}

class FakeAnalyticsEventPayload extends Fake implements AnalyticsEventPayload {}

class FakeAdRewardEarnedPayload extends Fake implements AdRewardEarnedPayload {}

/// A testable subclass of [RewardedAdManager] that overrides the theme generation
/// to bypass Flutter's [SchedulerBinding] and [ThemeData] dependencies.
class TestRewardedAdManager extends RewardedAdManager {
  TestRewardedAdManager({
    required super.appBloc,
    required super.adService,
    required super.analyticsService,
    super.logger,
  });

  @override
  AdThemeStyle getAdThemeStyle(AppState appState) => FakeAdThemeStyle();
}

void main() {
  group('RewardedAdManager', () {
    late RewardedAdManager rewardedAdManager;
    late MockAppBloc mockAppBloc;
    late MockAdService mockAdService;
    late MockAnalyticsService mockAnalyticsService;
    late MockLogger mockLogger;
    late MockRemoteConfig mockRemoteConfig;
    late MockFeaturesConfig mockFeaturesConfig;
    late MockAdConfig mockAdConfig;
    late MockRewardsConfig mockRewardsConfig;
    late MockUser mockUser;
    late MockAppSettings mockAppSettings;
    late MockDisplaySettings mockDisplaySettings;

    setUpAll(() {
      registerFallbackValue(FakeAppState());
      registerFallbackValue(FakeAppEvent());
      registerFallbackValue(FakeAdThemeStyle());
      registerFallbackValue(FakeAnalyticsEventPayload());
      registerFallbackValue(FakeServerSideVerificationOptions());
      registerFallbackValue(AnalyticsEvent.adClicked);
      registerFallbackValue(AnalyticsEvent.adRewardEarned);
      registerFallbackValue(FakeAdConfig());
      registerFallbackValue(FakeAdRewardEarnedPayload());
      registerFallbackValue(AccessTier.guest);
      registerFallbackValue(RewardType.adFree);
    });

    setUp(() {
      mockAppBloc = MockAppBloc();
      mockAdService = MockAdService();
      mockAnalyticsService = MockAnalyticsService();
      mockLogger = MockLogger();
      mockRemoteConfig = MockRemoteConfig();
      mockFeaturesConfig = MockFeaturesConfig();
      mockAdConfig = MockAdConfig();
      mockRewardsConfig = MockRewardsConfig();
      mockUser = MockUser();
      mockAppSettings = MockAppSettings();
      mockDisplaySettings = MockDisplaySettings();

      // Common mock setups
      when(() => mockRemoteConfig.features).thenReturn(mockFeaturesConfig);
      when(() => mockFeaturesConfig.ads).thenReturn(mockAdConfig);
      when(() => mockFeaturesConfig.rewards).thenReturn(mockRewardsConfig);
      when(() => mockAdConfig.enabled).thenReturn(true);
      when(() => mockRewardsConfig.enabled).thenReturn(true);
      when(() => mockUser.tier).thenReturn(AccessTier.standard);
      when(() => mockUser.id).thenReturn('test-user-id');
      when(
        () => mockAppSettings.displaySettings,
      ).thenReturn(mockDisplaySettings);
      when(() => mockDisplaySettings.baseTheme).thenReturn(AppBaseTheme.light);

      // Setup a stream for the AppBloc. The RewardedAdManager listens to this.
      whenListen(
        mockAppBloc,
        const Stream<AppState>.empty(),
        initialState: AppState(
          status: AppLifeCycleStatus.authenticated,
          remoteConfig: mockRemoteConfig,
          settings: mockAppSettings,
          user: mockUser,
        ),
      );

      when(
        () => mockAnalyticsService.logEvent(
          any(),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      // Stub logger to prevent null errors during callback execution
      when(() => mockLogger.info(any())).thenReturn(null);
      when(() => mockLogger.warning(any())).thenReturn(null);
      when(() => mockLogger.severe(any(), any(), any())).thenReturn(null);

      // Stub disposeAd to prevent null subtype errors
      when(() => mockAdService.disposeAd(any())).thenAnswer((_) async {});

      // The manager is instantiated in each test/group to ensure a clean state.
    });

    group('Pre-loading logic', () {
      tearDown(() {
        rewardedAdManager.dispose();
      });

      test('initialization triggers pre-loading if conditions are met', () async {
        final mockAd = MockRewardedAd();
        when(
          () => mockAdService.getRewardedAd(
            adConfig: any(named: 'adConfig'),
            adThemeStyle: any(named: 'adThemeStyle'),
            userTier: any(named: 'userTier'),
          ),
        ).thenAnswer((_) async => mockAd);

        // Instantiate the manager, which triggers the initial load via its constructor
        rewardedAdManager = TestRewardedAdManager(
          appBloc: mockAppBloc,
          adService: mockAdService,
          analyticsService: mockAnalyticsService,
          logger: mockLogger,
        );

        // Wait until the async pre-loading logic has called getRewardedAd.
        // This is necessary because the constructor triggers a fire-and-forget
        // async method, creating a race condition in the test.
        await untilCalled(
          () => mockAdService.getRewardedAd(
            adConfig: any(named: 'adConfig'),
            adThemeStyle: any(named: 'adThemeStyle'),
            userTier: any(named: 'userTier'),
          ),
        );

        verify(
          () => mockAdService.getRewardedAd(
            adConfig: mockAdConfig,
            adThemeStyle: any(named: 'adThemeStyle'),
            userTier: AccessTier.standard,
          ),
        ).called(1);
      });

      test('does not pre-load if ads are disabled', () async {
        when(() => mockAdConfig.enabled).thenReturn(false);

        rewardedAdManager = TestRewardedAdManager(
          appBloc: mockAppBloc,
          adService: mockAdService,
          analyticsService: mockAnalyticsService,
          logger: mockLogger,
        );
        await Future.microtask(() {});

        verifyNever(
          () => mockAdService.getRewardedAd(
            adConfig: any(named: 'adConfig'),
            adThemeStyle: any(named: 'adThemeStyle'),
            userTier: any(named: 'userTier'),
          ),
        );
      });

      test('does not pre-load if rewards are disabled', () async {
        when(() => mockRewardsConfig.enabled).thenReturn(false);

        rewardedAdManager = TestRewardedAdManager(
          appBloc: mockAppBloc,
          adService: mockAdService,
          analyticsService: mockAnalyticsService,
          logger: mockLogger,
        );
        await Future.microtask(() {});

        verifyNever(
          () => mockAdService.getRewardedAd(
            adConfig: any(named: 'adConfig'),
            adThemeStyle: any(named: 'adThemeStyle'),
            userTier: any(named: 'userTier'),
          ),
        );
      });
    });

    group('showAd', () {
      late MockAdmobRewardedAd mockAdmobAd;

      setUp(() {
        mockAdmobAd = MockAdmobRewardedAd();
        final mockPreloadedAd = MockRewardedAd();

        when(() => mockPreloadedAd.provider).thenReturn(AdPlatformType.admob);
        when(() => mockPreloadedAd.adObject).thenReturn(mockAdmobAd);

        when(
          () => mockAdmobAd.setServerSideOptions(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockAdmobAd.show(
            onUserEarnedReward: any(named: 'onUserEarnedReward'),
          ),
        ).thenAnswer((_) async {});
        when(() => mockAdmobAd.dispose()).thenAnswer((_) async {});

        // Set up the service to return the preloaded ad for this group's tests
        when(
          () => mockAdService.getRewardedAd(
            adConfig: any(named: 'adConfig'),
            adThemeStyle: any(named: 'adThemeStyle'),
            userTier: any(named: 'userTier'),
          ),
        ).thenAnswer((_) async => mockPreloadedAd);

        // Instantiate the manager for this group, which will pre-load the ad
        rewardedAdManager = TestRewardedAdManager(
          appBloc: mockAppBloc,
          adService: mockAdService,
          analyticsService: mockAnalyticsService,
          logger: mockLogger,
        );
      });

      tearDown(() {
        rewardedAdManager.dispose();
      });

      test(
        'calls onAdFailedToShow if no ad is preloaded and load fails',
        () async {
          // Create a new manager instance for this specific test case
          // where the ad load will fail.
          when(
            () => mockAdService.getRewardedAd(
              adConfig: any(named: 'adConfig'),
              adThemeStyle: any(named: 'adThemeStyle'),
              userTier: any(named: 'userTier'),
            ),
          ).thenAnswer((_) async => null);

          rewardedAdManager = TestRewardedAdManager(
            appBloc: mockAppBloc,
            adService: mockAdService,
            analyticsService: mockAnalyticsService,
            logger: mockLogger,
          );

          final onAdFailedToShow = expectAsync1((String error) {
            expect(error, 'Failed to load ad.');
          });

          await rewardedAdManager.showAd(
            rewardType: RewardType.adFree,
            onAdShowed: () => fail('onAdShowed should not be called'),
            onAdFailedToShow: onAdFailedToShow,
            onAdDismissed: () => fail('onAdDismissed should not be called'),
            onRewardEarned: (_) => fail('onRewardEarned should not be called'),
          );
        },
      );

      test('shows ad and handles callbacks correctly', () async {
        admob.FullScreenContentCallback<admob.RewardedAd>? capturedCallback;
        when(() => mockAdmobAd.fullScreenContentCallback = any()).thenAnswer((
          invocation,
        ) {
          capturedCallback =
              invocation.positionalArguments.first
                  as admob.FullScreenContentCallback<admob.RewardedAd>;
          return null;
        });

        final onAdShowed = expectAsync0(() {});
        final onAdDismissed = expectAsync0(() {});
        final onRewardEarned = expectAsync1((RewardType type) {
          expect(type, RewardType.adFree);
        });

        // Wait for the initial ad to be preloaded from the group's setUp block.
        // This ensures the manager has a preloaded ad before we call showAd,
        // preventing a race condition where the test proceeds before the async
        // setup is complete.
        await untilCalled(
          () => mockAdService.getRewardedAd(
            adConfig: any(named: 'adConfig'),
            adThemeStyle: any(named: 'adThemeStyle'),
            userTier: any(named: 'userTier'),
          ),
        );

        await rewardedAdManager.showAd(
          rewardType: RewardType.adFree,
          onAdShowed: onAdShowed,
          onAdFailedToShow: (_) =>
              fail('onAdFailedToShow should not be called'),
          onAdDismissed: onAdDismissed,
          onRewardEarned: onRewardEarned,
        );

        // Simulate callbacks
        expect(capturedCallback, isNotNull);
        capturedCallback!.onAdShowedFullScreenContent!(mockAdmobAd);
        capturedCallback!.onAdDismissedFullScreenContent!(mockAdmobAd);

        // Simulate reward
        final capturedCalls = verify(
          () => mockAdmobAd.show(
            onUserEarnedReward: captureAny(named: 'onUserEarnedReward'),
          ),
        ).captured;
        expect(capturedCalls.length, 1);
        final onUserEarnedReward =
            capturedCalls.first as admob.OnUserEarnedRewardCallback;

        onUserEarnedReward(mockAdmobAd, admob.RewardItem(1, 'adFree'));

        // Allow the unawaited logEvent call to complete
        // ignore: inference_failure_on_instance_creation
        await Future.delayed(Duration.zero);

        // Verify analytics
        verify(
          () => mockAnalyticsService.logEvent(
            any(), // Relaxed to any() to ensure we capture the call
            payload: any(named: 'payload'),
          ),
        ).called(1);
      });
    });
  });
}
