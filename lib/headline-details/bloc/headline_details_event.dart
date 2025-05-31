part of 'headline_details_bloc.dart';

abstract class HeadlineDetailsEvent extends Equatable {
  const HeadlineDetailsEvent();

  @override
  List<Object> get props => [];
}

class FetchHeadlineById extends HeadlineDetailsEvent {
  const FetchHeadlineById(this.headlineId);
  final String headlineId;

  @override
  List<Object> get props => [headlineId];
}

class HeadlineProvided extends HeadlineDetailsEvent {
  const HeadlineProvided(this.headline);
  final Headline headline;

  @override
  List<Object> get props => [headline];
}
