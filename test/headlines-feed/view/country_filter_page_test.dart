import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client/headlines_feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client/headlines_feed/view/country_filter_page.dart';
import 'package:flutter_news_app_mobile_client/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class MockHeadlinesFilterBloc
    extends MockBloc<HeadlinesFilterEvent, HeadlinesFilterState>
    implements HeadlinesFilterBloc {}

void main() {
  group('CountryFilterPage', () {
    late HeadlinesFilterBloc headlinesFilterBloc;

    const country1 = Country(
      id: 'c1',
      isoCode: 'US',
      name: {SupportedLanguage.en: 'USA'},
      flagUrl: '',
    );
    const country2 = Country(
      id: 'c2',
      isoCode: 'GB',
      name: {SupportedLanguage.en: 'United Kingdom'},
      flagUrl: '',
    );

    setUp(() {
      headlinesFilterBloc = MockHeadlinesFilterBloc();
      when(() => headlinesFilterBloc.state).thenReturn(
        const HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          allCountries: [country1, country2],
          selectedCountries: {},
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
          const FilterCountryToggled(country: country1, isSelected: true),
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
        MockGoRouterProvider(goRouter: mockNavigator, child: buildWidget()),
      );

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      verify(mockNavigator.pop).called(1);
    });
  });
}
