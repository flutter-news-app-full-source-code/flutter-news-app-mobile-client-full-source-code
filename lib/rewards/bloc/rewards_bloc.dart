import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';

part 'rewards_event.dart';
part 'rewards_state.dart';

class RewardsBloc extends Bloc<RewardsEvent, RewardsState> {
  RewardsBloc({required AppBloc appBloc})
    : _appBloc = appBloc,
      super(RewardsInitial()) {
    on<RewardsAdRequested>(_onRewardsAdRequested);
    on<RewardsAdWatched>(_onRewardsAdWatched);
    on<_RewardsTimerTicked>(_onRewardsTimerTicked);
    on<_RewardsStatusChanged>(_onRewardsStatusChanged);

    _appBlocSubscription = _appBloc.stream.listen((state) {
      final isRewardActive =
          state.userRewards?.isRewardActive(RewardType.adFree) ?? false;
      add(_RewardsStatusChanged(isRewardActive: isRewardActive));
    });
  }

  final AppBloc _appBloc;
  late final StreamSubscription<AppState> _appBlocSubscription;
  Timer? _timer;

  void _onRewardsAdRequested(
    RewardsAdRequested event,
    Emitter<RewardsState> emit,
  ) {
    emit(RewardsLoadingAd());
  }

  void _onRewardsAdWatched(RewardsAdWatched event, Emitter<RewardsState> emit) {
    emit(RewardsVerifying());
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
      if (state is! RewardsSuccess) {
        emit(RewardsSuccess());
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
