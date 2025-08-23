part of 'entity_details_bloc.dart';

/// Base class for all events in the entity details feature.
abstract class EntityDetailsEvent extends Equatable {
  const EntityDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load entity details and its initial list of headlines.
///
/// This can be triggered by providing either a direct [entity] object
/// or an [entityId] and its corresponding [contentType].
class EntityDetailsLoadRequested extends EntityDetailsEvent {
  const EntityDetailsLoadRequested({
    required this.adThemeStyle,
    required this.entityId,
    required this.contentType,
  }) : assert(
         entityId != null && contentType != null,
         'Both entityId and contentType must be provided.',
       );

  /// The unique ID of the entity to load.
  final String entityId;

  /// The type of the entity to load.
  final ContentType contentType;

  /// The current ad theme style, required for ad injection.
  final AdThemeStyle adThemeStyle;

  @override
  List<Object?> get props => [entityId, contentType, adThemeStyle];
}

/// Event to toggle the "follow" status of the currently loaded entity.
class EntityDetailsToggleFollowRequested extends EntityDetailsEvent {
  const EntityDetailsToggleFollowRequested();
}

/// Event to load the next page of headlines for the current entity.
class EntityDetailsLoadMoreHeadlinesRequested extends EntityDetailsEvent {
  const EntityDetailsLoadMoreHeadlinesRequested({required this.adThemeStyle});

  /// The current ad theme style, required for ad injection.
  final AdThemeStyle adThemeStyle;

  @override
  List<Object> get props => [adThemeStyle];
}

/// Internal event to notify the BLoC that the user's content preferences
/// have changed elsewhere in the app.
class _EntityDetailsUserPreferencesChanged extends EntityDetailsEvent {
  const _EntityDetailsUserPreferencesChanged(this.preferences);

  /// The updated user content preferences.
  final UserContentPreferences preferences;

  @override
  List<Object?> get props => [preferences];
}
