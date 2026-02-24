import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/rewards/bloc/rewards_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class FakeAppEvent extends Fake implements AppEvent {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockUserRewards extends Mock implements UserRewards {}

class MockRemoteConfig extends Mock implements RemoteConfig {}

class MockFeaturesConfig extends Mock implements FeaturesConfig {}

class MockRewardsConfig extends Mock implements RewardsConfig {}

class MockUser extends Mock implements User {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAppEvent());
    registerFallbackValue(AnalyticsEvent.rewardsHubViewed);
  });

  group('RewardsBloc', () {
    late AppBloc appBloc;
    late AnalyticsService analyticsService;
    late UserRewards userRewards;
    late RemoteConfig remoteConfig;
    late FeaturesConfig featuresConfig;
    late RewardsConfig rewardsConfig;
    late User user;

    setUp(() {
      appBloc = MockAppBloc();
      analyticsService = MockAnalyticsService();
      userRewards = MockUserRewards();
      remoteConfig = MockRemoteConfig();
      featuresConfig = MockFeaturesConfig();
      rewardsConfig = MockRewardsConfig();
      user = MockUser();

      when(() => user.id).thenReturn('test-user-id');

      when(() => remoteConfig.features).thenReturn(featuresConfig);
      when(() => featuresConfig.rewards).thenReturn(rewardsConfig);
      when(() => rewardsConfig.rewards).thenReturn({
        RewardType.adFree: const RewardDetails(enabled: true, durationDays: 1),
      });

      when(() => appBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.authenticated,
          remoteConfig: remoteConfig,
          user: user,
        ),
      );
      when(
        () => analyticsService.logEvent(any(), payload: any(named: 'payload')),
      ).thenAnswer((_) async {});
    });

    test('initial state is RewardsInitial', () {
      expect(
        RewardsBloc(appBloc: appBloc, analyticsService: analyticsService).state,
        const RewardsInitial(),
      );
    });

    blocTest<RewardsBloc, RewardsState>(
      'logs event when RewardsStarted is added',
      build: () =>
          RewardsBloc(appBloc: appBloc, analyticsService: analyticsService),
      act: (bloc) => bloc.add(RewardsStarted()),
      verify: (_) {
        verify(
          () => analyticsService.logEvent(
            AnalyticsEvent.rewardsHubViewed,
            payload: any(named: 'payload'),
          ),
        ).called(1);
      },
    );

    blocTest<RewardsBloc, RewardsState>(
      'emits [RewardsLoadingAd] when RewardsAdRequested is added',
      build: () =>
          RewardsBloc(appBloc: appBloc, analyticsService: analyticsService),
      act: (bloc) => bloc.add(RewardsAdRequested()),
      expect: () => [const RewardsLoadingAd()],
    );

    blocTest<RewardsBloc, RewardsState>(
      'emits [RewardsInitial] with snackbar message on RewardsAdFailed',
      build: () =>
          RewardsBloc(appBloc: appBloc, analyticsService: analyticsService),
      act: (bloc) => bloc.add(RewardsAdFailed()),
      expect: () => [
        const RewardsInitial(snackbarMessage: 'rewardsSnackbarFailure'),
      ],
    );

    blocTest<RewardsBloc, RewardsState>(
      'emits [RewardsInitial] with snackbar message on RewardsAdDismissed',
      build: () =>
          RewardsBloc(appBloc: appBloc, analyticsService: analyticsService),
      act: (bloc) => bloc.add(RewardsAdDismissed()),
      expect: () => [
        const RewardsInitial(snackbarMessage: 'rewardsAdDismissedSnackbar'),
      ],
    );

    blocTest<RewardsBloc, RewardsState>(
      'emits state with null snackbarMessage on SnackbarShown',
      build: () =>
          RewardsBloc(appBloc: appBloc, analyticsService: analyticsService),
      seed: () => const RewardsInitial(snackbarMessage: 'message'),
      act: (bloc) => bloc.add(SnackbarShown()),
      expect: () => [const RewardsInitial()],
    );

    blocTest<RewardsBloc, RewardsState>(
      'emits [RewardsVerifying] and starts timer on RewardsAdWatched',
      build: () =>
          RewardsBloc(appBloc: appBloc, analyticsService: analyticsService),
      seed: () => const RewardsLoadingAd(),
      act: (bloc) => bloc.add(RewardsAdWatched()),
      expect: () => [const RewardsVerifying()],
    );

    blocTest<RewardsBloc, RewardsState>(
      'dispatches UserRewardsRefreshed when timer ticks',
      build: () =>
          RewardsBloc(appBloc: appBloc, analyticsService: analyticsService),
      seed: () => const RewardsVerifying(),
      act: (bloc) => bloc.add(RewardsTimerTicked()),
      verify: (_) {
        verify(
          () => appBloc.add(any(that: isA<UserRewardsRefreshed>())),
        ).called(1);
      },
    );

    blocTest<RewardsBloc, RewardsState>(
      'emits [RewardsSuccess] when reward is verified',
      build: () {
        when(
          () => userRewards.isRewardActive(RewardType.adFree),
        ).thenReturn(true);
        when(
          () => appBloc.add(any(that: isA<UserRewardsRefreshed>())),
        ).thenAnswer((invocation) {
          final event =
              invocation.positionalArguments.first as UserRewardsRefreshed;
          event.completer?.complete(userRewards);
        });
        return RewardsBloc(
          appBloc: appBloc,
          analyticsService: analyticsService,
        );
      },
      seed: () => const RewardsVerifying(),
      act: (bloc) => bloc.add(RewardsTimerTicked()),
      wait: const Duration(milliseconds: 100), // Allow future to complete
      expect: () => [const RewardsSuccess()],
      verify: (_) {
        verify(
          () => analyticsService.logEvent(
            AnalyticsEvent.rewardGranted,
            payload: any(named: 'payload'),
          ),
        ).called(1);
      },
    );

    blocTest<RewardsBloc, RewardsState>(
      'emits nothing when reward is not yet active',
      build: () {
        when(
          () => userRewards.isRewardActive(RewardType.adFree),
        ).thenReturn(false);
        when(
          () => appBloc.add(any(that: isA<UserRewardsRefreshed>())),
        ).thenAnswer((invocation) {
          final event =
              invocation.positionalArguments.first as UserRewardsRefreshed;
          event.completer?.complete(userRewards);
        });
        return RewardsBloc(
          appBloc: appBloc,
          analyticsService: analyticsService,
        );
      },
      seed: () => const RewardsVerifying(),
      act: (bloc) => bloc.add(RewardsTimerTicked()),
      wait: const Duration(milliseconds: 100),
      expect: () => <RewardsState>[],
    );
  });
}
