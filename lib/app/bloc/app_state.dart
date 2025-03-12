part of 'app_bloc.dart';

@immutable
class AppState {
  const AppState({this.selectedIndex = 0});
  final int selectedIndex;

  AppState copyWith({int? selectedIndex}) {
    return AppState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}
