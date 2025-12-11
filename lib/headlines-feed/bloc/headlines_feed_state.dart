part of 'headlines_feed_bloc.dart';

enum HeadlinesFeedStatus { initial, loading, success, failure, loadingMore }

class HeadlinesFeedState extends Equatable {
  const HeadlinesFeedState({
    this.status = HeadlinesFeedStatus.initial,
    this.feedItems = const [],
    this.hasMore = true,
    this.cursor,
    this.filter = const HeadlineFilterCriteria(
      topics: [],
      sources: [],
      countries: [],
    ),
    this.savedHeadlineFilters = const [],
    this.activeFilterId = 'all',
    this.error,
    this.navigationUrl,
    this.navigationArguments,
    this.adThemeStyle,
    this.engagementsMap = const {},
    this.limitationStatus = LimitationStatus.allowed,
    this.limitedAction,
  });

  final HeadlinesFeedStatus status;

  /// The list of feed items, which can include headlines, ads, and decorators.
  final List<FeedItem> feedItems;
  final bool hasMore;
  final String? cursor;
  final HeadlineFilterCriteria filter;
  final HttpException? error;

  /// A URL to navigate to, typically set when a call-to-action is tapped.
  /// The UI should consume this and then clear it.
  final String? navigationUrl;

  /// Optional arguments to pass during navigation. This is used to pass
  /// complex objects like the `Headline` model to the engagement sheet.
  final Object? navigationArguments;

  /// The list of saved headlines filters available to the user.
  /// This is synced from the [AppBloc].
  final List<SavedHeadlineFilter> savedHeadlineFilters;

  /// The ID of the currently active filter.
  /// Can be a [SavedHeadlineFilter.id], 'all', or 'custom'.
  final String? activeFilterId;

  /// The current ad theme style.
  final AdThemeStyle? adThemeStyle;

  /// A map of engagements, where the key is the entity ID (e.g., headline ID)
  /// and the value is the list of engagements for that entity.
  final Map<String, List<Engagement>> engagementsMap;

  /// The status of the most recent content limitation check.
  final LimitationStatus limitationStatus;

  /// The specific action that was limited, if any.
  final ContentAction? limitedAction;

  HeadlinesFeedState copyWith({
    HeadlinesFeedStatus? status,
    List<FeedItem>? feedItems,
    bool? hasMore,
    String? cursor,
    HeadlineFilterCriteria? filter,
    List<SavedHeadlineFilter>? savedHeadlineFilters,
    String? activeFilterId,
    HttpException? error,
    String? navigationUrl,
    bool clearCursor = false,
    Object? navigationArguments,
    bool clearActiveFilterId = false,
    bool clearNavigationUrl = false,
    AdThemeStyle? adThemeStyle,
    bool clearNavigationArguments = false,
    Map<String, List<Engagement>>? engagementsMap,
    LimitationStatus? limitationStatus,
    ContentAction? limitedAction,
    bool clearLimitedAction = false,
  }) {
    return HeadlinesFeedState(
      status: status ?? this.status,
      feedItems: feedItems ?? this.feedItems,
      hasMore: hasMore ?? this.hasMore,
      cursor: clearCursor ? null : cursor ?? this.cursor,
      filter: filter ?? this.filter,
      savedHeadlineFilters: savedHeadlineFilters ?? this.savedHeadlineFilters,
      activeFilterId: clearActiveFilterId
          ? null
          : activeFilterId ?? this.activeFilterId,
      error: error ?? this.error,
      navigationUrl: clearNavigationUrl
          ? null
          : navigationUrl ?? this.navigationUrl,
      navigationArguments: clearNavigationArguments
          ? null
          : navigationArguments ?? this.navigationArguments,
      adThemeStyle: adThemeStyle ?? this.adThemeStyle,
      engagementsMap: engagementsMap ?? this.engagementsMap,
      limitationStatus: limitationStatus ?? this.limitationStatus,
      limitedAction: clearLimitedAction
          ? null
          : limitedAction ?? this.limitedAction,
    );
  }

  @override
  List<Object?> get props => [
    status,
    feedItems,
    hasMore,
    cursor,
    filter,
    savedHeadlineFilters,
    activeFilterId,
    error,
    navigationUrl,
    navigationArguments,
    adThemeStyle,
    engagementsMap,
    limitationStatus,
    limitedAction,
  ];
}
