import 'dart:async';

import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/initialization_result.dart';
import 'package:kv_storage_service/kv_storage_service.dart';
import 'package:logging/logging.dart';

part 'app_tour_event.dart';
part 'app_tour_state.dart';

/// {@template app_tour_bloc}
/// Manages the state for the pre-authentication app tour.
///
/// This BLoC handles page navigation within the tour and persists the
/// completion status to local storage before triggering an app restart.
/// {@endtemplate}
class AppTourBloc extends Bloc<AppTourEvent, AppTourState> {
  /// {@macro app_tour_bloc}
  AppTourBloc({
    required AppBloc appBloc,
    required KVStorageService storageService,
    required AnalyticsService analyticsService,
    required Logger logger,
  }) : _appBloc = appBloc,
       _storageService = storageService,
       _analyticsService = analyticsService,
       _logger = logger,
       super(const AppTourState()) {
    on<AppTourPageChanged>(_onPageChanged);
    on<AppTourCompleted>(_onCompleted);

    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvent.appTourStarted,
        payload: const AppTourStartedPayload(),
      ),
    );
  }

  final AppBloc _appBloc;
  final KVStorageService _storageService;
  final AnalyticsService _analyticsService;
  final Logger _logger;

  void _onPageChanged(AppTourPageChanged event, Emitter<AppTourState> emit) {
    emit(state.copyWith(currentPage: event.pageIndex));
    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvent.appTourStepViewed,
        payload: AppTourStepViewedPayload(stepIndex: event.pageIndex),
      ),
    );
  }

  Future<void> _onCompleted(
    AppTourCompleted event,
    Emitter<AppTourState> emit,
  ) async {
    _logger.info('App tour completed. Persisting status...');
    await _storageService.writeBool(
      key: StorageKey.hasSeenAppTour.stringValue,
      value: true,
    );
    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvent.appTourCompleted,
        payload: const AppTourCompletedPayload(),
      ),
    );
    _appBloc.add(
      const AppOnboardingCompleted(status: OnboardingStatus.preAuthTour),
    );
  }
}
