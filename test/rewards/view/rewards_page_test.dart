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

class FakeAppEvent extends Fake implements AppEvent {}

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
    registerFallbackValue(FakeAppEvent());
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

    testWidgets('shows verifying state and calls AppBloc on reward earned', (
      tester,
    ) async {
      // 1. Mock the ad manager to call onRewardEarned
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
            invocation.namedArguments[#onRewardEarned] as RewardEarnedCallback;
        onRewardEarned(RewardType.adFree);
      });

      // 2. Mock the app bloc to do nothing with the completer
      when(
        () => appBloc.add(any(that: isA<UserRewardsRefreshed>())),
      ).thenAnswer((_) {});

      // 3. Build and interact
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(FilledButton).first);
      await tester.pump(); // Enters verifying state

      // 4. Verify UI state
      final l10n = AppLocalizations.of(tester.element(find.byType(ListView)));
      expect(find.text(l10n.rewardsOfferVerifyingButton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 5. Advance timer and verify AppBloc call
      await tester.pump(const Duration(seconds: 2));
      verify(
        () => appBloc.add(any(that: isA<UserRewardsRefreshed>())),
      ).called(1);
    });

    testWidgets(
      'updates UI to active and shows success snackbar when reward activates',
      (tester) async {
        final appStateController = StreamController<AppState>();
        // 1. Mocks
        final activeUserRewards = MockUserRewards();
        when(
          () => activeUserRewards.isRewardActive(RewardType.adFree),
        ).thenReturn(true);
        when(
          () => activeUserRewards.isRewardActive(RewardType.dailyDigest),
        ).thenReturn(false);
        when(() => activeUserRewards.activeRewards).thenReturn({
          RewardType.adFree: DateTime.now().add(const Duration(days: 7)),
        });

        final appStateWithActiveReward = AppState(
          status: AppLifeCycleStatus.authenticated,
          remoteConfig: remoteConfig,
          userRewards: activeUserRewards,
        );

        whenListen(
          appBloc,
          appStateController.stream,
          initialState: appBloc.state,
        );

        // 2. Mock AppBloc.add to complete the completer and trigger state change
        when(
          () => appBloc.add(any(that: isA<UserRewardsRefreshed>())),
        ).thenAnswer((invocation) {
          final event =
              invocation.positionalArguments.first as UserRewardsRefreshed;
          event.completer?.complete(activeUserRewards);
          appStateController.add(appStateWithActiveReward);
        });

        // 3. Mock ad manager
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

        // 4. Build and interact
        await tester.pumpWidget(buildSubject());
        await tester.tap(find.byType(FilledButton).first);
        await tester.pump(); // Enter verifying state

        // 5. Advance timer and process completer
        await tester.pump(const Duration(seconds: 2)); // Timer tick
        await tester.pump(); // Process the future and state emission
        await tester.pumpAndSettle(); // Settle UI animations

        // 6. Get l10n instance for verification
        final l10n = AppLocalizations.of(tester.element(find.byType(ListView)));
        final rewardName = l10n.rewardTypeAdFree;

        // 7. Verify
        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.text(l10n.rewardsSnackbarSuccess(rewardName)),
          findsOneWidget,
        );
        expect(
          find.text(l10n.rewardsOfferActiveTitle(rewardName)),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text(l10n.rewardsOfferActiveButton), findsOneWidget);

        verify(
          () => analyticsService.logEvent(
            AnalyticsEvent.rewardGranted,
            payload: any(named: 'payload'),
          ),
        ).called(1);
        unawaited(appStateController.close());
      },
    );

    testWidgets('shows countdown timer for active reward', (tester) async {
      final expiry = DateTime.now().add(const Duration(hours: 1, minutes: 30));
      final activeRewards = MockUserRewards();
      when(() => activeRewards.isRewardActive(any())).thenReturn(false);
      when(
        () => activeRewards.isRewardActive(RewardType.adFree),
      ).thenReturn(true);
      when(
        () => activeRewards.activeRewards,
      ).thenReturn({RewardType.adFree: expiry});

      when(() => appBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.authenticated,
          remoteConfig: remoteConfig,
          userRewards: activeRewards,
        ),
      );

      await tester.pumpWidget(buildSubject());

      // Use a flexible matcher to account for minor timing differences in tests.
      final countdownFinder = find.textContaining(RegExp('Expires in: 1h'));

      expect(countdownFinder, findsOneWidget);
    });
  });
}
