import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTopicsRepository extends Mock implements DataRepository<Topic> {}

class MockSourcesRepository extends Mock implements DataRepository<Source> {}

class MockCountriesRepository extends Mock implements DataRepository<Country> {}

void main() {
  group('HeadlinesFilterBloc', () {
    late DataRepository<Topic> topicsRepository;
    late DataRepository<Source> sourcesRepository;
    late DataRepository<Country> countriesRepository;
    late HeadlinesFilterBloc headlinesFilterBloc;

    final topic1 = Topic(
      id: '1',
      name: 'Tech',
      description: '',
      iconUrl: '',
      createdAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
      updatedAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
      status: ContentStatus.active,
    );
    final source1 = Source(
      id: 's1',
      name: 'Source 1',
      description: '',
      url: '',
      logoUrl: '',
      sourceType: SourceType.blog,
      language: Language(
        id: 'l1',
        code: 'en',
        name: 'English',
        nativeName: 'English',
        createdAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
        status: ContentStatus.active,
      ),
      headquarters: Country(
        id: 'c1',
        isoCode: 'US',
        name: 'USA',
        flagUrl: '',
        createdAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
        status: ContentStatus.active,
      ),
      createdAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
      updatedAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
      status: ContentStatus.active,
    );
    final country1 = Country(
      id: 'c1',
      isoCode: 'US',
      name: 'USA',
      flagUrl: '',
      createdAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
      updatedAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
      status: ContentStatus.active,
    );
    final country2 = Country(
      id: 'c2',
      isoCode: 'GB',
      name: 'UK',
      flagUrl: '',
      createdAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
      updatedAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
      status: ContentStatus.active,
    );

    setUp(() {
      topicsRepository = MockTopicsRepository();
      sourcesRepository = MockSourcesRepository();
      countriesRepository = MockCountriesRepository();

      when(
        () => topicsRepository.readAll(
          filter: any(named: 'filter'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer(
        (_) async =>
            PaginatedResponse(items: [topic1], cursor: null, hasMore: false),
      );
      when(
        () => sourcesRepository.readAll(
          filter: any(named: 'filter'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer(
        (_) async =>
            PaginatedResponse(items: [source1], cursor: null, hasMore: false),
      );
      // Mock separate calls for event countries and headquarter countries
      when(
        () => countriesRepository.readAll(
          filter: {'hasActiveSources': true},
          sort: any(named: 'sort'),
        ),
      ).thenAnswer(
        (_) async =>
            PaginatedResponse(items: [country1], cursor: null, hasMore: false),
      );
      when(
        () =>
            countriesRepository.readAll(filter: null, sort: any(named: 'sort')),
      ).thenAnswer(
        (_) async => PaginatedResponse(
          items: [country1, country2],
          cursor: null,
          hasMore: false,
        ),
      );

      headlinesFilterBloc = HeadlinesFilterBloc(
        topicsRepository: topicsRepository,
        sourcesRepository: sourcesRepository,
        countriesRepository: countriesRepository,
      );
    });

    test('initial state is correct', () {
      expect(headlinesFilterBloc.state, const HeadlinesFilterState());
    });

    blocTest<HeadlinesFilterBloc, HeadlinesFilterState>(
      'emits [loading, success] when FilterDataLoaded is added and succeeds',
      build: () => headlinesFilterBloc,
      act: (bloc) => bloc.add(const FilterDataLoaded()),
      expect: () => <HeadlinesFilterState>[
        const HeadlinesFilterState(status: HeadlinesFilterStatus.loading),
        HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          allTopics: [topic1],
          allSources: [source1],
          allCountries: [country1],
          allHeadquarterCountries: [country1, country2],
          allSourceTypes: SourceType.values,
          selectedTopics: const {},
          selectedSources: const {},
          selectedCountries: const {},
        ),
      ],
      verify: (_) {
        verify(
          () => countriesRepository.readAll(
            filter: {'hasActiveSources': true},
            sort: any(named: 'sort'),
          ),
        ).called(1);
        verify(
          () => countriesRepository.readAll(
            filter: null,
            sort: any(named: 'sort'),
          ),
        ).called(1);
      },
    );

    blocTest<HeadlinesFilterBloc, HeadlinesFilterState>(
      'emits [loading, failure] when FilterDataLoaded fails',
      build: () {
        when(
          () => topicsRepository.readAll(
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenThrow(const NetworkException());
        return headlinesFilterBloc;
      },
      act: (bloc) => bloc.add(const FilterDataLoaded()),
      expect: () => <HeadlinesFilterState>[
        const HeadlinesFilterState(status: HeadlinesFilterStatus.loading),
        const HeadlinesFilterState(
          status: HeadlinesFilterStatus.failure,
          error: NetworkException(),
        ),
      ],
    );

    blocTest<HeadlinesFilterBloc, HeadlinesFilterState>(
      'toggles topic selection correctly',
      build: () => headlinesFilterBloc,
      seed: () => const HeadlinesFilterState(
        status: HeadlinesFilterStatus.success,
        selectedTopics: {},
      ),
      act: (bloc) => bloc
        ..add(FilterTopicToggled(topic: topic1, isSelected: true))
        ..add(FilterTopicToggled(topic: topic1, isSelected: false)),
      expect: () => <HeadlinesFilterState>[
        HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          selectedTopics: {topic1},
        ),
        const HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          selectedTopics: {},
        ),
      ],
    );

    blocTest<HeadlinesFilterBloc, HeadlinesFilterState>(
      'clears all selections',
      build: () => headlinesFilterBloc,
      seed: () => HeadlinesFilterState(
        status: HeadlinesFilterStatus.success,
        selectedTopics: {topic1},
        selectedSources: {source1},
        selectedCountries: {country1},
      ),
      act: (bloc) => bloc.add(const FilterSelectionsCleared()),
      expect: () => <HeadlinesFilterState>[
        const HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          selectedTopics: {},
          selectedSources: {},
          selectedCountries: {},
        ),
      ],
    );

    blocTest<HeadlinesFilterBloc, HeadlinesFilterState>(
      'updates source filter criteria',
      build: () => headlinesFilterBloc,
      seed: () =>
          const HeadlinesFilterState(status: HeadlinesFilterStatus.success),
      act: (bloc) => bloc.add(
        FilterSourceCriteriaChanged(
          selectedCountries: {country1},
          selectedSourceTypes: const {SourceType.blog},
        ),
      ),
      expect: () => <HeadlinesFilterState>[
        HeadlinesFilterState(
          status: HeadlinesFilterStatus.success,
          selectedSourceHeadquarterCountries: {country1},
          selectedSourceTypes: const {SourceType.blog},
        ),
      ],
    );
  });
}
