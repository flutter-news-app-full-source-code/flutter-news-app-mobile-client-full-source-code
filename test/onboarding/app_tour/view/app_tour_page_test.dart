import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/onboarding/app_tour/bloc/app_tour_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/onboarding/app_tour/view/app_tour_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kv_storage_service/kv_storage_service.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockAppTourBloc extends MockBloc<AppTourEvent, AppTourState>
    implements AppTourBloc {}

class MockKVStorageService extends Mock implements KVStorageService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockLogger extends Mock implements Logger {}

class MockRemoteConfig extends Mock implements RemoteConfig {}

class MockFeaturesConfig extends Mock implements FeaturesConfig {}

class MockOnboardingConfig extends Mock implements OnboardingConfig {}

class MockAppTourConfig extends Mock implements AppTourConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(AnalyticsEvent.appTourStarted);
    registerFallbackValue(const AppTourStartedPayload());
  });

  group('AppTourPage', () {
    late AppBloc appBloc;
    late AppTourBloc appTourBloc;
    late KVStorageService storageService;
    late AnalyticsService analyticsService;
    late Logger logger;
    late RemoteConfig remoteConfig;
    late FeaturesConfig featuresConfig;
    late OnboardingConfig onboardingConfig;
    late AppTourConfig appTourConfig;

    setUp(() {
      appBloc = MockAppBloc();
      appTourBloc = MockAppTourBloc();
      storageService = MockKVStorageService();
      analyticsService = MockAnalyticsService();
      logger = MockLogger();
      remoteConfig = MockRemoteConfig();
      featuresConfig = MockFeaturesConfig();
      onboardingConfig = MockOnboardingConfig();
      appTourConfig = MockAppTourConfig();

      when(() => appTourConfig.isSkippable).thenReturn(true);
      when(() => onboardingConfig.appTour).thenReturn(appTourConfig);
      when(() => featuresConfig.onboarding).thenReturn(onboardingConfig);
      when(() => remoteConfig.features).thenReturn(featuresConfig);
      when(() => appBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.preAuthOnboardingRequired,
          remoteConfig: remoteConfig,
        ),
      );
      when(() => appTourBloc.state).thenReturn(const AppTourState());
      when(
        () => analyticsService.logEvent(any(), payload: any(named: 'payload')),
      ).thenAnswer((_) async {});
    });

    Widget buildSubject() {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: storageService),
          RepositoryProvider.value(value: analyticsService),
          RepositoryProvider.value(value: logger),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: appBloc),
            BlocProvider.value(value: appTourBloc),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppTourView(),
          ),
        ),
      );
    }

    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(AppTourView), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(SmoothPageIndicator), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows Skip button when skippable', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('hides Skip button when not skippable', (tester) async {
      when(() => appTourConfig.isSkippable).thenReturn(false);
      await tester.pumpWidget(buildSubject());
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('tapping Skip button adds AppTourCompleted event', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      verify(() => appTourBloc.add(AppTourCompleted())).called(1);
      verify(
        () => analyticsService.logEvent(
          AnalyticsEvent.appTourSkipped,
          payload: const AppTourSkippedPayload(),
        ),
      ).called(1);
    });

    testWidgets('swiping PageView adds AppTourPageChanged event', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      verify(() => appTourBloc.add(const AppTourPageChanged(1))).called(1);
    });

    testWidgets('button shows "Next" on first page and '
        'tapping it navigates to next page', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('Next'), findsOneWidget);

      final pageView = tester.widget<PageView>(find.byType(PageView));
      final initialPage = pageView.controller!.page;

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      final newPage = pageView.controller!.page;
      expect(newPage, greaterThan(initialPage!));
    });

    testWidgets('button shows "Get Started" on last page and '
        'tapping it adds AppTourCompleted event', (tester) async {
      when(() => appTourBloc.state).thenReturn(
        const AppTourState(currentPage: AppTourState.totalPages - 1),
      );
      await tester.pumpWidget(buildSubject());

      expect(find.text('Get Started'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      verify(() => appTourBloc.add(AppTourCompleted())).called(1);
    });
  });
}
