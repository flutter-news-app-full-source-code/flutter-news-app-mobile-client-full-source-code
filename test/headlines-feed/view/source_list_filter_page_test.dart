import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/view/source_list_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class MockHeadlinesFilterBloc
    extends MockBloc<HeadlinesFilterEvent, HeadlinesFilterState>
    implements HeadlinesFilterBloc {}

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Mock implements HttpClient {
  _MockHttpClient() {
    registerFallbackValue(Uri());
    when(() => getUrl(any())).thenAnswer((_) async => _MockHttpClientRequest());
  }
}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {
  _MockHttpClientRequest() {
    when(() => headers).thenReturn(_MockHttpHeaders());
    when(close).thenAnswer((_) async => _MockHttpClientResponse());
  }
}

class _MockHttpHeaders extends Mock implements HttpHeaders {}

class _MockHttpClientResponse extends Mock implements HttpClientResponse {
  _MockHttpClientResponse() {
    when(() => statusCode).thenReturn(200);
    when(() => contentLength).thenReturn(kTransparentImage.length);
    when(
      () => compressionState,
    ).thenReturn(HttpClientResponseCompressionState.notCompressed);
    when(
      () => listen(
        any(),
        onError: any(named: 'onError'),
        onDone: any(named: 'onDone'),
        cancelOnError: any(named: 'cancelOnError'),
      ),
    ).thenAnswer((invocation) {
      final onData =
          invocation.positionalArguments[0] as void Function(List<int>);
      final onDone = invocation.namedArguments['onDone'] as void Function()?;
      onData(kTransparentImage);
      onDone?.call();
      return Stream<List<int>>.fromIterable([kTransparentImage]).listen(null);
    });
  }
}

const List<int> kTransparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  group('SourceListFilterPage', () {
    late HeadlinesFilterBloc headlinesFilterBloc;

    final country1 = Country(
      id: 'c1',
      isoCode: 'US',
      name: 'USA',
      flagUrl: 'https://example.com/flag.png',
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
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.text('Source Headquarter'));
      await tester.pumpAndSettle();

      // Select the country
      await tester.tap(find.text('USA'));
      await tester.pump();

      // Tap Save to pop with result
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () => headlinesFilterBloc.add(
          FilterSourceCriteriaChanged(selectedCountries: {country1}),
        ),
      ).called(1);
    });

    testWidgets('tapping type filter shows source type dialog', (tester) async {
      final mockGoRouter = MockGoRouter();
      when(
        () => mockGoRouter.pushNamed(any(), extra: any(named: 'extra')),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        MockGoRouterProvider(goRouter: mockGoRouter, child: buildWidget()),
      );

      await tester.tap(find.text('Types'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
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
