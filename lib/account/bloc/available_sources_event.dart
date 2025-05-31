part of 'available_sources_bloc.dart';

abstract class AvailableSourcesEvent extends Equatable {
  const AvailableSourcesEvent();

  @override
  List<Object> get props => [];
}

class FetchAvailableSources extends AvailableSourcesEvent {
  const FetchAvailableSources();
}
