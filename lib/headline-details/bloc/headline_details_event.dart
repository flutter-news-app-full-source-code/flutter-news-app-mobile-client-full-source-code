part of 'headline_details_bloc.dart';

abstract class HeadlineDetailsEvent {}

class HeadlineDetailsRequested extends HeadlineDetailsEvent {
  HeadlineDetailsRequested({required this.headlineId});

  final String headlineId;
}
