part of 'entity_details_bloc.dart';

abstract class EntityDetailsEvent extends Equatable {
  const EntityDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load entity details and initial headlines.
/// Can be triggered by passing an ID and type, or the full entity.
class EntityDetailsLoadRequested extends EntityDetailsEvent {
  const EntityDetailsLoadRequested({
    this.entityId,
    this.entityType,
    this.entity,
  }) : assert(
         (entityId != null && entityType != null) || entity != null,
         'Either entityId/entityType or entity must be provided.',
       );

  final String? entityId;
  final EntityType? entityType;
  final dynamic entity;

  @override
  List<Object?> get props => [entityId, entityType, entity];
}

/// Event to toggle the follow status of the current entity.
class EntityDetailsToggleFollowRequested extends EntityDetailsEvent {
  const EntityDetailsToggleFollowRequested();
}

/// Event to load more headlines for pagination.
class EntityDetailsLoadMoreHeadlinesRequested extends EntityDetailsEvent {
  const EntityDetailsLoadMoreHeadlinesRequested();
}

/// Internal event to notify the BLoC that user preferences have changed.
class _EntityDetailsUserPreferencesChanged extends EntityDetailsEvent {
  const _EntityDetailsUserPreferencesChanged(this.preferences);

  final UserContentPreferences preferences;

  @override
  List<Object?> get props => [preferences];
}
