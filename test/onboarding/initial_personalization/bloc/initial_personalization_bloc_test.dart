import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/initialization_result.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/onboarding/initial_personalization/bloc/initial_personalization_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockAppBloc extends Mock implements AppBloc {}

class MockDataRepository<T> extends Mock implements DataRepository<T> {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockLogger extends Mock implements Logger {}

class MockUser extends Mock implements User {}

class MockUserContext extends Mock implements UserContext {}

class MockRemoteConfig extends Mock implements RemoteConfig {}

class MockUserConfig extends Mock implements UserConfig {}

class MockUserLimitsConfig extends Mock implements UserLimitsConfig {}

class MockUserContentPreferences extends Mock
    implements UserContentPreferences {}

class FakeAnalyticsEventPayload extends Fake implements AnalyticsEventPayload {}

void main() {
  group('InitialPersonalizationBloc', () {
    late AppBloc appBloc;
    late DataRepository<UserContentPreferences>
    userContentPreferencesRepository;
    late DataRepository<UserContext> userContextRepository;
    late AnalyticsService analyticsService;
    late Logger logger;
    late User user;
    late UserContext userContext;
    late RemoteConfig remoteConfig;
    late UserConfig userConfig;
    late UserLimitsConfig userLimitsConfig;
    late UserContentPreferences userContentPreferences;

    const userId = 'user-id';
    final topic1 = Topic(
      id: 't1',
      name: 'Topic 1',
      description: '',
      iconUrl: '',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      status: ContentStatus.active,
    );

    setUpAll(() {
      registerFallbackValue(
        const AppOnboardingCompleted(
          status: OnboardingStatus.postAuthPersonalization,
        ),
      );
      registerFallbackValue(AnalyticsEvent.initialPersonalizationStarted);
      registerFallbackValue(FakeAnalyticsEventPayload());
    });

    setUp(() {
      appBloc = MockAppBloc();
      userContentPreferencesRepository = MockDataRepository();
      userContextRepository = MockDataRepository();
      analyticsService = MockAnalyticsService();
      logger = MockLogger();
      user = MockUser();
      userContext = MockUserContext();
      remoteConfig = MockRemoteConfig();
      userConfig = MockUserConfig();
      userLimitsConfig = MockUserLimitsConfig();
      userContentPreferences = MockUserContentPreferences();

      when(() => user.id).thenReturn(userId);
      when(() => user.tier).thenReturn(AccessTier.standard);
      when(() => userContext.id).thenReturn(userId);
      when(() => userContentPreferences.id).thenReturn(userId);
      when(
        () => userContentPreferences.copyWith(
          followedTopics: any(named: 'followedTopics'),
          followedSources: any(named: 'followedSources'),
          followedCountries: any(named: 'followedCountries'),
        ),
      ).thenReturn(userContentPreferences);
      when(
        () => userContext.copyWith(
          hasCompletedInitialPersonalization: any(
            named: 'hasCompletedInitialPersonalization',
          ),
        ),
      ).thenReturn(userContext);

      when(
        () => userLimitsConfig.followedItems,
      ).thenReturn({AccessTier.standard: 10});
      when(() => userConfig.limits).thenReturn(userLimitsConfig);
      when(() => remoteConfig.user).thenReturn(userConfig);

      when(() => appBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.postAuthOnboardingRequired,
          user: user,
          userContext: userContext,
          remoteConfig: remoteConfig,
          userContentPreferences: userContentPreferences,
        ),
      );

      when(
        () => analyticsService.logEvent(any(), payload: any(named: 'payload')),
      ).thenAnswer((_) async {});
      when(() => appBloc.add(any())).thenAnswer((_) async {});
    });

    InitialPersonalizationBloc buildBloc() {
      return InitialPersonalizationBloc(
        appBloc: appBloc,
        userContentPreferencesRepository: userContentPreferencesRepository,
        userContextRepository: userContextRepository,
        analyticsService: analyticsService,
        logger: logger,
      );
    }

    test('initial state is correct', () {
      expect(buildBloc().state, const InitialPersonalizationState());
    });

    test('logs InitialPersonalizationStarted on creation', () {
      buildBloc();
      verify(
        () => analyticsService.logEvent(
          AnalyticsEvent.initialPersonalizationStarted,
          payload: const InitialPersonalizationStartedPayload(),
        ),
      ).called(1);
    });

    blocTest<InitialPersonalizationBloc, InitialPersonalizationState>(
      'InitialPersonalizationDataRequested fetches limits and emits success',
      build: buildBloc,
      act: (bloc) => bloc.add(InitialPersonalizationDataRequested()),
      expect: () => [
        const InitialPersonalizationState(
          status: InitialPersonalizationStatus.loading,
        ),
        const InitialPersonalizationState(
          status: InitialPersonalizationStatus.success,
          maxSelectionsPerCategory: 10,
        ),
      ],
    );

    blocTest<InitialPersonalizationBloc, InitialPersonalizationState>(
      'InitialPersonalizationItemsSelected updates state',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(InitialPersonalizationItemsSelected<Topic>(items: {topic1})),
      expect: () => [
        InitialPersonalizationState(selectedTopics: {topic1}),
      ],
    );

    group('InitialPersonalizationCompleted', () {
      blocTest<InitialPersonalizationBloc, InitialPersonalizationState>(
        'saves preferences and completes onboarding',
        setUp: () {
          when(
            () => userContentPreferencesRepository.update(
              id: userId,
              item: userContentPreferences,
            ),
          ).thenAnswer((_) async => userContentPreferences);
          when(
            () => userContextRepository.update(id: userId, item: userContext),
          ).thenAnswer((_) async => userContext);
        },
        build: buildBloc,
        act: (bloc) => bloc.add(InitialPersonalizationCompleted()),
        expect: () => [
          const InitialPersonalizationState(
            status: InitialPersonalizationStatus.saving,
          ),
        ],
        verify: (_) {
          verify(
            () => userContentPreferencesRepository.update(
              id: userId,
              item: userContentPreferences,
            ),
          ).called(1);
          verify(
            () => userContextRepository.update(id: userId, item: userContext),
          ).called(1);
          verify(
            () => analyticsService.logEvent(
              AnalyticsEvent.initialPersonalizationCompleted,
              payload: const InitialPersonalizationCompletedPayload(),
            ),
          ).called(1);
          verify(
            () => appBloc.add(any(that: isA<AppOnboardingCompleted>())),
          ).called(1);
        },
      );
    });

    group('InitialPersonalizationSkipped', () {
      blocTest<InitialPersonalizationBloc, InitialPersonalizationState>(
        'updates context and completes onboarding',
        setUp: () {
          when(
            () => userContextRepository.update(id: userId, item: userContext),
          ).thenAnswer((_) async => userContext);
        },
        build: buildBloc,
        act: (bloc) => bloc.add(InitialPersonalizationSkipped()),
        expect: () => [
          const InitialPersonalizationState(
            status: InitialPersonalizationStatus.saving,
          ),
        ],
        verify: (_) {
          verify(
            () => userContextRepository.update(id: userId, item: userContext),
          ).called(1);
          verify(
            () => analyticsService.logEvent(
              AnalyticsEvent.initialPersonalizationSkipped,
              payload: const InitialPersonalizationSkippedPayload(),
            ),
          ).called(1);
          verify(
            () => appBloc.add(any(that: isA<AppOnboardingCompleted>())),
          ).called(1);
        },
      );
    });
  });
}
