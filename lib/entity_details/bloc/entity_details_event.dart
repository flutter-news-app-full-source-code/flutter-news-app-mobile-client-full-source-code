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
  });

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

/// Event to toggle the "follow" status of the currently loaded entity,
/// including a limit check.
final class EntityDetailsToggleFollowRequestedWithLimitCheck extends EntityDetailsEvent {
  /// Creates a [EntityDetailsToggleFollowRequestedWithLimitCheck] event.
  const EntityDetailsToggleFollowRequestedWithLimitCheck();
}


/// Event to load the next page of headlines for the current entity.
class EntityDetailsLoadMoreHeadlinesRequested extends EntityDetailsEvent {
  const EntityDetailsLoadMoreHeadlinesRequested({required this.adThemeStyle});

  /// The current ad theme style, required for ad injection.
  final AdThemeStyle adThemeStyle;

  @override
  List<Object> get props => [adThemeStyle];
}
