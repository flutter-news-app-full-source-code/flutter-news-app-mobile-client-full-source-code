part of 'app_bloc.dart';

sealed class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object> get props => [];
}

final class AppNavigationIndexChanged extends AppEvent {
  const AppNavigationIndexChanged(this.context, this.index);

  final BuildContext context;
  final int index;

  @override
  List<Object> get props => [index];
}

final class AppThemeChanged extends AppEvent {
  const AppThemeChanged();
}

/// {@template app_user_changed}
/// Event triggered when the user's authentication state changes.
/// {@endtemplate}
final class AppUserChanged extends AppEvent {
  /// {@macro app_user_changed}
  const AppUserChanged(this.user);

  /// The updated [User] object.
  final User user;

  @override
  List<Object> get props => [user];
}
