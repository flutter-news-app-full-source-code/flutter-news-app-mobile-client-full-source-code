import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(const AppState()) {
    on<AppNavigationIndexChanged>((event, emit) {
      emit(state.copyWith(selectedIndex: event.index));
    });
  }
}
