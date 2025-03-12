part of 'app_bloc.dart';

@immutable
sealed class AppEvent {}

final class AppNavigationIndexChanged extends AppEvent {
  AppNavigationIndexChanged({required this.index});

  final int index;
}
