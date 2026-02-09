import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/headlines_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/widgets/save_filter_dialog.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../helpers/helpers.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockHeadlinesFeedBloc
    extends MockBloc<HeadlinesFeedEvent, HeadlinesFeedState>
    implements HeadlinesFeedBloc {}

class MockContentLimitationService extends Mock
    implements ContentLimitationService {}

class MockTopicsRepository extends Mock implements DataRepository<Topic> {}

class MockSourcesRepository extends Mock implements DataRepository<Source> {}

class MockCountriesRepository extends Mock implements DataRepository<Country> {}

class MockHeadlinesFilterBloc
    extends MockBloc<HeadlinesFilterEvent, HeadlinesFilterState>
    implements HeadlinesFilterBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(ContentAction.bookmarkHeadline);
    registerFallbackValue(
      PushNotificationSubscriptionDeliveryType.breakingOnly,
    );
  });
  group('HeadlinesFilterPage', () {
    late AppBloc appBloc;

    const initialFilter = HeadlineFilterCriteria(
      topics: [],
      sources: [],
      countries: [],
    );
    late HeadlinesFeedBloc headlinesFeedBloc;
    late MockContentLimitationService contentLimitationService;
    late DataRepository<Topic> topicsRepository;
    late DataRepository<Source> sourcesRepository;
    late DataRepository<Country> countriesRepository;
    late MockHeadlinesFilterBloc mockHeadlinesFilterBloc;

    setUp(() {
      appBloc = MockAppBloc();
      when(
        () => appBloc.state,
      ).thenReturn(const AppState(status: AppLifeCycleStatus.authenticated));
      headlinesFeedBloc = MockHeadlinesFeedBloc();
      mockHeadlinesFilterBloc = MockHeadlinesFilterBloc();
      contentLimitationService = MockContentLimitationService();
      topicsRepository = MockTopicsRepository();
      sourcesRepository = MockSourcesRepository();
      countriesRepository = MockCountriesRepository();

      // Stub checkAction for calls without named arguments (e.g., pinFilter)
      when(
        () => contentLimitationService.checkAction(any()),
      ).thenAnswer((_) async => LimitationStatus.allowed);

      // Stub checkAction for calls WITH named arguments (e.g., notifications)
      when(
        () => contentLimitationService.checkAction(
          any(),
          deliveryType: any(named: 'deliveryType'),
        ),
      ).thenAnswer((_) async => LimitationStatus.allowed);

      when(
        () => topicsRepository.readAll(
          filter: any(named: 'filter'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const PaginatedResponse<Topic>(
          items: [],
          cursor: null,
          hasMore: false,
        );
      });
      when(
        () => sourcesRepository.readAll(
          filter: any(named: 'filter'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const PaginatedResponse<Source>(
          items: [],
          cursor: null,
          hasMore: false,
        );
      });
      when(
        () => countriesRepository.readAll(
          filter: any(named: 'filter'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const PaginatedResponse<Country>(
          items: [],
          cursor: null,
          hasMore: false,
        );
      });
    });

    Widget buildWidget({
      SavedHeadlineFilter? filterToEdit,
      HeadlinesFilterBloc? headlinesFilterBloc,
      MockGoRouter? mockGoRouter,
    }) {
      final page = HeadlinesFilterPage(
        initialFilter: initialFilter,
        filterToEdit: filterToEdit,
      );

      final app = MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      );

      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ContentLimitationService>.value(
            value: contentLimitationService,
          ),
          RepositoryProvider<DataRepository<Topic>>.value(
            value: topicsRepository,
          ),
          RepositoryProvider<DataRepository<Source>>.value(
            value: sourcesRepository,
          ),
          RepositoryProvider<DataRepository<Country>>.value(
            value: countriesRepository,
          ),
          RepositoryProvider<Logger>(
            create: (_) => Logger('HeadlinesFilterPageTest'),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
            BlocProvider<HeadlinesFeedBloc>.value(value: headlinesFeedBloc),
            BlocProvider<HeadlinesFilterBloc>.value(
              value: headlinesFilterBloc ?? mockHeadlinesFilterBloc,
            ),
          ],
          child: mockGoRouter != null
              ? MockGoRouterProvider(goRouter: mockGoRouter, child: app)
              : app,
        ),
      );
    }

    testWidgets('renders correctly with filter sections', (tester) async {
      const successState = HeadlinesFilterState(
        status: HeadlinesFilterStatus.success,
      );
      when(() => mockHeadlinesFilterBloc.state).thenReturn(successState);
      whenListen(mockHeadlinesFilterBloc, Stream.fromIterable([successState]));
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Filter Headlines'), findsOneWidget);
      expect(
        find.byKey(const Key(Routes.feedFilterTopicsName)),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key(Routes.feedFilterSourcesName)),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key(Routes.feedFilterEventCountriesName)),
        findsOneWidget,
      );
    });

    testWidgets('shows loading state correctly', (tester) async {
      const loadingState = HeadlinesFilterState(
        status: HeadlinesFilterStatus.loading,
      );
      when(() => mockHeadlinesFilterBloc.state).thenReturn(loadingState);
      whenListen(mockHeadlinesFilterBloc, Stream.fromIterable([loadingState]));
      await tester.pumpWidget(buildWidget());
      expect(find.byType(LoadingStateWidget), findsOneWidget);
    });

    testWidgets('tapping Topic navigates to TopicFilterPage', (tester) async {
      final mockGoRouter = MockGoRouter();
      final headlinesFilterBloc = MockHeadlinesFilterBloc();
      const successState = HeadlinesFilterState(
        status: HeadlinesFilterStatus.success,
      );
      when(() => headlinesFilterBloc.state).thenReturn(successState);
      whenListen(
        headlinesFilterBloc,
        Stream.fromIterable([successState]),
        initialState: successState,
      );

      when(
        () => mockGoRouter.pushNamed(any(), extra: any(named: 'extra')),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        buildWidget(
          headlinesFilterBloc: headlinesFilterBloc,
          mockGoRouter: mockGoRouter,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key(Routes.feedFilterTopicsName)));
      await tester.pumpAndSettle();

      verify(
        () => mockGoRouter.pushNamed(
          Routes.feedFilterTopicsName,
          extra: any(named: 'extra'),
        ),
      ).called(1);
    });

    testWidgets('tapping Sources navigates to SourceFilterPage', (
      tester,
    ) async {
      final mockGoRouter = MockGoRouter();
      final headlinesFilterBloc = MockHeadlinesFilterBloc();
      const successState = HeadlinesFilterState(
        status: HeadlinesFilterStatus.success,
      );
      when(() => headlinesFilterBloc.state).thenReturn(successState);
      whenListen(
        headlinesFilterBloc,
        Stream.fromIterable([successState]),
        initialState: successState,
      );

      when(
        () => mockGoRouter.pushNamed(any(), extra: any(named: 'extra')),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        buildWidget(
          headlinesFilterBloc: headlinesFilterBloc,
          mockGoRouter: mockGoRouter,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key(Routes.feedFilterSourcesName)));
      await tester.pumpAndSettle();

      verify(
        () => mockGoRouter.pushNamed(
          Routes.feedFilterSourcesName,
          extra: any(named: 'extra'),
        ),
      ).called(1);
    });

    testWidgets('tapping Countries navigates to CountryFilterPage', (
      tester,
    ) async {
      final mockGoRouter = MockGoRouter();
      final headlinesFilterBloc = MockHeadlinesFilterBloc();
      const successState = HeadlinesFilterState(
        status: HeadlinesFilterStatus.success,
      );
      when(() => headlinesFilterBloc.state).thenReturn(successState);
      whenListen(
        headlinesFilterBloc,
        Stream.fromIterable([successState]),
        initialState: successState,
      );

      when(
        () => mockGoRouter.pushNamed(any(), extra: any(named: 'extra')),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        buildWidget(
          headlinesFilterBloc: headlinesFilterBloc,
          mockGoRouter: mockGoRouter,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key(Routes.feedFilterEventCountriesName)),
      );
      await tester.pumpAndSettle();

      verify(
        () => mockGoRouter.pushNamed(
          Routes.feedFilterEventCountriesName,
          extra: any(named: 'extra'),
        ),
      ).called(1);
    });

    testWidgets(
      'tapping apply button shows dialog and "Apply Only" pops page',
      (tester) async {
        final mockGoRouter = MockGoRouter();
        final headlinesFilterBloc = MockHeadlinesFilterBloc();
        final state = HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          selectedTopics: {
            Topic(
              id: 't1',
              name: 'Test',
              description: '',
              iconUrl: '',
              createdAt: DateTime(2024),
              updatedAt: DateTime(2024),
              status: ContentStatus.active,
            ),
          },
        );
        when(() => headlinesFilterBloc.state).thenReturn(state);
        whenListen(headlinesFilterBloc, Stream.fromIterable([state]));

        // Stub pop
        when(mockGoRouter.pop).thenAnswer((_) {});

        await tester.pumpWidget(
          buildWidget(
            headlinesFilterBloc: headlinesFilterBloc,
            mockGoRouter: mockGoRouter,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.byKey(const Key('apply_only_button')));
        await tester.pumpAndSettle();

        verify(mockGoRouter.pop).called(3);
      },
    );

    testWidgets(
      'tapping apply button shows dialog and "Apply and Save" shows SaveFilterDialog',
      (tester) async {
        final mockGoRouter = MockGoRouter();
        final headlinesFilterBloc = MockHeadlinesFilterBloc();
        final state = HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          selectedTopics: {
            Topic(
              id: 't1',
              name: 'Test',
              description: '',
              iconUrl: '',
              createdAt: DateTime(2024),
              updatedAt: DateTime(2024),
              status: ContentStatus.active,
            ),
          },
        );
        when(() => headlinesFilterBloc.state).thenReturn(state);
        whenListen(headlinesFilterBloc, Stream.fromIterable([state]));

        // Stub pop for the dialog
        when(mockGoRouter.pop).thenAnswer((_) {});

        await tester.pumpWidget(
          buildWidget(
            headlinesFilterBloc: headlinesFilterBloc,
            mockGoRouter: mockGoRouter,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.byKey(const Key('apply_and_save_button')));
        await tester.pumpAndSettle();

        expect(find.byType(SaveFilterDialog), findsOneWidget);
      },
    );
  });
}
