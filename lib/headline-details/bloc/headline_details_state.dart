part of 'headline_details_bloc.dart';

abstract class HeadlineDetailsState extends Equatable {
  const HeadlineDetailsState();

  @override
  List<Object> get props => [];
}

class HeadlineDetailsInitial extends HeadlineDetailsState {}

class HeadlineDetailsLoading extends HeadlineDetailsState {}

class HeadlineDetailsLoaded extends HeadlineDetailsState {
  const HeadlineDetailsLoaded({required this.headline});

  final Headline headline;

  @override
  List<Object> get props => [headline];
}

class HeadlineDetailsFailure extends HeadlineDetailsState {
  const HeadlineDetailsFailure({required this.exception});

  final HttpException exception;

  @override
  List<Object> get props => [exception];
}
