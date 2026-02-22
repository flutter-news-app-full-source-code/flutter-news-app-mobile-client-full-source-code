import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart'
    as app_bloc;
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/saved_headlines_filters_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppBloc extends Mock implements app_bloc.AppBloc {}

class MockUserContentPreferences extends Mock
    implements UserContentPreferences {}

void main() {
  group('SavedHeadlinesFiltersBloc', () {
    late app_bloc.AppBloc appBloc;
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

    const userContentPreferences = UserContentPreferences(
      id: 'user1',
      followedCountries: [],
      followedSources: [],
      followedTopics: [],
      savedHeadlines: [],
      savedHeadlineFilters: [filter1, filter2],
      savedSourceFilters: [],
    );

    const initialAppState = app_bloc.AppState(
      status: AppLifeCycleStatus.authenticated,
      userContentPreferences: userContentPreferences,
    );

    setUp(() {
      appStateController = StreamController<app_bloc.AppState>.broadcast();
      appBloc = MockAppBloc();
      when(() => appBloc.state).thenReturn(initialAppState);
      when(() => appBloc.stream).thenAnswer((_) => appStateController.stream);
    });

    tearDown(() {
      appStateController.close();
    });

    blocTest<SavedHeadlinesFiltersBloc, SavedHeadlinesFiltersState>(
      'initial state is correct and loads data from AppBloc',
      build: () => SavedHeadlinesFiltersBloc(appBloc: appBloc),
      expect: () => <SavedHeadlinesFiltersState>[
        const SavedHeadlinesFiltersState(
          status: SavedHeadlinesFiltersStatus.success,
          filters: [filter1, filter2],
        ),
      ],
    );

    blocTest<SavedHeadlinesFiltersBloc, SavedHeadlinesFiltersState>(
      'emits new filter list when AppBloc state changes',
      build: () => SavedHeadlinesFiltersBloc(appBloc: appBloc),
      act: (bloc) {
        final newPreferences = userContentPreferences.copyWith(
          savedHeadlineFilters: [filter2, filter1],
        );
        appStateController.add(
          initialAppState.copyWith(userContentPreferences: newPreferences),
        );
      },
      skip: 1, // Skip the initial state loaded by the constructor.
      expect: () => <dynamic>[
        // The AppBloc stream update triggers another data load
        const SavedHeadlinesFiltersState(
          status: SavedHeadlinesFiltersStatus.success,
          filters: [filter2, filter1],
        ),
      ],
    );

    blocTest<SavedHeadlinesFiltersBloc, SavedHeadlinesFiltersState>(
      'dispatches SavedHeadlineFiltersReordered to AppBloc on reorder event',
      build: () => SavedHeadlinesFiltersBloc(appBloc: appBloc),
      act: (bloc) => bloc.add(
        const SavedHeadlinesFiltersReordered(
          reorderedFilters: [filter2, filter1],
        ),
      ),
      // The bloc should not emit its own state, but wait for AppBloc to
      // propagate the change.
      skip: 1,
      expect: () => <SavedHeadlinesFiltersState>[],
      verify: (_) {
        verify(
          () => appBloc.add(
            const app_bloc.SavedHeadlineFiltersReordered(
              reorderedFilters: [filter2, filter1],
            ),
          ),
        ).called(1);
      },
    );

    blocTest<SavedHeadlinesFiltersBloc, SavedHeadlinesFiltersState>(
      'dispatches SavedHeadlineFilterDeleted to AppBloc on delete event',
      build: () => SavedHeadlinesFiltersBloc(appBloc: appBloc),
      act: (bloc) =>
          bloc.add(const SavedHeadlinesFiltersDeleted(filterId: '1')),
      // Deleting a filter does not change its own state, it waits for AppBloc
      // to propagate change.
      skip: 1, // Skip the initial state loaded by the constructor.
      expect: () => <SavedHeadlinesFiltersState>[],
      verify: (_) {
        verify(
          () => appBloc.add(
            const app_bloc.SavedHeadlineFilterDeleted(filterId: '1'),
          ),
        ).called(1);
      },
    );
  });
}
