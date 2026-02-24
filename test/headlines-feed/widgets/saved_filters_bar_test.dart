import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/widgets/saved_filters_bar.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class MockHeadlinesFeedBloc
    extends MockBloc<HeadlinesFeedEvent, HeadlinesFeedState>
    implements HeadlinesFeedBloc {}

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

void main() {
  group('SavedFiltersBar', () {
    late HeadlinesFeedBloc headlinesFeedBloc;
    late AppBloc appBloc;

    const filter1 = SavedHeadlineFilter(
      id: 'f1',
      userId: 'u1',
      name: 'Pinned Filter',
      isPinned: true,
      deliveryTypes: {},
      criteria: HeadlineFilterCriteria(topics: [], sources: [], countries: []),
    );

    final userContentPreferences = UserContentPreferences(
      id: 'u1',
      followedTopics: [
        Topic(
          id: 't1',
          name: 'Tech',
          description: '',
          iconUrl: '',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
          status: ContentStatus.active,
        ),
      ],
      followedSources: const [],
      followedCountries: const [],
      savedHeadlines: const [],
      savedHeadlineFilters: const [filter1],
    );

    setUpAll(() {
      const dummyAdThemeStyle = AdThemeStyle(
        mainBackgroundColor: Colors.transparent,
        cornerRadius: 0,
        callToActionTextColor: Colors.transparent,
        callToActionBackgroundColor: Colors.transparent,
        callToActionTextSize: 0,
        primaryTextColor: Colors.transparent,
        primaryBackgroundColor: Colors.transparent,
        primaryTextSize: 0,
        secondaryTextColor: Colors.transparent,
        secondaryBackgroundColor: Colors.transparent,
        secondaryTextSize: 0,
        tertiaryTextColor: Colors.transparent,
        tertiaryBackgroundColor: Colors.transparent,
        tertiaryTextSize: 0,
      );
      registerFallbackValue(
        const AllFilterSelected(adThemeStyle: dummyAdThemeStyle),
      );
      registerFallbackValue(
        const FollowedFilterSelected(adThemeStyle: dummyAdThemeStyle),
      );
      registerFallbackValue(
        const SavedFilterSelected(
          filter: filter1,
          adThemeStyle: dummyAdThemeStyle,
        ),
      );
    });

    setUp(() {
      headlinesFeedBloc = MockHeadlinesFeedBloc();
      appBloc = MockAppBloc();

      when(() => headlinesFeedBloc.state).thenReturn(
        const HeadlinesFeedState(
          savedHeadlineFilters: [filter1],
          activeFilterId: 'all',
        ),
      );
      when(
        () => headlinesFeedBloc.stream,
      ).thenAnswer((_) => Stream.value(headlinesFeedBloc.state));

      when(() => appBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.authenticated,
          userContentPreferences: userContentPreferences,
        ),
      );
      when(() => appBloc.stream).thenAnswer((_) => Stream.value(appBloc.state));
    });

    Widget buildWidget() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: headlinesFeedBloc),
              BlocProvider.value(value: appBloc),
            ],
            child: const SavedFiltersBar(),
          ),
        ),
      );
    }

    testWidgets('renders correctly with all chips', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Followed'), findsOneWidget);
      expect(find.text('Pinned Filter'), findsOneWidget);
      expect(find.text('Custom'), findsNothing);
    });

    testWidgets('does not render Followed chip if user follows nothing', (
      tester,
    ) async {
      when(() => appBloc.state).thenReturn(
        const AppState(
          status: AppLifeCycleStatus.authenticated,
          userContentPreferences: UserContentPreferences(
            id: 'u1',
            followedTopics: [],
            followedSources: [],
            followedCountries: [],
            savedHeadlines: [],
            savedHeadlineFilters: [],
          ),
        ),
      );
      when(() => appBloc.stream).thenAnswer((_) => Stream.value(appBloc.state));

      await tester.pumpWidget(buildWidget());

      expect(find.text('Followed'), findsNothing);
    });

    testWidgets('renders Custom chip when activeFilterId is custom', (
      tester,
    ) async {
      when(() => headlinesFeedBloc.state).thenReturn(
        const HeadlinesFeedState(
          savedHeadlineFilters: [filter1],
          activeFilterId: 'custom',
        ),
      );
      when(
        () => headlinesFeedBloc.stream,
      ).thenAnswer((_) => Stream.value(headlinesFeedBloc.state));

      await tester.pumpWidget(buildWidget());

      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('tapping a chip dispatches correct event', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.text('All'));
      verify(() => headlinesFeedBloc.add(any<AllFilterSelected>())).called(1);

      await tester.tap(find.text('Followed'));
      verify(
        () => headlinesFeedBloc.add(any<FollowedFilterSelected>()),
      ).called(1);

      await tester.tap(find.text('Pinned Filter'));
      verify(
        () => headlinesFeedBloc.add(
          any<SavedFilterSelected>(that: isA<SavedFilterSelected>()),
        ),
      ).called(1);
    });

    testWidgets('tapping filter icon navigates to saved filters page', (
      tester,
    ) async {
      final mockGoRouter = MockGoRouter();

      when(() => mockGoRouter.pushNamed(any())).thenAnswer((_) async => null);

      await tester.pumpWidget(
        MockGoRouterProvider(goRouter: mockGoRouter, child: buildWidget()),
      );

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      verify(
        () => mockGoRouter.pushNamed(Routes.savedHeadlineFiltersName),
      ).called(1);
    });
  });
}
