part of 'settings_bloc.dart';

/// Enum representing the possible statuses of the settings feature.
enum SettingsStatus {
  /// Initial state, before any loading attempt.
  initial,

  /// Settings are currently being loaded from the repository.
  loading,

  /// Settings have been successfully loaded or updated.
  success,

  /// An error occurred while loading or updating settings.
  failure,
}

/// {@template settings_state}
/// Represents the state of the settings feature, including loading status
/// and the current values of all user-configurable settings.
/// {@endtemplate}
class SettingsState extends Equatable {
  /// {@macro settings_state}
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.appSettings = const AppSettings( // Default value
      appFontSize: FontSize.medium,
      appFontType: AppFontType.roboto,
    ),
    this.articleSettings = const ArticleSettings( // Default value
      articleFontSize: FontSize.medium,
    ),
    this.themeSettings = const ThemeSettings( // Default value
      themeMode: AppThemeMode.system,
      themeName: AppThemeName.grey,
    ),
    this.feedSettings = const FeedSettings( // Default value
      feedListTileType: FeedListTileType.imageStart,
    ),
    this.notificationSettings = const NotificationSettings(enabled: false), // Default
    this.error,
  });

  /// The current status of loading/updating settings.
  final SettingsStatus status;

  /// Current application-wide settings (font size, font type).
  final AppSettings appSettings;

  /// Current settings specific to article display (font size).
  final ArticleSettings articleSettings;

  /// Current theme settings (mode, name/color scheme).
  final ThemeSettings themeSettings;

  /// Current settings for the news feed display (tile type).
  final FeedSettings feedSettings;

  /// Current notification settings (enabled, followed items).
  final NotificationSettings notificationSettings;

  /// An optional error object if the status is [SettingsStatus.failure].
  final Object? error;

  /// Creates a copy of the current state with updated values.
  SettingsState copyWith({
    SettingsStatus? status,
    AppSettings? appSettings,
    ArticleSettings? articleSettings,
    ThemeSettings? themeSettings,
    FeedSettings? feedSettings,
    NotificationSettings? notificationSettings,
    Object? error,
    bool clearError = false, // Flag to explicitly clear error
  }) {
    return SettingsState(
      status: status ?? this.status,
      appSettings: appSettings ?? this.appSettings,
      articleSettings: articleSettings ?? this.articleSettings,
      themeSettings: themeSettings ?? this.themeSettings,
      feedSettings: feedSettings ?? this.feedSettings,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        appSettings,
        articleSettings,
        themeSettings,
        feedSettings,
        notificationSettings,
        error,
      ];
}
