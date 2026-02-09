import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/source_type_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../helpers/helpers.dart';

class MockHeadlinesFilterBloc
    extends MockBloc<HeadlinesFilterEvent, HeadlinesFilterState>
    implements HeadlinesFilterBloc {}

void main() {
  group('SourceTypeFilterPage', () {
    late HeadlinesFilterBloc headlinesFilterBloc;

    setUpAll(() {
      registerFallbackValue(const FilterDataLoaded());
    });

    setUp(() {
      headlinesFilterBloc = MockHeadlinesFilterBloc();
      when(() => headlinesFilterBloc.state).thenReturn(
        const HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          allSourceTypes: [SourceType.blog, SourceType.newsAgency],
          selectedSourceTypes: {},
        ),
      );
      when(
        () => headlinesFilterBloc.stream,
      ).thenAnswer((_) => const Stream.empty());
    });

    Widget buildWidget() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SourceTypeFilterPage(filterBloc: headlinesFilterBloc),
      );
    }

    testWidgets('renders correctly with source types', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Types'), findsOneWidget);
      expect(find.text('Blog'), findsOneWidget);
      expect(find.text('News Agency'), findsOneWidget);
    });

    testWidgets('shows empty state when no source types are available', (
      tester,
    ) async {
      when(() => headlinesFilterBloc.state).thenReturn(
        const HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          allSourceTypes: [],
        ),
      );

      await tester.pumpWidget(buildWidget());

      expect(find.byType(InitialStateWidget), findsOneWidget);
    });

    testWidgets('tapping a checkbox dispatches correct event', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.text('Blog'));
      await tester.pump();

      verify(
        () => headlinesFilterBloc.add(
          any(that: isA<FilterSourceCriteriaChanged>()),
        ),
      ).called(1);

      // Simulate the state update
      when(() => headlinesFilterBloc.state).thenReturn(
        const HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          allSourceTypes: [SourceType.blog, SourceType.newsAgency],
          selectedSourceTypes: {SourceType.blog},
        ),
      );
      await tester.pumpWidget(buildWidget());

      // Tap again to unselect
      await tester.tap(find.text('Blog'));
      await tester.pump();

      verify(
        () => headlinesFilterBloc.add(
          any(that: isA<FilterSourceCriteriaChanged>()),
        ),
      ).called(1);
    });

    testWidgets('tapping apply button pops the page', (tester) async {
      final mockNavigator = MockGoRouter();
      when(() => mockNavigator.pop<void>()).thenAnswer((_) async {
        return;
      });

      await tester.pumpWidget(
        MockGoRouterProvider(
          goRouter: mockNavigator,
          child: SourceTypeFilterPage(filterBloc: headlinesFilterBloc),
        ),
      );

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      verify(mockNavigator.pop).called(1);
    });
  });
}
