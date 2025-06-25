part of 'entity_details_bloc.dart';

/// Status for the overall entity details page.
enum EntityDetailsStatus { initial, loading, success, failure }

/// Status for fetching headlines within the entity details page.
enum EntityHeadlinesStatus { initial, loadingMore, success, failure }

class EntityDetailsState extends Equatable {
  const EntityDetailsState({
    this.status = EntityDetailsStatus.initial,
    this.entityType,
    this.entity,
    this.isFollowing = false,
    this.feedItems = const [],
    this.headlinesStatus = EntityHeadlinesStatus.initial,
    this.hasMoreHeadlines = true,
    this.headlinesCursor,
    this.errorMessage,
  });

  final EntityDetailsStatus status;
  final EntityType? entityType;
  final dynamic entity;
  final bool isFollowing;
  final List<FeedItem> feedItems;
  final EntityHeadlinesStatus headlinesStatus;
  final bool hasMoreHeadlines;
  final String? headlinesCursor;
  final String? errorMessage;

  EntityDetailsState copyWith({
    EntityDetailsStatus? status,
    EntityType? entityType,
    dynamic entity,
    bool? isFollowing,
    List<FeedItem>? feedItems,
    EntityHeadlinesStatus? headlinesStatus,
    bool? hasMoreHeadlines,
    String? headlinesCursor,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool clearEntity = false,
    bool clearHeadlinesCursor = false,
  }) {
    return EntityDetailsState(
      status: status ?? this.status,
      entityType: entityType ?? this.entityType,
      entity: clearEntity ? null : entity ?? this.entity,
      isFollowing: isFollowing ?? this.isFollowing,
      feedItems: feedItems ?? this.feedItems,
      headlinesStatus: headlinesStatus ?? this.headlinesStatus,
      hasMoreHeadlines: hasMoreHeadlines ?? this.hasMoreHeadlines,
      headlinesCursor: // This cursor is for fetching original headlines
      clearHeadlinesCursor
          ? null
          : headlinesCursor ?? this.headlinesCursor,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    entityType,
    entity,
    isFollowing,
    feedItems,
    headlinesStatus,
    hasMoreHeadlines,
    headlinesCursor,
    errorMessage,
  ];
}
