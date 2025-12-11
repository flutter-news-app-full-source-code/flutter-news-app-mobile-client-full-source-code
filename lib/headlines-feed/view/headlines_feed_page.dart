import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_placeholder.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/feed_ad_loader_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/models/decorator_placeholder.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/widgets/feed_decorator_loader_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/widgets/feed_sliver_app_bar.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/widgets/saved_filters_bar.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/view/comments_bottom_sheet.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/shared.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template headlines_feed_view}
/// The core view widget for the headlines feed.
///
/// Handles displaying the list of headlines, loading states, error states,
/// pagination (infinity scroll), and pull-to-refresh functionality. It also
/// includes the AppBar with actions for notifications and filtering.
/// {@endtemplate}
class HeadlinesFeedPage extends StatefulWidget {
  /// {@macro headlines_feed_view}
  const HeadlinesFeedPage({super.key});

  @override
  State<HeadlinesFeedPage> createState() => _HeadlinesFeedPageState();
}

/// State for the [HeadlinesFeedPage]. Manages the [ScrollController] for
/// pagination and listens to scroll events.
class _HeadlinesFeedPageState extends State<HeadlinesFeedPage>
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
          _showContentLimitationBottomSheet(
            context: context,
            status: state.limitationStatus,
            action: state.limitedAction ?? ContentAction.reactToContent,
          );
          return;
        }

        // This listener handles navigation actions triggered by the BLoC.
        if (state.navigationUrl != null) {
          if (state.navigationArguments is Headline) {
            final headline = state.navigationArguments as Headline;
            final engagements = state.engagementsMap[headline.id] ?? [];
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => CommentsBottomSheet(
                headlineId: headline.id,
                engagements: engagements,
              ),
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

            return RefreshIndicator(
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
                  const FeedSliverAppBar(
                    bottom: PreferredSize(
                      preferredSize: Size.fromHeight(52),
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
                              headline: l10n.headlinesFeedEmptyFilteredHeadline,
                              subheadline:
                                  l10n.headlinesFeedEmptyFilteredSubheadline,
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
                              child: Text(l10n.headlinesFeedClearFiltersButton),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
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
                            return state.status ==
                                    HeadlinesFeedStatus.loadingMore
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppSpacing.lg,
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          }
                          final item = state.feedItems[index];

                          if (item is Headline) {
                            final imageStyle = context
                                .watch<AppBloc>()
                                .state
                                .feedItemImageStyle;

                            switch (imageStyle) {
                              case FeedItemImageStyle.hidden:
                                return HeadlineTileTextOnly(
                                  headline: item,
                                  onHeadlineTap: () =>
                                      HeadlineTapHandler.handleHeadlineTap(
                                        context,
                                        item,
                                      ),
                                );
                              case FeedItemImageStyle.smallThumbnail:
                                return HeadlineTileImageStart(
                                  headline: item,
                                  onHeadlineTap: () =>
                                      HeadlineTapHandler.handleHeadlineTap(
                                        context,
                                        item,
                                      ),
                                );
                              case FeedItemImageStyle.largeThumbnail:
                                return HeadlineTileImageTop(
                                  headline: item,
                                  onHeadlineTap: () =>
                                      HeadlineTapHandler.handleHeadlineTap(
                                        context,
                                        item,
                                      ),
                                );
                            }
                          } else if (item is AdPlaceholder) {
                            // Access the AppBloc to get the remoteConfig for ads.
                            final remoteConfig = context
                                .read<AppBloc>()
                                .state
                                .remoteConfig;

                            // Ensure adConfig is not null before building the AdLoaderWidget.
                            if (remoteConfig?.features.ads == null) {
                              // Return an empty widget or a placeholder if adConfig is not available.
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
                            // The FeedDecoratorLoaderWidget is responsible for
                            // determining which non-ad decorator to show and
                            // managing its entire lifecycle. A ValueKey is
                            // used to ensure its state is preserved correctly.
                            return FeedDecoratorLoaderWidget(
                              key: ValueKey(item.id),
                            );
                          }
                          // Return an empty box for any other unhandled item types.
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

void _showContentLimitationBottomSheet({
  required BuildContext context,
  required LimitationStatus status,
  required ContentAction action,
}) {
  final l10n = AppLocalizations.of(context);
  final userRole = context.read<AppBloc>().state.user?.appRole;

  final content = _getBottomSheetContent(
    context: context,
    l10n: l10n,
    status: status,
    userRole: userRole,
    action: action,
  );

  showModalBottomSheet<void>(
    context: context,
    builder: (_) => ContentLimitationBottomSheet(
      title: content.title,
      body: content.body,
      buttonText: content.buttonText,
      onButtonPressed: content.onPressed,
    ),
  );
}

({String title, String body, String buttonText, VoidCallback? onPressed})
_getBottomSheetContent({
  required BuildContext context,
  required AppLocalizations l10n,
  required LimitationStatus status,
  required AppUserRole? userRole,
  required ContentAction action,
}) {
  switch (status) {
    case LimitationStatus.anonymousLimitReached:
      return (
        title: l10n.limitReachedGuestUserTitle,
        body: l10n.limitReachedGuestUserBody,
        buttonText: l10n.anonymousLimitButton,
        onPressed: () => context.goNamed(Routes.accountLinkingName),
      );
    // Other cases for standard/premium users would go here.
    case LimitationStatus.standardUserLimitReached:
    case LimitationStatus.premiumUserLimitReached:
    case LimitationStatus.allowed:
      return (
        title: l10n.limitReachedTitle,
        body: l10n.limitReachedBodyReactions,
        buttonText: l10n.gotItButton,
        onPressed: () => Navigator.of(context).pop(),
      );
  }
}
