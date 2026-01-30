import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:logging/logging.dart';

part 'rewards_event.dart';
part 'rewards_state.dart';

class RewardsBloc extends Bloc<RewardsEvent, RewardsState> {
  RewardsBloc({
    required AppBloc appBloc,
    required AnalyticsService analyticsService,
    Logger? logger,
  }) : _appBloc = appBloc,
       _analyticsService = analyticsService,
       _logger = logger ?? Logger('RewardsBloc'),
       super(const RewardsInitial()) {
    on<RewardsStarted>(_onRewardsStarted);
    on<RewardsAdRequested>(_onRewardsAdRequested);
    on<RewardsAdWatched>(_onRewardsAdWatched);
    on<_RewardsTimerTicked>(_onRewardsTimerTicked);
    on<RewardsAdFailed>(_onRewardsAdFailed);
    on<RewardsAdDismissed>(_onRewardsAdDismissed);
    on<SnackbarShown>(_onSnackbarShown);
  }

  final AppBloc _appBloc;
  final AnalyticsService _analyticsService;
  final Logger _logger;
  Timer? _timer;

  Future<void> _onRewardsStarted(
    RewardsStarted event,
    Emitter<RewardsState> emit,
  ) async {
    await _analyticsService.logEvent(
      AnalyticsEvent.rewardsHubViewed,
      payload: const RewardsHubViewedPayload(),
    );
  }

  void _onRewardsAdFailed(RewardsAdFailed event, Emitter<RewardsState> emit) =>
      emit(const RewardsInitial(snackbarMessage: 'rewardsSnackbarFailure'));

  void _onRewardsAdDismissed(
    RewardsAdDismissed event,
    Emitter<RewardsState> emit,
  ) =>
      emit(const RewardsInitial(snackbarMessage: 'rewardsAdDismissedSnackbar'));

  void _onSnackbarShown(SnackbarShown event, Emitter<RewardsState> emit) {
    emit(state.copyWith(snackbarMessage: () => null));
  }

  void _onRewardsAdRequested(
    RewardsAdRequested event,
    Emitter<RewardsState> emit,
  ) {
    emit(RewardsLoadingAd(activeRewardType: event.type));
  }

  void _onRewardsAdWatched(RewardsAdWatched event, Emitter<RewardsState> emit) {
    if (state.activeRewardType == null) return;
    emit(RewardsVerifying(activeRewardType: state.activeRewardType));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      add(_RewardsTimerTicked());
    });
  }

  Future<void> _onRewardsTimerTicked(
    _RewardsTimerTicked event,
    Emitter<RewardsState> emit,
  ) async {
    final rewardType = state.activeRewardType;
    if (rewardType == null) {
      _logger.warning('Timer ticked but no active reward type to verify.');
      _timer?.cancel();
      return;
    }

    _logger.info('Verifying reward status for: $rewardType');
    final completer = Completer<UserRewards?>();
    _appBloc.add(UserRewardsRefreshed(completer: completer));

    try {
      final userRewards = await completer.future;
      final isRewardActive = userRewards?.isRewardActive(rewardType) ?? false;

      _logger.info('Verification check result: $isRewardActive');

      if (isRewardActive) {
        _logger.info('Reward $rewardType is active. Stopping timer.');
        _timer?.cancel();
        if (state is! RewardsSuccess) {
          emit(RewardsSuccess(activeRewardType: rewardType));

          final duration =
              _appBloc
                  .state
                  .remoteConfig
                  ?.features
                  .rewards
                  .rewards[rewardType]
                  ?.durationDays ??
              0;

          unawaited(
            _analyticsService.logEvent(
              AnalyticsEvent.rewardGranted,
              payload: RewardGrantedPayload(
                rewardType: rewardType,
                durationDays: duration,
              ),
            ),
          );
        }
      }
    } catch (e, s) {
      _logger.severe('Error during reward verification in RewardsBloc', e, s);
      // The timer will continue, and the next tick will retry.
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
