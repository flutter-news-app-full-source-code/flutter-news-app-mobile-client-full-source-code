//
// ignore_for_file: lines_longer_than_80_chars

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_placeholder.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/feed_ad_loader_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_core/feed_core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_decorators/call_to_action_decorator_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_decorators/content_collection_decorator_widget.dart';
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
class _HeadlinesFeedPageState extends State<HeadlinesFeedPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Add listener to trigger pagination when scrolling near the bottom.
    _scrollController.addListener(_onScroll);

    // Dispatch the initial fetch event for the headlines feed.
    // This is intentionally placed in `initState` and wrapped in `addPostFrameCallback`
    // to ensure the `BuildContext` is fully initialized and stable.
    // This prevents the "Tried to listen to an InheritedWidget in a life-cycle
    // that will never be called again" error, which occurred when the event
    // was dispatched from the router's `BlocProvider` `create` method,
    // as that context could be disposed before asynchronous operations completed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HeadlinesFeedBloc>().add(
          HeadlinesFeedFetchRequested(
            adThemeStyle: AdThemeStyle.fromTheme(Theme.of(context)),
          ),
        );
      }
    });
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<HeadlinesFeedBloc, HeadlinesFeedState>(
      listener: (context, state) {
        if (state.navigationUrl != null) {
          // Use context.push for navigation to allow returning.
          // This is suitable for call-to-action flows like linking an account.
          context.push(state.navigationUrl!);
          // Notify the BLoC that navigation has been handled to clear the URL.
          context.read<HeadlinesFeedBloc>().add(NavigationHandled());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.headlinesFeedAppBarTitle,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          actions: [
            // IconButton(
            //   icon: const Icon(Icons.notifications_outlined),
            //   tooltip: l10n.notificationsTooltip,
            //   onPressed: () {
            //     context.goNamed(
            //       Routes.notificationsName,
            //     );
            //   },
            // ),
            BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
              builder: (context, state) {
                final isFilterApplied =
                    (state.filter.topics?.isNotEmpty ?? false) ||
                    (state.filter.sources?.isNotEmpty ?? false) ||
                    (state.filter.eventCountries?.isNotEmpty ?? false) ||
                    state.filter.isFromFollowedItems;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      tooltip: l10n.headlinesFeedFilterTooltip,
                      onPressed: () {
                        // Navigate to the filter page route
                        final headlinesFeedBloc = context
                            .read<HeadlinesFeedBloc>();
                        context.goNamed(
                          Routes.feedFilterName,
                          extra: headlinesFeedBloc,
                        );
                      },
                    ),
                    if (isFilterApplied)
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: Container(
                          width: AppSpacing.sm,
                          height: AppSpacing.sm,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
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
                //TODO(fulleni): l10n.
                exception:
                    state.error ??
                    const UnknownException('Failed to load headlines feed.'),
                onRetry: () => context.read<HeadlinesFeedBloc>().add(
                  HeadlinesFeedRefreshRequested(
                    adThemeStyle: AdThemeStyle.fromTheme(Theme.of(context)),
                  ),
                ),
              );
            }

            if (state.status == HeadlinesFeedStatus.success &&
                state.feedItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InitialStateWidget(
                      icon: Icons.search_off,
                      headline: l10n.headlinesFeedEmptyFilteredHeadline,
                      subheadline: l10n.headlinesFeedEmptyFilteredSubheadline,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: () => context.read<HeadlinesFeedBloc>().add(
                        HeadlinesFeedFiltersCleared(
                          adThemeStyle: AdThemeStyle.fromTheme(
                            Theme.of(context),
                          ),
                        ),
                      ),
                      child: Text(l10n.headlinesFeedClearFiltersButton),
                    ),
                  ],
                ),
              );
            }

            Future<void> onHeadlineTap(Headline headline) async {
              // Await for the ad to be shown and dismissed.
              await context
                  .read<InterstitialAdManager>()
                  .onPotentialAdTrigger();

              // Check if the widget is still in the tree before navigating.
              if (!context.mounted) return;

              // Proceed with navigation after the ad is closed.
              await context.pushNamed(
                Routes.articleDetailsName,
                pathParameters: {'id': headline.id},
                extra: headline,
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<HeadlinesFeedBloc>().add(
                  HeadlinesFeedRefreshRequested(
                    adThemeStyle: AdThemeStyle.fromTheme(Theme.of(context)),
                  ),
                );
              },
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.xxl,
                ),
                itemCount: state.hasMore
                    ? state.feedItems.length + 1
                    : state.feedItems.length,
                separatorBuilder: (context, index) {
                  if (index < state.feedItems.length - 1) {
                    final currentItem = state.feedItems[index];
                    final nextItem = state.feedItems[index + 1];
                    // Adjust spacing around any decorator or ad
                    if (currentItem is! Headline || nextItem is! Headline) {
                      return const SizedBox(height: AppSpacing.md);
                    }
                  }
                  return const SizedBox(height: AppSpacing.lg);
                },
                itemBuilder: (context, index) {
                  if (index >= state.feedItems.length) {
                    return state.status == HeadlinesFeedStatus.loadingMore
                        ? const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  }
                  final item = state.feedItems[index];

                  if (item is Headline) {
                    final imageStyle =
                        context.watch<AppBloc>().state.headlineImageStyle;
                    Widget tile;
                    switch (imageStyle) {
                      case HeadlineImageStyle.hidden:
                        tile = HeadlineTileTextOnly(
                          headline: item,
                          onHeadlineTap: () => onHeadlineTap(item),
                        );
                      case HeadlineImageStyle.smallThumbnail:
                        tile = HeadlineTileImageStart(
                          headline: item,
                          onHeadlineTap: () => onHeadlineTap(item),
                        );
                      case HeadlineImageStyle.largeThumbnail:
                        tile = HeadlineTileImageTop(
                          headline: item,
                          onHeadlineTap: () => onHeadlineTap(item),
                        );
                    }
                    return tile;
                  } else if (item is AdPlaceholder) {
                    // Access the AppBloc to get the remoteConfig for ads.
                    final adConfig = context
                        .read<AppBloc>()
                        .state
                        .remoteConfig
                        ?.adConfig;

                    // Ensure adConfig is not null before building the AdLoaderWidget.
                    if (adConfig == null) {
                      // Return an empty widget or a placeholder if adConfig is not available.
                      return const SizedBox.shrink();
                    }

                    return FeedAdLoaderWidget(
                      key: ValueKey(item.id), // Add a unique key for AdPlaceholder
                      adPlaceholder: item,
                      adThemeStyle: AdThemeStyle.fromTheme(Theme.of(context)),
                      adConfig: adConfig,
                    );
                  } else if (item is CallToActionItem) {
                    return CallToActionDecoratorWidget(
                      item: item,
                      onCallToAction: (url) {
                        context.read<HeadlinesFeedBloc>().add(
                          CallToActionTapped(url: url),
                        );
                      },
                      onDismiss: (decoratorType) {
                        context.read<HeadlinesFeedBloc>().add(
                          FeedDecoratorDismissed(
                            feedDecoratorType: decoratorType,
                          ),
                        );
                      },
                    );
                  } else if (item is ContentCollectionItem) {
                    // Access AppBloc to get the user's content preferences,
                    // which is the source of truth for followed items.
                    final appState = context.watch<AppBloc>().state;
                    final followedTopics =
                        appState.userContentPreferences?.followedTopics ?? [];
                    final followedSources =
                        appState.userContentPreferences?.followedSources ?? [];

                    final followedTopicIds =
                        followedTopics.map((t) => t.id).toList();
                    final followedSourceIds =
                        followedSources.map((s) => s.id).toList();

                    return ContentCollectionDecoratorWidget(
                      item: item,
                      followedTopicIds: followedTopicIds,
                      followedSourceIds: followedSourceIds,
                      onFollowToggle: (toggledItem) {
                        final currentUserPreferences =
                            appState.userContentPreferences;
                        if (currentUserPreferences == null) return;

                        UserContentPreferences updatedPreferences;

                        if (toggledItem is Topic) {
                          final isCurrentlyFollowing =
                              followedTopicIds.contains(toggledItem.id);
                          final newFollowedTopics =
                              List<Topic>.from(followedTopics);
                          if (isCurrentlyFollowing) {
                            newFollowedTopics
                                .removeWhere((t) => t.id == toggledItem.id);
                          } else {
                            newFollowedTopics.add(toggledItem);
                          }
                          updatedPreferences = currentUserPreferences.copyWith(
                            followedTopics: newFollowedTopics,
                          );
                        } else if (toggledItem is Source) {
                          final isCurrentlyFollowing =
                              followedSourceIds.contains(toggledItem.id);
                          final newFollowedSources =
                              List<Source>.from(followedSources);
                          if (isCurrentlyFollowing) {
                            newFollowedSources
                                .removeWhere((s) => s.id == toggledItem.id);
                          } else {
                            newFollowedSources.add(toggledItem);
                          }
                          updatedPreferences = currentUserPreferences.copyWith(
                            followedSources: newFollowedSources,
                          );
                        } else {
                          return;
                        }

                        context.read<AppBloc>().add(
                              AppUserContentPreferencesChanged(
                                preferences: updatedPreferences,
                              ),
                            );
                      },
                      onDismiss: (decoratorType) {
                        context.read<HeadlinesFeedBloc>().add(
                              FeedDecoratorDismissed(
                                feedDecoratorType: decoratorType,
                              ),
                            );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
