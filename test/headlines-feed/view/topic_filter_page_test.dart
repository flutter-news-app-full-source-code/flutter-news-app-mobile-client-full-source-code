import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/topic_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../helpers/helpers.dart';

class MockHeadlinesFilterBloc
    extends MockBloc<HeadlinesFilterEvent, HeadlinesFilterState>
    implements HeadlinesFilterBloc {}

void main() {
  group('TopicFilterPage', () {
    late HeadlinesFilterBloc headlinesFilterBloc;

    final topic1 = Topic(
      id: 't1',
      name: 'Technology',
      description: '',
      iconUrl: '',
      createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      status: ContentStatus.active,
    );
    final topic2 = Topic(
      id: 't2',
      name: 'Business',
      description: '',
      iconUrl: '',
      createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      status: ContentStatus.active,
    );

    setUp(() {
      headlinesFilterBloc = MockHeadlinesFilterBloc();
      when(() => headlinesFilterBloc.state).thenReturn(
        HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          allTopics: [topic1, topic2],
          selectedTopics: const {},
        ),
      );
    });

    Widget buildWidget() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TopicFilterPage(filterBloc: headlinesFilterBloc),
      );
    }

    testWidgets('renders correctly with topics list', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Topic'), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
    });

    testWidgets('tapping a topic toggles selection', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.text('Technology'));
      await tester.pump();

      verify(
        () => headlinesFilterBloc.add(
          FilterTopicToggled(topic: topic1, isSelected: true),
        ),
      ).called(1);
    });

    testWidgets('shows empty state when no topics are available', (
      tester,
    ) async {
      when(() => headlinesFilterBloc.state).thenReturn(
        const HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          allTopics: [],
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
          child: TopicFilterPage(filterBloc: headlinesFilterBloc),
        ),
      );

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      verify(mockNavigator.pop).called(1);
    });
  });
}
