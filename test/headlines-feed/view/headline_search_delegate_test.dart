import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_search_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/headline_search_delegate.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

class MockHeadlineSearchBloc
    extends MockBloc<HeadlineSearchEvent, HeadlineSearchState>
    implements HeadlineSearchBloc {}

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockHeadlinesFeedBloc
    extends MockBloc<HeadlinesFeedEvent, HeadlinesFeedState>
    implements HeadlinesFeedBloc {}

class MockInterstitialAdManager extends Mock implements InterstitialAdManager {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('HeadlineSearchDelegate', () {
    late HeadlineSearchBloc headlineSearchBloc;
    late AppBloc appBloc;
    late HeadlinesFeedBloc headlinesFeedBloc;
    late InterstitialAdManager interstitialAdManager;
    late AnalyticsService analyticsService;

    setUpAll(() {
      registerFallbackValue(const HeadlineSearchQueryChanged(''));
    });

    setUp(() {
      headlineSearchBloc = MockHeadlineSearchBloc();
      appBloc = MockAppBloc();
      headlinesFeedBloc = MockHeadlinesFeedBloc();
      interstitialAdManager = MockInterstitialAdManager();
      analyticsService = MockAnalyticsService();

      when(
        () => headlineSearchBloc.state,
      ).thenReturn(const HeadlineSearchState());
      when(() => headlineSearchBloc.stream).thenAnswer(
        (_) => Stream.value(const HeadlineSearchState()).asBroadcastStream(),
      );

      when(
        () => appBloc.state,
      ).thenReturn(const AppState(status: AppLifeCycleStatus.authenticated));
      when(() => appBloc.stream).thenAnswer((_) => Stream.value(appBloc.state));

      when(
        () => headlinesFeedBloc.state,
      ).thenReturn(const HeadlinesFeedState(engagementsMap: {}));
      when(
        () => headlinesFeedBloc.stream,
      ).thenAnswer((_) => Stream.value(headlinesFeedBloc.state));
    });

    Widget buildWidget() {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: interstitialAdManager),
          RepositoryProvider.value(value: analyticsService),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: appBloc),
            BlocProvider.value(value: headlinesFeedBloc),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              UiKitLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: FloatingActionButton(
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: HeadlineSearchDelegate(
                        headlineSearchBloc: headlineSearchBloc,
                      ),
                    );
                  },
                  child: const Icon(Icons.search),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows initial state by default', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('Search for Headlines'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      when(() => headlineSearchBloc.state).thenReturn(
        const HeadlineSearchState(status: HeadlineSearchStatus.loading),
      );
      when(() => headlineSearchBloc.stream).thenAnswer(
        (_) => Stream<HeadlineSearchState>.value(
          const HeadlineSearchState(status: HeadlineSearchStatus.loading),
        ).asBroadcastStream(),
      );

      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump(); // Start navigation
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Allow frame to build

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows failure state and retries', (tester) async {
      when(() => headlineSearchBloc.state).thenReturn(
        const HeadlineSearchState(
          status: HeadlineSearchStatus.failure,
          error: HttpException('oops'),
        ),
      );
      when(() => headlineSearchBloc.stream).thenAnswer(
        (_) => Stream<HeadlineSearchState>.value(
          const HeadlineSearchState(
            status: HeadlineSearchStatus.failure,
            error: HttpException('oops'),
          ),
        ),
      );

      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.byType(FailureStateWidget), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      clearInteractions(headlineSearchBloc);

      await tester.tap(find.text('Retry'));
      verify(
        () => headlineSearchBloc.add(
          any(that: isA<HeadlineSearchQueryChanged>()),
        ),
      ).called(1);
    });

    testWidgets('shows empty results state', (tester) async {
      when(() => headlineSearchBloc.state).thenReturn(
        const HeadlineSearchState(
          status: HeadlineSearchStatus.success,
          headlines: [],
        ),
      );
      when(() => headlineSearchBloc.stream).thenAnswer(
        (_) => Stream<HeadlineSearchState>.value(
          const HeadlineSearchState(
            status: HeadlineSearchStatus.success,
            headlines: [],
          ),
        ),
      );

      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('No headlines found.'), findsOneWidget);
    });

    testWidgets('shows results when success', (tester) async {
      final headline = Headline(
        id: '1',
        title: 'Test Headline',
        url: 'url',
        imageUrl: 'url',
        source: Source(
          id: 's1',
          name: 'Source',
          description: '',
          url: '',
          logoUrl: '',
          sourceType: SourceType.newsAgency,
          language: Language(
            id: 'l1',
            code: 'en',
            name: 'English',
            nativeName: 'English',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            status: ContentStatus.active,
          ),
          headquarters: Country(
            id: 'c1',
            isoCode: 'US',
            name: 'USA',
            flagUrl: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            status: ContentStatus.active,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ContentStatus.active,
        ),
        eventCountry: Country(
          id: 'c1',
          isoCode: 'US',
          name: 'USA',
          flagUrl: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ContentStatus.active,
        ),
        topic: Topic(
          id: 't1',
          name: 'Topic',
          description: '',
          iconUrl: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: ContentStatus.active,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ContentStatus.active,
        isBreaking: false,
      );

      when(() => headlineSearchBloc.state).thenReturn(
        HeadlineSearchState(
          status: HeadlineSearchStatus.success,
          headlines: [headline],
        ),
      );
      when(() => headlineSearchBloc.stream).thenAnswer(
        (_) => Stream<HeadlineSearchState>.value(
          HeadlineSearchState(
            status: HeadlineSearchStatus.success,
            headlines: [headline],
          ),
        ),
      );

      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('Test Headline'), findsOneWidget);
    });

    testWidgets('dispatches query changed event on input', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      verify(
        () => headlineSearchBloc.add(const HeadlineSearchQueryChanged('test')),
      ).called(1);
    });
  });
}
