import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/source_list_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class MockHeadlinesFilterBloc
    extends MockBloc<HeadlinesFilterEvent, HeadlinesFilterState>
    implements HeadlinesFilterBloc {}

void main() {
  group('SourceListFilterPage', () {
    late HeadlinesFilterBloc headlinesFilterBloc;

    final country1 = Country(
      id: 'c1',
      isoCode: 'US',
      name: 'USA',
      flagUrl: '',
      createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      status: ContentStatus.active,
    );

    setUp(() {
      headlinesFilterBloc = MockHeadlinesFilterBloc();
      when(() => headlinesFilterBloc.state).thenReturn(
        HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          allHeadquarterCountries: [country1],
          allSourceTypes: const [SourceType.blog],
          selectedSourceHeadquarterCountries: const {},
          selectedSourceTypes: const {},
        ),
      );
    });

    Widget buildWidget() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SourceListFilterPage(filterBloc: headlinesFilterBloc),
      );
    }

    testWidgets('renders correctly with filter options', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Filter Sources'), findsOneWidget);
      expect(find.text('Source Headquarter'), findsOneWidget);
      expect(find.text('Types'), findsOneWidget);
      expect(find.text('All'), findsNWidgets(2));
    });

    testWidgets('tapping country filter navigates and updates on return', (
      tester,
    ) async {
      final mockGoRouter = MockGoRouter();
      when(
        () => mockGoRouter.pushNamed<Set<dynamic>>(
          Routes.multiSelectSearchName,
          extra: any<Map<String, dynamic>>(named: 'extra'),
        ),
      ).thenAnswer((_) async => {country1} as Set<dynamic>);

      await tester.pumpWidget(
        MockGoRouterProvider(goRouter: mockGoRouter, child: buildWidget()),
      );

      await tester.tap(find.text('Source Headquarter'));
      await tester.pumpAndSettle();

      verify(
        () => headlinesFilterBloc.add(
          FilterSourceCriteriaChanged(selectedCountries: {country1}),
        ),
      ).called(1);
    });

    testWidgets('tapping type filter navigates to source type filter page', (
      tester,
    ) async {
      final mockGoRouter = MockGoRouter();
      when(
        () => mockGoRouter.pushNamed(any(), extra: any(named: 'extra')),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        MockGoRouterProvider(goRouter: mockGoRouter, child: buildWidget()),
      );

      await tester.tap(find.text('Types'));
      await tester.pumpAndSettle();

      verify(
        () => mockGoRouter.pushNamed(
          Routes.sourceTypeFilterName,
          extra: headlinesFilterBloc,
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
          child: SourceListFilterPage(filterBloc: headlinesFilterBloc),
        ),
      );

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      verify(mockNavigator.pop).called(1);
    });
  });
}
