part of 'rewards_bloc.dart';

sealed class RewardsEvent extends Equatable {
  const RewardsEvent();

  @override
  List<Object> get props => [];
}

final class RewardsAdRequested extends RewardsEvent {}

final class RewardsAdWatched extends RewardsEvent {}

final class _RewardsTimerTicked extends RewardsEvent {}

final class _RewardsStatusChanged extends RewardsEvent {
  const _RewardsStatusChanged({required this.isRewardActive});
  final bool isRewardActive;
}
