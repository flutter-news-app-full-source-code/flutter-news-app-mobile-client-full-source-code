part of 'rewards_bloc.dart';

sealed class RewardsState extends Equatable {
  const RewardsState({this.snackbarMessage});

  final String? snackbarMessage;

  @override
  List<Object?> get props => [snackbarMessage];

  RewardsState copyWith({ValueGetter<String?>? snackbarMessage});
}

final class RewardsInitial extends RewardsState {
  const RewardsInitial({super.snackbarMessage});

  @override
  RewardsInitial copyWith({ValueGetter<String?>? snackbarMessage}) =>
      RewardsInitial(
        snackbarMessage: snackbarMessage != null
            ? snackbarMessage()
            : this.snackbarMessage,
      );
}

final class RewardsLoadingAd extends RewardsState {
  @override
  RewardsLoadingAd copyWith({ValueGetter<String?>? snackbarMessage}) =>
      RewardsLoadingAd();
}

final class RewardsVerifying extends RewardsState {
  @override
  RewardsVerifying copyWith({ValueGetter<String?>? snackbarMessage}) =>
      RewardsVerifying();
}

final class RewardsSuccess extends RewardsState {
  @override
  RewardsSuccess copyWith({ValueGetter<String?>? snackbarMessage}) =>
      RewardsSuccess();
}
