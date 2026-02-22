import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/view/source_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart' as ui_kit;
import 'package:ui_kit/ui_kit.dart';

import '../../helpers/helpers.dart';

class MockHeadlinesFilterBloc
    extends MockBloc<HeadlinesFilterEvent, HeadlinesFilterState>
    implements HeadlinesFilterBloc {}

void main() {
  group('SourceFilterPage', () {
    late HeadlinesFilterBloc headlinesFilterBloc;

    final source1 = Source(
      id: 's1',
      name: 'Source One',
      description: '',
      url: '',
      logoUrl: 'http://logo.url/1',
      sourceType: SourceType.blog,
      language: Language(
        id: 'l1',
        code: 'en',
        name: 'English',
        nativeName: 'English',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        status: ContentStatus.active,
      ),
      headquarters: Country(
        id: 'c1',
        isoCode: 'US',
        name: 'USA',
        flagUrl: '',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        status: ContentStatus.active,
      ),
      createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      status: ContentStatus.active,
    );

    setUp(() {
      headlinesFilterBloc = MockHeadlinesFilterBloc();
    });

    Widget buildWidget() {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ui_kit.UiKitLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: SourceFilterPage(filterBloc: headlinesFilterBloc),
      );
    }

    testWidgets('renders correctly and shows sources', (tester) async {
      when(() => headlinesFilterBloc.state).thenReturn(
        HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          allSources: [source1],
        ),
      );
      await tester.pumpWidget(buildWidget());

      expect(find.text('Source'), findsOneWidget);
      expect(find.text('Source One'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('shows loading state correctly', (tester) async {
      when(() => headlinesFilterBloc.state).thenReturn(
        const HeadlinesFilterState(status: HeadlinesFilterStatus.loading),
      );

      await tester.pumpWidget(buildWidget());

      expect(find.byType(LoadingStateWidget), findsOneWidget);
    });

    testWidgets('shows failure state correctly', (tester) async {
      when(() => headlinesFilterBloc.state).thenReturn(
        const HeadlinesFilterState(
          status: HeadlinesFilterStatus.failure,
          error: UnknownException('error'),
        ),
      );

      await tester.pumpWidget(buildWidget());

      expect(find.byType(FailureStateWidget), findsOneWidget);
    });

    testWidgets('tapping a source toggles selection', (tester) async {
      when(() => headlinesFilterBloc.state).thenReturn(
        HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          allSources: [source1],
          selectedSources: const {},
        ),
      );
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.text('Source One'));
      await tester.pump();

      verify(
        () => headlinesFilterBloc.add(
          FilterSourceToggled(source: source1, isSelected: true),
        ),
      ).called(1);
    });

    testWidgets('tapping filter icon navigates to source list filter page', (
      tester,
    ) async {
      when(() => headlinesFilterBloc.state).thenReturn(
        HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          allSources: [source1],
          selectedSources: const {},
        ),
      );
      final mockGoRouter = MockGoRouter();
      when(
        () => mockGoRouter.pushNamed(any(), extra: any(named: 'extra')),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        MockGoRouterProvider(goRouter: mockGoRouter, child: buildWidget()),
      );

      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();

      verify(
        () => mockGoRouter.pushNamed(
          Routes.sourceListFilterName,
          extra: headlinesFilterBloc,
        ),
      ).called(1);
    });

    testWidgets('tapping apply button pops the page', (tester) async {
      when(() => headlinesFilterBloc.state).thenReturn(
        HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          allSources: [source1],
          selectedSources: const {},
        ),
      );
      final mockNavigator = MockGoRouter();
      when(() => mockNavigator.pop<void>()).thenAnswer((_) async {
        return;
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ui_kit.UiKitLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MockGoRouterProvider(
            goRouter: mockNavigator,
            child: SourceFilterPage(filterBloc: headlinesFilterBloc),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      verify(mockNavigator.pop).called(1);
    });
  });
}
