part of 'app_bloc.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object> get props => [];
}

@Deprecated('Use SettingsBloc events instead')
class AppThemeChanged extends AppEvent {
  const AppThemeChanged();
}

class AppUserChanged extends AppEvent {
  const AppUserChanged(this.user);

  final User user;

  @override
  List<Object> get props => [user];
}

/// {@template app_settings_refreshed}
/// Internal event to trigger reloading of settings within AppBloc.
/// Added when user changes or upon explicit request.
/// {@endtemplate}
class AppSettingsRefreshed extends AppEvent {
  /// {@macro app_settings_refreshed}
  const AppSettingsRefreshed();
}
