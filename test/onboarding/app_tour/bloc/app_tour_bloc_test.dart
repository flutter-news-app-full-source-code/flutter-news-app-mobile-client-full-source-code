import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/initialization_result.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/onboarding/app_tour/bloc/app_tour_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kv_storage_service/kv_storage_service.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockAppBloc extends Mock implements AppBloc {}

class MockKVStorageService extends Mock implements KVStorageService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockLogger extends Mock implements Logger {}

class FakeAppEvent extends Fake implements AppEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(AnalyticsEvent.appTourStarted);
    registerFallbackValue(const AppTourStartedPayload());
    registerFallbackValue(FakeAppEvent());
  });

  group('AppTourBloc', () {
    late AppBloc appBloc;
    late KVStorageService storageService;
    late AnalyticsService analyticsService;
    late Logger logger;

    setUp(() {
      appBloc = MockAppBloc();
      storageService = MockKVStorageService();
      analyticsService = MockAnalyticsService();
      logger = MockLogger();

      when(
        () => analyticsService.logEvent(any(), payload: any(named: 'payload')),
      ).thenAnswer((_) async {});
    });

    AppTourBloc buildBloc() {
      return AppTourBloc(
        appBloc: appBloc,
        storageService: storageService,
        analyticsService: analyticsService,
        logger: logger,
      );
    }

    test('initial state is AppTourState()', () {
      expect(buildBloc().state, const AppTourState());
    });

    test('logs AppTourStarted on creation', () {
      buildBloc();
      verify(
        () => analyticsService.logEvent(
          AnalyticsEvent.appTourStarted,
          payload: const AppTourStartedPayload(),
        ),
      ).called(1);
    });

    group('AppTourPageChanged', () {
      blocTest<AppTourBloc, AppTourState>(
        'emits new state with updated currentPage and logs event',
        build: buildBloc,
        act: (bloc) => bloc.add(const AppTourPageChanged(1)),
        expect: () => [const AppTourState(currentPage: 1)],
        verify: (_) {
          verify(
            () => analyticsService.logEvent(
              AnalyticsEvent.appTourStepViewed,
              payload: const AppTourStepViewedPayload(stepIndex: 1),
            ),
          ).called(1);
        },
      );
    });

    group('AppTourCompleted', () {
      setUp(() {
        when(
          () => storageService.writeBool(
            key: StorageKey.hasSeenAppTour.stringValue,
            value: true,
          ),
        ).thenAnswer((_) async {});
        when(() => appBloc.add(any())).thenAnswer((_) async {});
      });

      blocTest<AppTourBloc, AppTourState>(
        'persists completion status, logs event, and notifies AppBloc',
        build: buildBloc,
        act: (bloc) => bloc.add(AppTourCompleted()),
        verify: (_) {
          verify(
            () => storageService.writeBool(
              key: StorageKey.hasSeenAppTour.stringValue,
              value: true,
            ),
          ).called(1);

          verify(
            () => analyticsService.logEvent(
              AnalyticsEvent.appTourCompleted,
              payload: const AppTourCompletedPayload(),
            ),
          ).called(1);

          verify(
            () => appBloc.add(
              const AppOnboardingCompleted(
                status: OnboardingStatus.preAuthTour,
              ),
            ),
          ).called(1);
        },
      );
    });
  });
}
