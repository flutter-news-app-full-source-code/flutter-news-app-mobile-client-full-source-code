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
  const RewardsLoadingAd({super.snackbarMessage});

  @override
  RewardsLoadingAd copyWith({ValueGetter<String?>? snackbarMessage}) =>
      RewardsLoadingAd(
        snackbarMessage: snackbarMessage != null
            ? snackbarMessage()
            : this.snackbarMessage,
      );
}

final class RewardsVerifying extends RewardsState {
  const RewardsVerifying({super.snackbarMessage});

  @override
  RewardsVerifying copyWith({ValueGetter<String?>? snackbarMessage}) =>
      RewardsVerifying(
        snackbarMessage: snackbarMessage != null
            ? snackbarMessage()
            : this.snackbarMessage,
      );
}

final class RewardsSuccess extends RewardsState {
  const RewardsSuccess({super.snackbarMessage});

  @override
  RewardsSuccess copyWith({ValueGetter<String?>? snackbarMessage}) =>
      RewardsSuccess(
        snackbarMessage: snackbarMessage != null
            ? snackbarMessage()
            : this.snackbarMessage,
      );
}
