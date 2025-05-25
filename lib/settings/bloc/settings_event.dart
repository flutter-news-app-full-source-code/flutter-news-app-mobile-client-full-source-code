part of 'settings_bloc.dart';

//
// ignore_for_file: avoid_positional_boolean_parameters

// Import models and enums from ht_shared

/// {@template settings_event}
/// Base class for all events related to the settings feature.
/// {@endtemplate}
abstract class SettingsEvent extends Equatable {
  /// {@macro settings_event}
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// {@template settings_load_requested}
/// Event added when the settings page is entered to load initial settings.
/// {@endtemplate}
class SettingsLoadRequested extends SettingsEvent {
  /// {@macro settings_load_requested}
  const SettingsLoadRequested();
}

// --- Appearance Settings Events ---

/// {@template settings_app_theme_mode_changed}
/// Event added when the user changes the app theme mode (light/dark/system).
/// {@endtemplate}
class SettingsAppThemeModeChanged extends SettingsEvent {
  /// {@macro settings_app_theme_mode_changed}
  const SettingsAppThemeModeChanged(this.themeMode);

  /// The newly selected theme mode.
  final AppBaseTheme themeMode; // Use AppBaseTheme from ht_shared

  @override
  List<Object?> get props => [themeMode];
}

/// {@template settings_app_theme_name_changed}
/// Event added when the user changes the app theme name (color scheme).
/// {@endtemplate}
class SettingsAppThemeNameChanged extends SettingsEvent {
  /// {@macro settings_app_theme_name_changed}
  const SettingsAppThemeNameChanged(this.themeName);

  /// The newly selected theme name.
  final AppAccentTheme themeName; // Use AppAccentTheme from ht_shared

  @override
  List<Object?> get props => [themeName];
}

/// {@template settings_app_font_size_changed}
/// Event added when the user changes the global app font size.
/// {@endtemplate}
class SettingsAppFontSizeChanged extends SettingsEvent {
  /// {@macro settings_app_font_size_changed}
  const SettingsAppFontSizeChanged(this.fontSize);

  /// The newly selected font size.
  final AppTextScaleFactor fontSize; // Use AppTextScaleFactor from ht_shared

  @override
  List<Object?> get props => [fontSize];
}

/// {@template settings_app_font_type_changed}
/// Event added when the user changes the global app font type.
/// {@endtemplate}
class SettingsAppFontTypeChanged extends SettingsEvent {
  /// {@macro settings_app_font_type_changed}
  const SettingsAppFontTypeChanged(this.fontType);

  /// The newly selected font type.
  final String fontType; // Use String for fontFamily

  @override
  List<Object?> get props => [fontType];
}

/// {@template settings_app_font_weight_changed}
/// Event added when the user changes the global app font weight.
/// {@endtemplate}
class SettingsAppFontWeightChanged extends SettingsEvent {
  /// {@macro settings_app_font_weight_changed}
  const SettingsAppFontWeightChanged(this.fontWeight);

  /// The newly selected font weight.
  final AppFontWeight fontWeight; // Use AppFontWeight from ht_shared

  @override
  List<Object?> get props => [fontWeight];
}

// --- Feed Settings Events ---

/// {@template settings_feed_tile_type_changed}
/// Event added when the user changes the feed list tile type.
/// {@endtemplate}
class SettingsFeedTileTypeChanged extends SettingsEvent {
  /// {@macro settings_feed_tile_type_changed}
  const SettingsFeedTileTypeChanged(this.tileType);

  /// The newly selected feed list tile type.
  // Note: This event might need to be split into density and image style changes.
  final HeadlineImageStyle tileType; // Use HeadlineImageStyle from ht_shared

  @override
  List<Object?> get props => [tileType];
}

// --- Notification Settings Events ---

/// {@template settings_notifications_enabled_changed}
/// Event added when the user toggles the global notification setting.
/// {@endtemplate}
class SettingsNotificationsEnabledChanged extends SettingsEvent {
  /// {@macro settings_notifications_enabled_changed}
  const SettingsNotificationsEnabledChanged(this.enabled);

  /// The new state of the notification enabled flag.
  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

// TODO(cline): Add events for changing followed categories/sources/countries
// for notifications if needed later. Example:
// class SettingsNotificationCategoriesChanged extends SettingsEvent { ... }
