part of 'rewards_bloc.dart';

sealed class RewardsState extends Equatable {
  const RewardsState();

  @override
  List<Object> get props => [];
}

final class RewardsInitial extends RewardsState {}

final class RewardsLoadingAd extends RewardsState {}

final class RewardsVerifying extends RewardsState {}

final class RewardsSuccess extends RewardsState {}
