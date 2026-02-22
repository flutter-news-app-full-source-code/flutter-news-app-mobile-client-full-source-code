import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_search_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDataRepository extends Mock implements DataRepository<Headline> {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class FakeSearchPerformedPayload extends Fake
    implements SearchPerformedPayload {}

void main() {
  group('HeadlineSearchBloc', () {
    late DataRepository<Headline> headlinesRepository;
    late AnalyticsService analyticsService;

    setUpAll(() {
      registerFallbackValue(FakeSearchPerformedPayload());
      registerFallbackValue(AnalyticsEvent.searchPerformed);
    });

    setUp(() {
      headlinesRepository = MockDataRepository();
      analyticsService = MockAnalyticsService();
      when(
        () => analyticsService.logEvent(any(), payload: any(named: 'payload')),
      ).thenAnswer((_) async {});
    });

    test('initial state is correct', () {
      expect(
        HeadlineSearchBloc(
          headlinesRepository: headlinesRepository,
          analyticsService: analyticsService,
        ).state,
        const HeadlineSearchState(),
      );
    });

    blocTest<HeadlineSearchBloc, HeadlineSearchState>(
      'emits [initial] when query is too short',
      build: () => HeadlineSearchBloc(
        headlinesRepository: headlinesRepository,
        analyticsService: analyticsService,
      ),
      act: (bloc) => bloc.add(const HeadlineSearchQueryChanged('ab')),
      wait: const Duration(milliseconds: 350),
      expect: () => [
        const HeadlineSearchState(status: HeadlineSearchStatus.initial),
      ],
    );

    blocTest<HeadlineSearchBloc, HeadlineSearchState>(
      'emits [loading, success] when search is successful',
      build: () => HeadlineSearchBloc(
        headlinesRepository: headlinesRepository,
        analyticsService: analyticsService,
      ),
      setUp: () {
        when(
          () => headlinesRepository.readAll(
            filter: any(named: 'filter'),
            pagination: any(named: 'pagination'),
          ),
        ).thenAnswer(
          (_) async =>
              const PaginatedResponse(items: [], cursor: null, hasMore: false),
        );
      },
      act: (bloc) => bloc.add(const HeadlineSearchQueryChanged('flutter')),
      wait: const Duration(milliseconds: 350),
      expect: () => [
        const HeadlineSearchState(status: HeadlineSearchStatus.loading),
        const HeadlineSearchState(
          status: HeadlineSearchStatus.success,
          headlines: [],
        ),
      ],
      verify: (_) {
        verify(
          () => headlinesRepository.readAll(
            filter: any(named: 'filter'),
            pagination: any(named: 'pagination'),
          ),
        ).called(1);
        verify(
          () => analyticsService.logEvent(
            AnalyticsEvent.searchPerformed,
            payload: any(named: 'payload'),
          ),
        ).called(1);
      },
    );

    blocTest<HeadlineSearchBloc, HeadlineSearchState>(
      'emits [loading, failure] when search fails',
      build: () => HeadlineSearchBloc(
        headlinesRepository: headlinesRepository,
        analyticsService: analyticsService,
      ),
      setUp: () {
        when(
          () => headlinesRepository.readAll(
            filter: any(named: 'filter'),
            pagination: any(named: 'pagination'),
          ),
        ).thenThrow(const HttpException('oops'));
      },
      act: (bloc) => bloc.add(const HeadlineSearchQueryChanged('error')),
      wait: const Duration(milliseconds: 350),
      expect: () => [
        const HeadlineSearchState(status: HeadlineSearchStatus.loading),
        isA<HeadlineSearchState>()
            .having((s) => s.status, 'status', HeadlineSearchStatus.failure)
            .having((s) => s.error, 'error', isA<HttpException>()),
      ],
    );
  });
}
