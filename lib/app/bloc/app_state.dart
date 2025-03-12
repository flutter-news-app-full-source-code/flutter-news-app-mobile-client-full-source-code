part of 'app_bloc.dart';

class AppState extends Equatable {
  const AppState({this.selectedBottomNavigationIndex = 0});
  final int selectedBottomNavigationIndex;

  AppState copyWith({int? selectedBottomNavigationIndex}) {
    return AppState(
      selectedBottomNavigationIndex:
          selectedBottomNavigationIndex ?? this.selectedBottomNavigationIndex,
    );
  }

  @override
  List<Object?> get props => [selectedBottomNavigationIndex];
}
