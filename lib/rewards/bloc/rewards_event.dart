part of 'rewards_bloc.dart';

sealed class RewardsEvent extends Equatable {
  const RewardsEvent();

  @override
  List<Object> get props => [];
}

final class RewardsStarted extends RewardsEvent {}

final class RewardsAdFailed extends RewardsEvent {}

final class RewardsAdDismissed extends RewardsEvent {}

final class RewardsAdRequested extends RewardsEvent {
  const RewardsAdRequested({required this.type});
  final RewardType type;
}

final class RewardsAdWatched extends RewardsEvent {}

final class SnackbarShown extends RewardsEvent {}

final class _RewardsTimerTicked extends RewardsEvent {}

final class _RewardsStatusChanged extends RewardsEvent {
  const _RewardsStatusChanged({required this.isRewardActive});
  final bool isRewardActive;
}
