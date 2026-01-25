import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/rewarded_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/rewards/view/rewards_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockRewardedAdManager extends Mock implements RewardedAdManager {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockRemoteConfig extends Mock implements RemoteConfig {}

class MockFeaturesConfig extends Mock implements FeaturesConfig {}

class MockRewardsConfig extends Mock implements RewardsConfig {}

class MockUserRewards extends Mock implements UserRewards {}

void main() {
  setUpAll(() {
    registerFallbackValue(RewardType.adFree);
    registerFallbackValue(AnalyticsEvent.rewardsHubViewed);
  });

  late AppBloc appBloc;
  late RewardedAdManager rewardedAdManager;
  late AnalyticsService analyticsService;
  late RemoteConfig remoteConfig;
  late FeaturesConfig featuresConfig;
  late RewardsConfig rewardsConfig;
  late UserRewards userRewards;

  const rewardDetails = RewardDetails(enabled: true, durationDays: 7);
  final rewardsMap = {
    RewardType.adFree: rewardDetails,
    RewardType.dailyDigest: rewardDetails,
  };

  setUp(() {
    appBloc = MockAppBloc();
    rewardedAdManager = MockRewardedAdManager();
    analyticsService = MockAnalyticsService();
    remoteConfig = MockRemoteConfig();
    featuresConfig = MockFeaturesConfig();
    rewardsConfig = MockRewardsConfig();
    userRewards = MockUserRewards();

    // Setup Remote Config Mocks
    when(() => remoteConfig.features).thenReturn(featuresConfig);
    when(() => featuresConfig.rewards).thenReturn(rewardsConfig);
    when(() => rewardsConfig.rewards).thenReturn(rewardsMap);

    // Setup User Rewards Mocks
    when(() => userRewards.isRewardActive(any())).thenReturn(false);
    when(() => userRewards.activeRewards).thenReturn({});

    // Setup AppBloc State
    when(() => appBloc.state).thenReturn(
      AppState(
        status: AppLifeCycleStatus.authenticated,
        remoteConfig: remoteConfig,
        userRewards: userRewards,
      ),
    );

    // Setup Analytics
    when(
      () => analyticsService.logEvent(any(), payload: any(named: 'payload')),
    ).thenAnswer((_) async {});
  });

  Widget buildSubject() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: rewardedAdManager),
          RepositoryProvider.value(value: analyticsService),
        ],
        child: BlocProvider.value(value: appBloc, child: const RewardsPage()),
      ),
    );
  }

  group('RewardsPage', () {
    testWidgets('renders available rewards from remote config', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.textContaining('Ad-Free'), findsOneWidget);
      expect(find.textContaining('Daily Digest'), findsOneWidget);
      expect(find.byType(FilledButton), findsNWidgets(2));

      verify(
        () => analyticsService.logEvent(
          AnalyticsEvent.rewardsHubViewed,
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    testWidgets('triggers ad flow when "Watch Ad" is tapped', (tester) async {
      when(
        () => rewardedAdManager.showAd(
          rewardType: any(named: 'rewardType'),
          onAdShowed: any(named: 'onAdShowed'),
          onAdFailedToShow: any(named: 'onAdFailedToShow'),
          onAdDismissed: any(named: 'onAdDismissed'),
          onRewardEarned: any(named: 'onRewardEarned'),
        ),
      ).thenAnswer((invocation) async {
        // Simulate ad showed
        final onAdShowed =
            invocation.namedArguments[#onAdShowed] as RewardedAdShowCallback;
        onAdShowed();
      });

      await tester.pumpWidget(buildSubject());

      await tester.tap(find.byType(FilledButton).first);
      await tester.pump();

      verify(
        () => rewardedAdManager.showAd(
          rewardType: RewardType.adFree,
          onAdShowed: any(named: 'onAdShowed'),
          onAdFailedToShow: any(named: 'onAdFailedToShow'),
          onAdDismissed: any(named: 'onAdDismissed'),
          onRewardEarned: any(named: 'onRewardEarned'),
        ),
      ).called(1);

      verify(
        () => analyticsService.logEvent(
          AnalyticsEvent.rewardOfferClicked,
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    testWidgets('shows snackbar on ad failure', (tester) async {
      when(
        () => rewardedAdManager.showAd(
          rewardType: any(named: 'rewardType'),
          onAdShowed: any(named: 'onAdShowed'),
          onAdFailedToShow: any(named: 'onAdFailedToShow'),
          onAdDismissed: any(named: 'onAdDismissed'),
          onRewardEarned: any(named: 'onRewardEarned'),
        ),
      ).thenAnswer((invocation) async {
        final onAdFailedToShow =
            invocation.namedArguments[#onAdFailedToShow]
                as RewardedAdFailedToShowCallback;
        onAdFailedToShow('Network Error');
      });

      await tester.pumpWidget(buildSubject());

      await tester.tap(find.byType(FilledButton).first);
      await tester.pump(); // Process tap
      await tester.pumpAndSettle(); // Process snackbar animation

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets(
      'shows verifying state and dispatches refresh on reward earned',
      (tester) async {
        when(
          () => rewardedAdManager.showAd(
            rewardType: any(named: 'rewardType'),
            onAdShowed: any(named: 'onAdShowed'),
            onAdFailedToShow: any(named: 'onAdFailedToShow'),
            onAdDismissed: any(named: 'onAdDismissed'),
            onRewardEarned: any(named: 'onRewardEarned'),
          ),
        ).thenAnswer((invocation) async {
          final onRewardEarned =
              invocation.namedArguments[#onRewardEarned]
                  as RewardEarnedCallback;
          onRewardEarned(RewardType.adFree);
        });

        await tester.pumpWidget(buildSubject());

        await tester.tap(find.byType(FilledButton).first);
        await tester.pump();

        // Verify loading state (Verifying...)
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Verify AppBloc event dispatched
        verify(() => appBloc.add(const UserRewardsRefreshed())).called(1);
      },
    );

    testWidgets(
      'updates UI to active and shows success snackbar when reward activates',
      (tester) async {
        // Setup a controller to manually drive the bloc stream.
        // This allows us to emit states *after* the widget has subscribed.
        final stateController = StreamController<AppState>.broadcast();
        when(() => appBloc.stream).thenAnswer((_) => stateController.stream);

        // 1. Start with no active rewards
        when(
          () => rewardedAdManager.showAd(
            rewardType: any(named: 'rewardType'),
            onAdShowed: any(named: 'onAdShowed'),
            onAdFailedToShow: any(named: 'onAdFailedToShow'),
            onAdDismissed: any(named: 'onAdDismissed'),
            onRewardEarned: any(named: 'onRewardEarned'),
          ),
        ).thenAnswer((invocation) async {
          final onRewardEarned =
              invocation.namedArguments[#onRewardEarned]
                  as RewardEarnedCallback;
          onRewardEarned(RewardType.adFree);
        });

        await tester.pumpWidget(buildSubject());

        // 2. Trigger ad watch
        await tester.tap(find.byType(FilledButton).first);
        await tester.pump();

        // 3. Simulate AppBloc state update (Reward Activated)
        final activeUserRewards = MockUserRewards();
        // Ensure isRewardActive returns false by default for other types (e.g. Daily Digest)
        when(() => activeUserRewards.isRewardActive(any())).thenReturn(false);
        when(
          () => activeUserRewards.isRewardActive(RewardType.adFree),
        ).thenReturn(true);
        when(() => activeUserRewards.activeRewards).thenReturn({
          RewardType.adFree: DateTime.now().add(const Duration(days: 7)),
        });

        final newState = AppState(
          status: AppLifeCycleStatus.authenticated,
          remoteConfig: remoteConfig,
          userRewards: activeUserRewards,
        );

        // Update the state getter and emit the new state
        when(() => appBloc.state).thenReturn(newState);
        stateController.add(newState);

        // Pump to process the stream event and then pump for animation
        await tester.pump();
        await tester.pump(
          const Duration(seconds: 1),
        ); // Allow SnackBar animation

        // Verify Success SnackBar
        expect(find.byType(SnackBar), findsOneWidget);

        // Verify UI update (Active state)
        expect(find.text('Ad-Free Active'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(
          find.byType(FilledButton),
          findsNWidgets(2),
        ); // Both buttons present

        verify(
          () => analyticsService.logEvent(
            AnalyticsEvent.rewardGranted,
            payload: any(named: 'payload'),
          ),
        ).called(1);

        await stateController.close();
      },
    );
  });
}
