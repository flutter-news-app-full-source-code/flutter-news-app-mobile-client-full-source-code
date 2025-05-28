part of 'account_bloc.dart';

/// {@template account_event}
/// Base class for Account events.
/// {@endtemplate}
sealed class AccountEvent extends Equatable {
  /// {@macro account_event}
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

/// {@template _account_user_changed}
/// Internal event triggered when the authenticated user changes.
/// {@endtemplate}
final class _AccountUserChanged extends AccountEvent {
  /// {@macro _account_user_changed}
  const _AccountUserChanged({required this.user});

  /// The current authenticated user, or null if unauthenticated.
  final User? user;

  @override
  List<Object?> get props => [user];
}

/// {@template account_load_content_preferences_requested}
/// Event triggered when the user's content preferences need to be loaded.
/// {@endtemplate}
final class AccountLoadContentPreferencesRequested extends AccountEvent {
  /// {@macro account_load_content_preferences_requested}
  const AccountLoadContentPreferencesRequested({required this.userId});

  /// The ID of the user whose content preferences should be loaded.
  final String userId;

  @override
  List<Object> get props => [userId];
}

/// {@template account_follow_category_toggled}
/// Event triggered when a user toggles following a category.
/// {@endtemplate}
final class AccountFollowCategoryToggled extends AccountEvent {
  /// {@macro account_follow_category_toggled}
  const AccountFollowCategoryToggled({required this.category});

  final Category category;

  @override
  List<Object> get props => [category];
}

/// {@template account_follow_source_toggled}
/// Event triggered when a user toggles following a source.
/// {@endtemplate}
final class AccountFollowSourceToggled extends AccountEvent {
  /// {@macro account_follow_source_toggled}
  const AccountFollowSourceToggled({required this.source});

  final Source source;

  @override
  List<Object> get props => [source];
}

/// {@template account_follow_country_toggled}
/// Event triggered when a user toggles following a country.
/// {@endtemplate}
final class AccountFollowCountryToggled extends AccountEvent {
  /// {@macro account_follow_country_toggled}
  const AccountFollowCountryToggled({required this.country});

  final Country country;

  @override
  List<Object> get props => [country];
}

/// {@template account_save_headline_toggled}
/// Event triggered when a user toggles saving a headline.
/// {@endtemplate}
final class AccountSaveHeadlineToggled extends AccountEvent {
  /// {@macro account_save_headline_toggled}
  const AccountSaveHeadlineToggled({required this.headline});

  final Headline headline;

  @override
  List<Object> get props => [headline];
}
