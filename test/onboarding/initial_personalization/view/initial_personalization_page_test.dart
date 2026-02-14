import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/onboarding/initial_personalization/bloc/initial_personalization_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/onboarding/initial_personalization/view/initial_personalization_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/multi_select_search_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockInitialPersonalizationBloc
    extends MockBloc<InitialPersonalizationEvent, InitialPersonalizationState>
    implements InitialPersonalizationBloc {}

class MockDataRepository<T> extends Mock implements DataRepository<T> {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockLogger extends Mock implements Logger {}

class MockRemoteConfig extends Mock implements RemoteConfig {}

class MockFeaturesConfig extends Mock implements FeaturesConfig {}

class MockOnboardingConfig extends Mock implements OnboardingConfig {}

class MockInitialPersonalizationConfig extends Mock
    implements InitialPersonalizationConfig {}

class MockNavigator extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  group('InitialPersonalizationPage', () {
    late AppBloc appBloc;
    late InitialPersonalizationBloc personalizationBloc;
    late DataRepository<UserContentPreferences>
    userContentPreferencesRepository;
    late DataRepository<UserContext> userContextRepository;
    late DataRepository<Topic> topicsRepository;
    late AnalyticsService analyticsService;
    late Logger logger;
    late RemoteConfig remoteConfig;
    late FeaturesConfig featuresConfig;
    late OnboardingConfig onboardingConfig;
    late InitialPersonalizationConfig personalizationConfig;
    late NavigatorObserver navigatorObserver;

    setUpAll(() {
      registerFallbackValue(FakeRoute());
    });

    setUp(() {
      appBloc = MockAppBloc();
      personalizationBloc = MockInitialPersonalizationBloc();
      userContentPreferencesRepository = MockDataRepository();
      userContextRepository = MockDataRepository();
      topicsRepository = MockDataRepository();
      analyticsService = MockAnalyticsService();
      logger = MockLogger();
      remoteConfig = MockRemoteConfig();
      featuresConfig = MockFeaturesConfig();
      onboardingConfig = MockOnboardingConfig();
      personalizationConfig = MockInitialPersonalizationConfig();
      navigatorObserver = MockNavigator();

      when(() => personalizationConfig.isSkippable).thenReturn(true);
      when(
        () => personalizationConfig.isTopicSelectionEnabled,
      ).thenReturn(true);
      when(
        () => personalizationConfig.isSourceSelectionEnabled,
      ).thenReturn(false);
      when(
        () => personalizationConfig.isCountrySelectionEnabled,
      ).thenReturn(false);

      when(
        () => onboardingConfig.initialPersonalization,
      ).thenReturn(personalizationConfig);
      when(() => featuresConfig.onboarding).thenReturn(onboardingConfig);
      when(() => remoteConfig.features).thenReturn(featuresConfig);

      when(() => appBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.postAuthOnboardingRequired,
          remoteConfig: remoteConfig,
        ),
      );

      when(() => personalizationBloc.state).thenReturn(
        const InitialPersonalizationState(
          status: InitialPersonalizationStatus.success,
        ),
      );
    });

    Widget buildSubject() {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: userContentPreferencesRepository),
          RepositoryProvider.value(value: userContextRepository),
          RepositoryProvider.value(value: topicsRepository),
          RepositoryProvider.value(value: analyticsService),
          RepositoryProvider.value(value: logger),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: appBloc),
            BlocProvider.value(value: personalizationBloc),
          ],
          child: MaterialApp(
            localizationsDelegates: [
              ...AppLocalizations.localizationsDelegates,
              ...UiKitLocalizations.localizationsDelegates,
            ],
            supportedLocales: const [
              ...AppLocalizations.supportedLocales,
              ...UiKitLocalizations.supportedLocales,
            ],
            home: const InitialPersonalizationPage(),
            navigatorObservers: [navigatorObserver],
          ),
        ),
      );
    }

    testWidgets('renders correctly in success state', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(InitialPersonalizationPage), findsOneWidget);
      expect(find.text('Customize Your Feed'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows loading indicator when status is loading', (
      tester,
    ) async {
      when(() => personalizationBloc.state).thenReturn(
        const InitialPersonalizationState(
          status: InitialPersonalizationStatus.loading,
        ),
      );
      await tester.pumpWidget(buildSubject());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows failure widget when status is failure', (tester) async {
      when(() => personalizationBloc.state).thenReturn(
        const InitialPersonalizationState(
          status: InitialPersonalizationStatus.failure,
          error: UnknownException('error'),
        ),
      );
      await tester.pumpWidget(buildSubject());
      expect(find.byType(FailureStateWidget), findsOneWidget);
      await tester.tap(find.text('Retry'));
      verify(
        () => personalizationBloc.add(InitialPersonalizationDataRequested()),
      ).called(1);
    });

    testWidgets(
      'tapping Skip button adds InitialPersonalizationSkipped event',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.tap(find.text('Skip'));
        verify(
          () => personalizationBloc.add(InitialPersonalizationSkipped()),
        ).called(1);
      },
    );

    testWidgets(
      'tapping Finish button adds InitialPersonalizationCompleted event',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.tap(find.text('Finish'));
        verify(
          () => personalizationBloc.add(InitialPersonalizationCompleted()),
        ).called(1);
      },
    );

    testWidgets('renders step cards based on config', (tester) async {
      when(
        () => personalizationConfig.isTopicSelectionEnabled,
      ).thenReturn(true);
      when(
        () => personalizationConfig.isSourceSelectionEnabled,
      ).thenReturn(true);
      when(
        () => personalizationConfig.isCountrySelectionEnabled,
      ).thenReturn(false);

      await tester.pumpWidget(buildSubject());

      expect(find.text('Select Topics'), findsOneWidget);
      expect(find.text('Select Sources'), findsOneWidget);
      expect(find.text('Select Countries'), findsNothing);
    });

    testWidgets('tapping a step card navigates to MultiSelectSearchPage', (
      tester,
    ) async {
      final topic = Topic(
        id: '1',
        name: 'Tech',
        description: '',
        iconUrl: '',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        status: ContentStatus.active,
      );
      when(() => personalizationBloc.state).thenReturn(
        InitialPersonalizationState(
          status: InitialPersonalizationStatus.success,
          selectedTopics: {topic},
        ),
      );

      when(
        () => topicsRepository.readAll(
          filter: any(named: 'filter'),
          pagination: any(named: 'pagination'),
        ),
      ).thenAnswer(
        (_) async => const PaginatedResponse<Topic>(
          items: [],
          cursor: null,
          hasMore: false,
        ),
      );

      await tester.pumpWidget(buildSubject());

      reset(navigatorObserver);

      await tester.tap(find.text('Select Topics'));
      await tester.pumpAndSettle();

      verify(() => navigatorObserver.didPush(any(), any())).called(1);
      expect(find.byType(MultiSelectSearchPage<Topic>), findsOneWidget);

      final searchPage = tester.widget<MultiSelectSearchPage<Topic>>(
        find.byType(MultiSelectSearchPage<Topic>),
      );
      expect(searchPage.initialSelectedItems, {topic});
      expect(searchPage.repository, isNotNull);
    });
  });
}
