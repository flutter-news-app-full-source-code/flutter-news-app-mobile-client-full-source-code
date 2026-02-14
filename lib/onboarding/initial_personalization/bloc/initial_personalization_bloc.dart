import 'dart:async';
import 'dart:math';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/initialization_result.dart';
import 'package:logging/logging.dart';

part 'initial_personalization_event.dart';
part 'initial_personalization_state.dart';

class InitialPersonalizationBloc
    extends Bloc<InitialPersonalizationEvent, InitialPersonalizationState> {
  InitialPersonalizationBloc({
    required AppBloc appBloc,
    required DataRepository<UserContentPreferences>
    userContentPreferencesRepository,
    required DataRepository<UserContext> userContextRepository,
    required AnalyticsService analyticsService,
    required Logger logger,
  }) : _appBloc = appBloc,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _userContextRepository = userContextRepository,
       _analyticsService = analyticsService,
       _logger = logger,
       super(const InitialPersonalizationState()) {
    on<InitialPersonalizationDataRequested>(_onDataRequested);
    on<InitialPersonalizationItemsSelected<Topic>>(_onTopicsSelected);
    on<InitialPersonalizationItemsSelected<Source>>(_onSourcesSelected);
    on<InitialPersonalizationItemsSelected<Country>>(_onCountriesSelected);
    on<InitialPersonalizationCompleted>(_onCompleted);
    on<InitialPersonalizationSkipped>(_onSkipped);

    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvent.initialPersonalizationStarted,
        payload: const InitialPersonalizationStartedPayload(),
      ),
    );
  }

  final AppBloc _appBloc;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final DataRepository<UserContext> _userContextRepository;
  final AnalyticsService _analyticsService;
  final Logger _logger;

  Future<void> _onDataRequested(
    InitialPersonalizationDataRequested event,
    Emitter<InitialPersonalizationState> emit,
  ) async {
    emit(state.copyWith(status: InitialPersonalizationStatus.loading));

    try {
      final remoteConfig = _appBloc.state.remoteConfig!;
      final user = _appBloc.state.user!;

      final followedItemsLimit =
          remoteConfig.user.limits.followedItems[user.tier] ?? 0;

      emit(
        state.copyWith(
          status: InitialPersonalizationStatus.success,
          maxSelectionsPerCategory: followedItemsLimit,
        ),
      );
    } on HttpException catch (e, s) {
      _logger.severe('Failed to load initial personalization data.', e, s);
      emit(
        state.copyWith(status: InitialPersonalizationStatus.failure, error: e),
      );
    }
  }

  void _onTopicsSelected(
    InitialPersonalizationItemsSelected<Topic> event,
    Emitter<InitialPersonalizationState> emit,
  ) {
    emit(state.copyWith(selectedTopics: event.items));
  }

  void _onSourcesSelected(
    InitialPersonalizationItemsSelected<Source> event,
    Emitter<InitialPersonalizationState> emit,
  ) {
    emit(state.copyWith(selectedSources: event.items));
  }

  void _onCountriesSelected(
    InitialPersonalizationItemsSelected<Country> event,
    Emitter<InitialPersonalizationState> emit,
  ) {
    emit(state.copyWith(selectedCountries: event.items));
  }

  Future<void> _onCompleted(
    InitialPersonalizationCompleted event,
    Emitter<InitialPersonalizationState> emit,
  ) async {
    emit(state.copyWith(status: InitialPersonalizationStatus.saving));
    final user = _appBloc.state.user!;
    final userContext = _appBloc.state.userContext!;

    try {
      final preferences = await _userContentPreferencesRepository.read(
        id: user.id,
      );
      final updatedPreferences = preferences.copyWith(
        followedTopics: state.selectedTopics.toList(),
        followedSources: state.selectedSources.toList(),
        followedCountries: state.selectedCountries.toList(),
      );

      final [
        updatedPreferencesResult as UserContentPreferences,
        updatedContextResult as UserContext,
      ] = await Future.wait([
        _userContentPreferencesRepository.update(
          id: user.id,
          item: updatedPreferences,
        ),
        _userContextRepository.update(
          id: user.id,
          item: userContext.copyWith(hasCompletedInitialPersonalization: true),
        ),
      ]);

      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.initialPersonalizationCompleted,
          payload: const InitialPersonalizationCompletedPayload(),
        ),
      );

      _appBloc.add(
        AppOnboardingCompleted(
          status: OnboardingStatus.postAuthPersonalization,
          userContentPreferences: updatedPreferencesResult,
          userContext: updatedContextResult,
        ),
      );
    } catch (e, s) {
      _logger.severe('Failed to save initial personalization.', e, s);
      emit(state.copyWith(status: InitialPersonalizationStatus.failure));
    }
  }

  Future<void> _onSkipped(
    InitialPersonalizationSkipped event,
    Emitter<InitialPersonalizationState> emit,
  ) async {
    emit(state.copyWith(status: InitialPersonalizationStatus.saving));
    final user = _appBloc.state.user!;
    final userContext = _appBloc.state.userContext!;

    try {
      final updatedContext = userContext.copyWith(
        hasCompletedInitialPersonalization: true,
      );
      final updatedContextResult = await _userContextRepository.update(
        id: user.id,
        item: updatedContext,
      );

      unawaited(
        _analyticsService.logEvent(
          AnalyticsEvent.initialPersonalizationSkipped,
          payload: const InitialPersonalizationSkippedPayload(),
        ),
      );

      _appBloc.add(
        AppOnboardingCompleted(
          status: OnboardingStatus.postAuthPersonalization,
          userContext: updatedContextResult,
        ),
      );
    } catch (e, s) {
      _logger.severe('Failed to save skipped personalization status.', e, s);
      emit(state.copyWith(status: InitialPersonalizationStatus.failure));
    }
  }
}
