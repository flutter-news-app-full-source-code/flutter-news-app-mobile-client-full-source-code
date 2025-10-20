import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'discover_event.dart';
part 'discover_state.dart';

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  DiscoverBloc() : super(DiscoverInitial()) {
    on<DiscoverEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
