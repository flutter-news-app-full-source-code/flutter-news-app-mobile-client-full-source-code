import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'available_topics_event.dart';
part 'available_topics_state.dart';

class AvailableTopicsBloc extends Bloc<AvailableTopicsEvent, AvailableTopicsState> {
  AvailableTopicsBloc() : super(AvailableTopicsInitial()) {
    on<AvailableTopicsEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
