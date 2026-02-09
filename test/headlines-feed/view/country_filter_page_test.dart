import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/country_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../helpers/helpers.dart';

class MockHeadlinesFilterBloc
    extends MockBloc<HeadlinesFilterEvent, HeadlinesFilterState>
    implements HeadlinesFilterBloc {}

void main() {
  group('CountryFilterPage', () {
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
    final country2 = Country(
      id: 'c2',
      isoCode: 'GB',
      name: 'United Kingdom',
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
          allCountries: [country1, country2],
          selectedCountries: const {},
        ),
      );
    });

    Widget buildWidget() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CountryFilterPage(
          title: 'Test Countries',
          filterBloc: headlinesFilterBloc,
        ),
      );
    }

    testWidgets('renders correctly with countries list', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Test Countries'), findsOneWidget);
      expect(find.text('USA'), findsOneWidget);
      expect(find.text('United Kingdom'), findsOneWidget);
    });

    testWidgets('tapping a country toggles selection', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.text('USA'));
      await tester.pump();

      verify(
        () => headlinesFilterBloc.add(
          FilterCountryToggled(country: country1, isSelected: true),
        ),
      ).called(1);
    });

    testWidgets('shows empty state when no countries are available', (
      tester,
    ) async {
      when(() => headlinesFilterBloc.state).thenReturn(
        const HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          allCountries: [],
        ),
      );

      await tester.pumpWidget(buildWidget());

      expect(find.byType(InitialStateWidget), findsOneWidget);
    });

    testWidgets('tapping apply button pops the page', (tester) async {
      final mockNavigator = MockGoRouter();
      when(() => mockNavigator.pop<void>()).thenAnswer((_) async {
        return;
      });

      await tester.pumpWidget(
        MockGoRouterProvider(
          goRouter: mockNavigator,
          child: CountryFilterPage(
            title: 'Test Countries',
            filterBloc: headlinesFilterBloc,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      verify(mockNavigator.pop).called(1);
    });
  });
}
