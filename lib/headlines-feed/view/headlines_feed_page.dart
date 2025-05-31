//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// Import Category
// Import Country
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/app/bloc/app_bloc.dart'; // Added to access settings
import 'package:ht_main/headlines-feed/bloc/headlines_feed_bloc.dart';
// HeadlineItemWidget import removed
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/shared.dart';
import 'package:ht_shared/ht_shared.dart'
    show Headline, HeadlineImageStyle; // Added HeadlineImageStyle

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
    if (_isBottom && state is HeadlinesFeedLoaded) {
      if (state.hasMore) {
        // Request the next page of headlines
        context.read<HeadlinesFeedBloc>().add(
          HeadlinesFeedFetchRequested(cursor: state.cursor), // Pass cursor
        );
      }
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
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.headlinesFeedAppBarTitle,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: l10n.notificationsTooltip, // Add tooltip for accessibility
            onPressed: () {
              context.goNamed(
                Routes.notificationsName,
              ); // Ensure correct route name
            },
          ),
          BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
            builder: (context, state) {
              var isFilterApplied = false;
              if (state is HeadlinesFeedLoaded) {
                // Check if any filter list is non-null and not empty
                isFilterApplied =
                    (state.filter.categories?.isNotEmpty ?? false) ||
                    (state.filter.sources?.isNotEmpty ?? false);
                // (state.filter.eventCountries?.isNotEmpty ?? false); // Removed
              }
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    tooltip: l10n.headlinesFeedFilterTooltip,
                    onPressed: () {
                      // Navigate to the filter page route
                      final headlinesFeedBloc =
                          context.read<HeadlinesFeedBloc>();
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
        buildWhen:
            (previous, current) => current is! HeadlinesFeedLoadingSilently,
        builder: (context, state) {
          switch (state) {
            case HeadlinesFeedInitial(): // Handle initial state
            case HeadlinesFeedLoading():
              // Display full-screen loading indicator
              return LoadingStateWidget(
                icon: Icons.newspaper, // Use a relevant icon
                headline: l10n.headlinesFeedLoadingHeadline,
                subheadline: l10n.headlinesFeedLoadingSubheadline,
              );

            case HeadlinesFeedLoadingSilently():
              // This state is handled by buildWhen, should not be reached here.
              // Return an empty container as a fallback.
              return const SizedBox.shrink();

            case HeadlinesFeedLoaded():
              if (state.headlines.isEmpty) {
                // If the list is empty after filters, show a message
                // with a "Clear Filters" button using FailureStateWidget.
                return FailureStateWidget(
                  message:
                      '${l10n.headlinesFeedEmptyFilteredHeadline}\n${l10n.headlinesFeedEmptyFilteredSubheadline}',
                  onRetry: () {
                    // This will be our "Clear Filters" action
                    context.read<HeadlinesFeedBloc>().add(
                      HeadlinesFeedFiltersCleared(),
                    );
                  },
                  retryButtonText:
                      l10n.headlinesFeedClearFiltersButton, // New l10n string
                );
              }
              // Display the list of headlines with pull-to-refresh
              return RefreshIndicator(
                onRefresh: () async {
                  // Dispatch refresh event to the BLoC
                  context.read<HeadlinesFeedBloc>().add(
                    HeadlinesFeedRefreshRequested(),
                  );
                  // Note: BLoC handles emitting loading state during refresh
                },
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                    bottom:
                        AppSpacing.xxl, // Ensure space below last item/loader
                  ),
                  itemCount:
                      state.hasMore
                          ? state.headlines.length +
                              1 // +1 for loading indicator
                          : state.headlines.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(
                        height: AppSpacing.lg,
                      ), // Consistent spacing
                  itemBuilder: (context, index) {
                    // Check if it's the loading indicator item
                    if (index >= state.headlines.length) {
                      // Show loading indicator at the bottom if more items exist
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    // Otherwise, build the headline item
                    final headline = state.headlines[index];
                    final imageStyle =
                        context
                            .watch<AppBloc>()
                            .state
                            .settings
                            .feedPreferences
                            .headlineImageStyle;

                    Widget tile;
                    switch (imageStyle) {
                      case HeadlineImageStyle.hidden:
                        tile = HeadlineTileTextOnly(
                          headline: headline,
                          onHeadlineTap:
                              () => context.goNamed(
                                Routes.articleDetailsName,
                                pathParameters: {'id': headline.id},
                                extra: headline,
                              ),
                        );
                      case HeadlineImageStyle.smallThumbnail:
                        tile = HeadlineTileImageStart(
                          headline: headline,
                          onHeadlineTap:
                              () => context.goNamed(
                                Routes.articleDetailsName,
                                pathParameters: {'id': headline.id},
                                extra: headline,
                              ),
                        );
                      case HeadlineImageStyle.largeThumbnail:
                        tile = HeadlineTileImageTop(
                          headline: headline,
                          onHeadlineTap:
                              () => context.goNamed(
                                Routes.articleDetailsName,
                                pathParameters: {'id': headline.id},
                                extra: headline,
                              ),
                        );
                    }
                    return tile;
                  },
                ),
              );

            case HeadlinesFeedError():
              // Display error message with a retry button
              return FailureStateWidget(
                message: state.message,
                onRetry: () {
                  // Dispatch refresh event on retry
                  context.read<HeadlinesFeedBloc>().add(
                    HeadlinesFeedRefreshRequested(),
                  );
                },
              );
          }
        },
      ),
    );
  }
}
