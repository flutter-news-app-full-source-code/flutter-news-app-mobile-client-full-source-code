import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';

part 'rewards_event.dart';
part 'rewards_state.dart';

class RewardsBloc extends Bloc<RewardsEvent, RewardsState> {
  RewardsBloc({
    required AppBloc appBloc,
    required AnalyticsService analyticsService,
  }) : _appBloc = appBloc,
       _analyticsService = analyticsService,
       super(RewardsInitial()) {
    on<RewardsStarted>(_onRewardsStarted);
    on<RewardsAdRequested>(_onRewardsAdRequested);
    on<RewardsAdWatched>(_onRewardsAdWatched);
    on<_RewardsTimerTicked>(_onRewardsTimerTicked);
    on<_RewardsStatusChanged>(_onRewardsStatusChanged);
    on<RewardsAdFailed>(_onRewardsAdFailed);
    on<RewardsAdDismissed>(_onRewardsAdDismissed);
    on<SnackbarShown>(_onSnackbarShown);

    _appBlocSubscription = _appBloc.stream.listen((state) {
      final isRewardActive =
          state.userRewards?.isRewardActive(RewardType.adFree) ?? false;
      add(_RewardsStatusChanged(isRewardActive: isRewardActive));
    });
  }

  final AppBloc _appBloc;
  final AnalyticsService _analyticsService;
  late final StreamSubscription<AppState> _appBlocSubscription;
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
    emit(RewardsVerifying(activeRewardType: state.activeRewardType!));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      add(_RewardsTimerTicked());
    });
  }

  void _onRewardsTimerTicked(
    _RewardsTimerTicked event,
    Emitter<RewardsState> emit,
  ) {
    _appBloc.add(const UserRewardsRefreshed());
  }

  void _onRewardsStatusChanged(
    _RewardsStatusChanged event,
    Emitter<RewardsState> emit,
  ) {
    if (event.isRewardActive) {
      _timer?.cancel();
      if (state is! RewardsSuccess && state.activeRewardType != null) {
        emit(RewardsSuccess(activeRewardType: state.activeRewardType!));
      }
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _appBlocSubscription.cancel();
    return super.close();
  }
}
