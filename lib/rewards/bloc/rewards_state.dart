part of 'rewards_bloc.dart';

sealed class RewardsState extends Equatable {
  const RewardsState({this.activeRewardType, this.snackbarMessage});

  final RewardType? activeRewardType;
  final String? snackbarMessage;

  @override
  List<Object?> get props => [activeRewardType, snackbarMessage];

  RewardsState copyWith({
    ValueGetter<RewardType?>? activeRewardType,
    ValueGetter<String?>? snackbarMessage,
  }) {
    if (this is RewardsInitial) {
      return RewardsInitial(
        activeRewardType: activeRewardType != null
            ? activeRewardType()
            : this.activeRewardType,
        snackbarMessage: snackbarMessage != null
            ? snackbarMessage()
            : this.snackbarMessage,
      );
    }
    // For other states, we just return them as they are,
    // as they don't carry extra properties in this design.
    return this;
  }
}

final class RewardsInitial extends RewardsState {
  const RewardsInitial({super.activeRewardType, super.snackbarMessage});
}

final class RewardsLoadingAd extends RewardsState {
  const RewardsLoadingAd({required super.activeRewardType});
}

final class RewardsVerifying extends RewardsState {
  const RewardsVerifying({required super.activeRewardType});
}

final class RewardsSuccess extends RewardsState {
  const RewardsSuccess({required super.activeRewardType});
}
