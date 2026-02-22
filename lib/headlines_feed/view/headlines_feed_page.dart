import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_placeholder.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/feed_ad_loader_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/models/decorator_placeholder.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/widgets/feed_decorator_loader_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/widgets/feed_sliver_app_bar.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/widgets/saved_filters_bar.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/services/feed_decorator_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/services/feed_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/constants/app_layout.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/shared.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/view/comments_bottom_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template headlines_feed_view}
/// The main page for the headlines feed, responsible for providing the
/// [HeadlinesFeedBloc] to its child widget, [_HeadlinesFeedView].
///
/// This separation ensures that the BLoC is created only once and is available
/// to all descendant widgets, including any routes that are pushed on top of
/// this page (e.g., the filter page).
/// {@endtemplate}
class HeadlinesFeedPage extends StatelessWidget {
  /// {@macro headlines_feed_view}
  const HeadlinesFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HeadlinesFeedView();
  }
}

/// The core view widget for the headlines feed.
class _HeadlinesFeedView extends StatefulWidget {
  const _HeadlinesFeedView();

  @override
  State<_HeadlinesFeedView> createState() => __HeadlinesFeedViewState();
}

/// State for the [_HeadlinesFeedView]. Manages the [ScrollController] for
/// pagination and listens to scroll events.
class __HeadlinesFeedViewState extends State<_HeadlinesFeedView>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  bool _isInitialFetchDispatched = false;

  @override
  void initState() {
    super.initState();
    // Add listener to trigger pagination when scrolling near the bottom.
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The initial data fetch for the feed is explicitly triggered here instead
    // of in `initState` because it requires access to the `Theme` via
    // `context`, which is only safe to do after `initState` has completed.
    // A flag ensures this logic runs only once for the widget's lifecycle.
    if (!_isInitialFetchDispatched) {
      context.read<HeadlinesFeedBloc>().add(
        HeadlinesFeedStarted(
          adThemeStyle: AdThemeStyle.fromTheme(Theme.of(context)),
        ),
      );
      _isInitialFetchDispatched = true;
    }
  }

  @override
  void dispose() {
    // Remove listener and dispose the controller to prevent memory leaks.
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Callback function for scroll events.
  ///
  /// Checks if the user has scrolled near the bottom of the list and if there
  /// are more headlines to fetch. If so, dispatches a
  /// [HeadlinesFeedFetchRequested] event to the BLoC.
  void _onScroll() {
    final state = context.read<HeadlinesFeedBloc>().state;
    if (_isBottom &&
        state.hasMore &&
        state.status != HeadlinesFeedStatus.loadingMore) {
      context.read<HeadlinesFeedBloc>().add(
        HeadlinesFeedFetchRequested(
          adThemeStyle: AdThemeStyle.fromTheme(Theme.of(context)),
        ),
      );
    }
  }

  /// Checks if the current scroll position is near the bottom of the list.
  ///
  /// Returns `true` if the scroll offset is within 98% of the maximum scroll
  /// extent, `false` otherwise.
  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Trigger slightly before reaching the absolute end for smoother loading.
    return currentScroll >= (maxScroll * 0.98);
  }

  @override
  // Keep the state alive when switching tabs in the bottom navigation.
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // The call to super.build(context) must be the first statement in the build
    // method when using AutomaticKeepAliveClientMixin.
    super.build(context);
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    return BlocListener<HeadlinesFeedBloc, HeadlinesFeedState>(
      listenWhen: (previous, current) =>
          previous.navigationUrl != current.navigationUrl ||
          previous.limitationStatus != current.limitationStatus,
      listener: (context, state) {
        if (state.limitationStatus != LimitationStatus.allowed) {
          showContentLimitationBottomSheet(
            context: context,
            status: state.limitationStatus,
            action: state.limitedAction ?? ContentAction.reactToContent,
          );
          return;
        }

        // This listener handles navigation actions triggered by the BLoC.
        if (state.navigationUrl != null) {
          final navArgs = state.navigationArguments;
          if (navArgs is Headline) {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => CommentsBottomSheet(headlineId: navArgs.id),
            );
          } else {
            // Handle simple URL navigation for call-to-actions.
            context.push(state.navigationUrl!);
          }
          // Notify the BLoC that navigation has been handled to clear the URL.
          context.read<HeadlinesFeedBloc>().add(NavigationHandled());
        }
      },
      child: Scaffold(
        body: BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
          builder: (context, state) {
            // Access the AppBloc to check for remoteConfig availability.
            final appBlocState = context.watch<AppBloc>().state;

            // If remoteConfig is not yet loaded, show a loading indicator.
            // This handles the brief period after authentication but before
            // the remote config is fetched, preventing null access errors.
            if (appBlocState.remoteConfig == null) {
              return LoadingStateWidget(
                icon: Icons.settings_applications_outlined,
                headline: l10n.headlinesFeedLoadingHeadline,
                subheadline: l10n.pleaseWait,
              );
            }

            if (state.status == HeadlinesFeedStatus.initial ||
                (state.status == HeadlinesFeedStatus.loading &&
                    state.feedItems.isEmpty)) {
              return LoadingStateWidget(
                icon: Icons.newspaper,
                headline: l10n.headlinesFeedLoadingHeadline,
                subheadline: l10n.headlinesFeedLoadingSubheadline,
              );
            }

            if (state.status == HeadlinesFeedStatus.failure &&
                state.feedItems.isEmpty) {
              return FailureStateWidget(
                exception: state.error ?? UnknownException(l10n.unknownError),
                onRetry: () => context.read<HeadlinesFeedBloc>().add(
                  HeadlinesFeedRefreshRequested(
                    adThemeStyle: AdThemeStyle.fromTheme(theme),
                  ),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.maxContentWidth,
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<HeadlinesFeedBloc>().add(
                      HeadlinesFeedRefreshRequested(
                        adThemeStyle: AdThemeStyle.fromTheme(theme),
                      ),
                    );
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      FeedSliverAppBar(
                        bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(
                            AppLayout.savedFiltersBarHeight,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: SavedFiltersBar(),
                          ),
                        ),
                      ),
                      // Conditionally render either the feed content or an empty
                      // state message within the scroll view. This ensures the
                      // app bar and filter bar are always visible for a better
                      // and more consistent user experience, allowing users to
                      // easily modify filters even when there are no results.
                      if (state.feedItems.isEmpty &&
                          state.status != HeadlinesFeedStatus.loading)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InitialStateWidget(
                                  icon: Icons.search_off,
                                  headline:
                                      l10n.headlinesFeedEmptyFilteredHeadline,
                                  subheadline: l10n
                                      .headlinesFeedEmptyFilteredSubheadline,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                ElevatedButton(
                                  onPressed: () =>
                                      context.read<HeadlinesFeedBloc>().add(
                                        HeadlinesFeedFiltersCleared(
                                          adThemeStyle: AdThemeStyle.fromTheme(
                                            theme,
                                          ),
                                        ),
                                      ),
                                  child: Text(
                                    l10n.headlinesFeedClearFiltersButton,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        _buildSliverList(state, theme),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverList(HeadlinesFeedState state, ThemeData theme) {
    return SliverPadding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xxl,
      ),
      sliver: SliverList.separated(
        itemCount: state.hasMore
            ? state.feedItems.length + 1
            : state.feedItems.length,
        separatorBuilder: (context, index) {
          if (index >= state.feedItems.length - 1) {
            return const SizedBox.shrink();
          }
          final currentItem = state.feedItems[index];
          final nextItem = state.feedItems[index + 1];

          if (currentItem is DecoratorPlaceholder ||
              currentItem is! Headline ||
              nextItem is! Headline) {
            return const SizedBox(height: AppSpacing.md);
          }
          return const SizedBox(height: AppSpacing.sm);
        },
        itemBuilder: (context, index) {
          if (index >= state.feedItems.length) {
            return _buildLoadingIndicator(state);
          }
          final item = state.feedItems[index];
          return _buildFeedItem(context, item, state, theme);
        },
      ),
    );
  }

  Widget _buildFeedItem(
    BuildContext context,
    FeedItem item,
    HeadlinesFeedState state,
    ThemeData theme,
  ) {
    if (item is Headline) {
      final imageStyle = context.watch<AppBloc>().state.feedItemImageStyle;

      switch (imageStyle) {
        case FeedItemImageStyle.hidden:
          return HeadlineTileTextOnly(
            headline: item,
            onHeadlineTap: () =>
                HeadlineTapHandler.handleHeadlineTap(context, item),
          );
        case FeedItemImageStyle.smallThumbnail:
          return HeadlineTileImageStart(
            headline: item,
            onHeadlineTap: () =>
                HeadlineTapHandler.handleHeadlineTap(context, item),
          );
        case FeedItemImageStyle.largeThumbnail:
          return HeadlineTileImageTop(
            headline: item,
            onHeadlineTap: () =>
                HeadlineTapHandler.handleHeadlineTap(context, item),
          );
      }
    } else if (item is AdPlaceholder) {
      final remoteConfig = context.read<AppBloc>().state.remoteConfig;
      if (remoteConfig?.features.ads == null) {
        return const SizedBox.shrink();
      }
      return FeedAdLoaderWidget(
        key: ValueKey(item.id),
        contextKey: state.activeFilterId!,
        adPlaceholder: item,
        adThemeStyle: AdThemeStyle.fromTheme(theme),
        remoteConfig: remoteConfig!,
      );
    } else if (item is DecoratorPlaceholder) {
      return FeedDecoratorLoaderWidget(key: ValueKey(item.id));
    }
    return const SizedBox.shrink();
  }

  Widget _buildLoadingIndicator(HeadlinesFeedState state) {
    return state.status == HeadlinesFeedStatus.loadingMore
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        : const SizedBox.shrink();
  }
}
