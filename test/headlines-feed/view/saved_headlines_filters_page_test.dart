import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart'
    as app_bloc;
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/saved_headlines_filters_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../helpers/helpers.dart';

class MockAppBloc extends MockBloc<app_bloc.AppEvent, app_bloc.AppState>
    implements app_bloc.AppBloc {}

class MockHeadlinesFeedBloc
    extends MockBloc<HeadlinesFeedEvent, HeadlinesFeedState>
    implements HeadlinesFeedBloc {}

class FakeAppEvent extends Fake implements app_bloc.AppEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAppEvent());
  });

  group('SavedHeadlinesFiltersPage', () {
    late MockAppBloc appBloc;
    late MockHeadlinesFeedBloc headlinesFeedBloc;
    late StreamController<app_bloc.AppState> appStateController;

    const filter1 = SavedHeadlineFilter(
      id: '1',
      userId: 'user1',
      name: 'Filter 1',
      isPinned: true,
      deliveryTypes: {},
      criteria: HeadlineFilterCriteria(topics: [], sources: [], countries: []),
    );
    const filter2 = SavedHeadlineFilter(
      id: '2',
      userId: 'user1',
      name: 'Filter 2',
      isPinned: false,
      deliveryTypes: {},
      criteria: HeadlineFilterCriteria(topics: [], sources: [], countries: []),
    );

    setUp(() {
      appBloc = MockAppBloc();
      headlinesFeedBloc = MockHeadlinesFeedBloc();
      appStateController = StreamController<app_bloc.AppState>.broadcast();

      when(() => appBloc.stream).thenAnswer((_) => appStateController.stream);
      when(() => appBloc.state).thenReturn(
        const app_bloc.AppState(status: AppLifeCycleStatus.authenticated),
      );
    });

    tearDown(() {
      appStateController.close();
    });

    Widget buildWidget() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<app_bloc.AppBloc>(create: (context) => appBloc),
            BlocProvider<HeadlinesFeedBloc>(
              create: (context) => headlinesFeedBloc,
            ),
          ],
          child: const SavedHeadlinesFiltersPage(),
        ),
      );
    }

    testWidgets('renders correctly with a list of filters', (tester) async {
      const userContentPreferences = UserContentPreferences(
        id: 'user1',
        followedCountries: [],
        followedSources: [],
        followedTopics: [],
        savedHeadlines: [],
        savedHeadlineFilters: [filter1, filter2],
        savedSourceFilters: [],
      );
      when(() => appBloc.state).thenReturn(
        const app_bloc.AppState(
          status: AppLifeCycleStatus.authenticated,
          userContentPreferences: userContentPreferences,
        ),
      );
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      expect(find.text('Saved Filters'), findsOneWidget);
      expect(find.text('Filter 1'), findsOneWidget);
      expect(find.text('Filter 2'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget); // Floating action button
    });

    testWidgets('shows loading state', (tester) async {
      when(() => appBloc.state).thenReturn(
        const app_bloc.AppState(
          status: AppLifeCycleStatus.authenticated,
          userContentPreferences: null,
        ),
      );
      await tester.pumpWidget(buildWidget());
      // The bloc starts in `initial` state, which shows the LoadingStateWidget.
      expect(find.byType(LoadingStateWidget), findsOneWidget);
    });

    testWidgets('shows empty state when no filters are available', (
      tester,
    ) async {
      const userContentPreferences = UserContentPreferences(
        id: 'user1',
        followedCountries: [],
        followedSources: [],
        followedTopics: [],
        savedHeadlines: [],
        savedHeadlineFilters: [],
        savedSourceFilters: [],
      );
      when(() => appBloc.state).thenReturn(
        const app_bloc.AppState(
          status: AppLifeCycleStatus.authenticated,
          userContentPreferences: userContentPreferences,
        ),
      );
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(InitialStateWidget), findsOneWidget);
      expect(find.text('No Saved Filters Yet'), findsOneWidget);
    });

    testWidgets('tapping a filter applies it and pops the page', (
      tester,
    ) async {
      final mockGoRouter = MockGoRouter();
      when(() => appBloc.state).thenReturn(
        const app_bloc.AppState(
          status: AppLifeCycleStatus.authenticated,
          userContentPreferences: UserContentPreferences(
            id: 'user1',
            followedCountries: [],
            followedSources: [],
            followedTopics: [],
            savedHeadlines: [],
            savedHeadlineFilters: [filter1, filter2],
            savedSourceFilters: [],
          ),
        ),
      );
      when(
        () => mockGoRouter.pushNamed(
          Routes.feedFilterName,
          extra: any(named: 'extra'),
        ),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        MockGoRouterProvider(goRouter: mockGoRouter, child: buildWidget()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Filter 1'));
      await tester.pumpAndSettle();

      verify(
        () => headlinesFeedBloc.add(
          SavedFilterSelected(
            filter: filter1,
            adThemeStyle: AdThemeStyle.fromTheme(
              Theme.of(tester.element(find.byType(SavedHeadlinesFiltersPage))),
            ),
          ),
        ),
      ).called(1);
      verify(mockGoRouter.pop).called(1);
    });

    testWidgets('tapping floating action button navigates to filter creation', (
      tester,
    ) async {
      final mockGoRouter = MockGoRouter();
      when(() => appBloc.state).thenReturn(
        const app_bloc.AppState(
          status: AppLifeCycleStatus.authenticated,
          userContentPreferences: UserContentPreferences(
            id: 'user1',
            followedCountries: [],
            followedSources: [],
            followedTopics: [],
            savedHeadlines: [],
            savedHeadlineFilters: [],
            savedSourceFilters: [],
          ),
        ),
      );
      when(
        () => mockGoRouter.pushNamed(
          Routes.feedFilterName,
          extra: any(named: 'extra'),
        ),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        MockGoRouterProvider(goRouter: mockGoRouter, child: buildWidget()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      verify(
        () => mockGoRouter.pushNamed(
          Routes.feedFilterName,
          extra: {
            'initialFilter': const HeadlineFilterCriteria(
              topics: [],
              sources: [],
              countries: [],
            ),
            'filterToEdit': null,
          },
        ),
      ).called(1);
    });

    testWidgets('tapping edit option navigates to filter edit page', (
      tester,
    ) async {
      final mockGoRouter = MockGoRouter();
      when(() => appBloc.state).thenReturn(
        const app_bloc.AppState(
          status: AppLifeCycleStatus.authenticated,
          userContentPreferences: UserContentPreferences(
            id: 'user1',
            followedCountries: [],
            followedSources: [],
            followedTopics: [],
            savedHeadlines: [],
            savedHeadlineFilters: [filter1, filter2],
            savedSourceFilters: [],
          ),
        ),
      );
      when(
        () => mockGoRouter.pushNamed(
          Routes.feedFilterName,
          extra: any(named: 'extra'),
        ),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        MockGoRouterProvider(goRouter: mockGoRouter, child: buildWidget()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      verify(
        () => mockGoRouter.pushNamed(
          Routes.feedFilterName,
          extra: {'initialFilter': filter1.criteria, 'filterToEdit': filter1},
        ),
      ).called(1);
    });

    testWidgets('tapping delete option shows confirmation dialog and deletes', (
      tester,
    ) async {
      when(() => appBloc.state).thenReturn(
        const app_bloc.AppState(
          status: AppLifeCycleStatus.authenticated,
          userContentPreferences: UserContentPreferences(
            id: 'user1',
            followedCountries: [],
            followedSources: [],
            followedTopics: [],
            savedHeadlines: [],
            savedHeadlineFilters: [filter1, filter2],
            savedSourceFilters: [],
          ),
        ),
      );
      when(() => appBloc.add(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Delete')); // Confirm delete
      await tester.pumpAndSettle();

      verify(
        () => appBloc.add(
          const app_bloc.SavedHeadlineFilterDeleted(filterId: '1'),
        ),
      ).called(1);
    });
  });
}
