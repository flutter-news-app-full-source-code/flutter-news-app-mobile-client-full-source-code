part of 'available_topics_bloc.dart';

abstract class AvailableTopicsEvent extends Equatable {
  const AvailableTopicsEvent();

  @override
  List<Object> get props => [];
}

class FetchAvailableTopics extends AvailableTopicsEvent {
  const FetchAvailableTopics();
}
