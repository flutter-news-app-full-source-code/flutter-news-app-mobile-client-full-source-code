part of 'entity_details_bloc.dart';

/// Status for the overall entity details page.
enum EntityDetailsStatus {
  /// The initial state.
  initial,

  /// The entity and its initial headlines are being loaded.
  loading,

  /// The entity and headlines have been successfully loaded.
  success,

  /// More headlines are being loaded for pagination.
  loadingMore,

  /// The page failed to load the entity or initial headlines.
  failure,

  /// A subsequent operation (like pagination) failed.
  /// The UI can still display existing data.
  partialFailure,
}

/// {@template entity_details_state}
/// The state for the entity details feature.
///
/// Contains the loaded entity, its associated feed items, and the
/// current status of data fetching operations.
/// {@endtemplate}
class EntityDetailsState extends Equatable {
  /// {@macro entity_details_state}
  const EntityDetailsState({
    this.status = EntityDetailsStatus.initial,
    this.contentType,
    this.entity,
    this.isFollowing = false,
    this.feedItems = const [],
    this.hasMoreHeadlines = true,
    this.headlinesCursor,
    this.exception,
  });

  /// The overall status of the page.
  final EntityDetailsStatus status;

  /// The type of the entity being displayed (e.g., topic, source).
  final ContentType? contentType;

  /// The entity being displayed (e.g., a [Topic] or [Source] object).
  final FeedItem? entity;

  /// Whether the current user is following the displayed entity.
  final bool isFollowing;

  /// The list of feed items (headlines, ads, etc.) to display.
  final List<FeedItem> feedItems;

  /// Whether there are more headlines to fetch for pagination.
  final bool hasMoreHeadlines;

  /// The cursor for paginating through headlines.
  final String? headlinesCursor;

  /// The exception that occurred, if any.
  final HtHttpException? exception;

  /// Creates a copy of the current state with updated values.
  EntityDetailsState copyWith({
    EntityDetailsStatus? status,
    ContentType? contentType,
    FeedItem? entity,
    bool? isFollowing,
    List<FeedItem>? feedItems,
    bool? hasMoreHeadlines,
    String? headlinesCursor,
    HtHttpException? exception,
    bool clearEntity = false,
    bool clearHeadlinesCursor = false,
    bool clearException = false,
  }) {
    return EntityDetailsState(
      status: status ?? this.status,
      contentType: contentType ?? this.contentType,
      entity: clearEntity ? null : entity ?? this.entity,
      isFollowing: isFollowing ?? this.isFollowing,
      feedItems: feedItems ?? this.feedItems,
      hasMoreHeadlines: hasMoreHeadlines ?? this.hasMoreHeadlines,
      headlinesCursor: clearHeadlinesCursor
          ? null
          : headlinesCursor ?? this.headlinesCursor,
      exception: clearException ? null : exception ?? this.exception,
    );
  }

  @override
  List<Object?> get props => [
    status,
    contentType,
    entity,
    isFollowing,
    feedItems,
    hasMoreHeadlines,
    headlinesCursor,
    exception,
  ];
}
