part of 'app_bloc.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

@Deprecated('Use SettingsBloc events instead')
class AppThemeChanged extends AppEvent {
  //
  // ignore: deprecated_consistency
  const AppThemeChanged();
}

class AppUserChanged extends AppEvent {
  const AppUserChanged(this.user);

  final User? user;

  @override
  List<Object?> get props => [user];
}

/// {@template app_settings_refreshed}
/// Internal event to trigger reloading of settings within AppBloc.
/// Added when user changes or upon explicit request.
/// {@endtemplate}
class AppSettingsRefreshed extends AppEvent {
  /// {@macro app_settings_refreshed}
  const AppSettingsRefreshed();
}

/// {@template app_logout_requested}
/// Event to request user logout.
/// {@endtemplate}
class AppLogoutRequested extends AppEvent {
  /// {@macro app_logout_requested}
  const AppLogoutRequested();
}

/// {@template app_theme_mode_changed}
/// Event to change the application's theme mode.
/// {@endtemplate}
class AppThemeModeChanged extends AppEvent {
  /// {@macro app_theme_mode_changed}
  const AppThemeModeChanged(this.themeMode);

  final ThemeMode themeMode;

  @override
  List<Object?> get props => [themeMode];
}

/// {@template app_flex_scheme_changed}
/// Event to change the application's FlexColorScheme.
/// {@endtemplate}
class AppFlexSchemeChanged extends AppEvent {
  /// {@macro app_flex_scheme_changed}
  const AppFlexSchemeChanged(this.flexScheme);

  final FlexScheme flexScheme;

  @override
  List<Object?> get props => [flexScheme];
}

/// {@template app_font_family_changed}
/// Event to change the application's font family.
/// {@endtemplate}
class AppFontFamilyChanged extends AppEvent {
  /// {@macro app_font_family_changed}
  const AppFontFamilyChanged(this.fontFamily);

  final String? fontFamily;

  @override
  List<Object?> get props => [fontFamily];
}

/// {@template app_text_scale_factor_changed}
/// Event to change the application's text scale factor.
/// {@endtemplate}
class AppTextScaleFactorChanged extends AppEvent {
  /// {@macro app_text_scale_factor_changed}
  const AppTextScaleFactorChanged(this.appTextScaleFactor);

  final AppTextScaleFactor appTextScaleFactor;

  @override
  List<Object?> get props => [appTextScaleFactor];
}

/// {@template app_config_fetch_requested}
/// Event to trigger fetching of the global AppConfig.
/// {@endtemplate}
class AppConfigFetchRequested extends AppEvent {
  /// {@macro app_config_fetch_requested}
  const AppConfigFetchRequested();
}

/// {@template app_user_account_action_shown}
/// Event triggered when an AccountAction has been shown to the user,
/// prompting an update to their `lastAccountActionShownAt` timestamp.
/// {@endtemplate}
class AppUserAccountActionShown extends AppEvent {
  /// {@macro app_user_account_action_shown}
  const AppUserAccountActionShown({required this.userId});

  final String userId;

  @override
  List<Object> get props => [userId];
}
