part of 'headline_details_bloc.dart';

abstract class HeadlineDetailsState {}

class HeadlineDetailsInitial extends HeadlineDetailsState {}

class HeadlineDetailsLoading extends HeadlineDetailsState {}

class HeadlineDetailsLoaded extends HeadlineDetailsState {
  HeadlineDetailsLoaded({required this.headline});

  final Headline headline;
}

class HeadlineDetailsFailure extends HeadlineDetailsState {
  HeadlineDetailsFailure({required this.message});

  final String message;
}
