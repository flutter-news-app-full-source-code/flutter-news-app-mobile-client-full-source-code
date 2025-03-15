part of 'app_bloc.dart';

@immutable
sealed class AppEvent {}

final class AppNavigationIndexChanged extends AppEvent {
  AppNavigationIndexChanged({required this.index, required this.context});

  final int index;
  final BuildContext context;
}

final class AppThemeChanged extends AppEvent {}
