import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template saved_filters_bar}
/// A horizontal, scrollable bar that displays saved feed filters.
///
/// This widget allows users to quickly switch between their saved filters,
/// an "All" filter, and a "Custom" filter state. It also provides an entry
/// point to the main filter page.
///
/// On the web, it includes a fade effect at the edges to indicate that the
/// list is scrollable.
/// {@endtemplate}
class SavedFiltersBar extends StatefulWidget {
  /// {@macro saved_filters_bar}
  const SavedFiltersBar({super.key});

  @override
  State<SavedFiltersBar> createState() => _SavedFiltersBarState();
}

class _SavedFiltersBarState extends State<SavedFiltersBar> {
  final _scrollController = ScrollController();
  // A map to hold GlobalKeys for each filter chip. This allows us to find
  // the chip's context and scroll to it programmatically.
  final Map<String, GlobalKey> _chipKeys = {};

  @override
  void initState() {
    super.initState();
    // Add a listener to rebuild the widget when scrolling occurs,
    // which is necessary to update the ShaderMask's gradient.
    _scrollController.addListener(() => setState(() {}));
  }

  static const _allFilterId = 'all';
  static const _customFilterId = 'custom';
  static const _followedFilterId = 'followed';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    // The BlocListener is responsible for reacting to state changes and
    // triggering side effects, in this case, scrolling the active chip
    // into view.
    return BlocListener<HeadlinesFeedBloc, HeadlinesFeedState>(
      // Optimize the listener to only fire when the active filter ID changes.
      listenWhen: (previous, current) =>
          previous.activeFilterId != current.activeFilterId,
      listener: (context, state) {
        // We use a post-frame callback to ensure that the widget tree has been
        // rebuilt and the new active chip (especially the "Custom" one) is
        // laid out on the screen before we try to scroll to it.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final key = _chipKeys[state.activeFilterId];
          if (key?.currentContext != null) {
            Scrollable.ensureVisible(
              key!.currentContext!,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
          }
        });
      },
      child: SizedBox(
        height: 52,
        child: BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
          builder: (context, state) {
            // Clear the keys on each build to prevent the map from growing
            // indefinitely with old, stale keys.
            _chipKeys.clear();

            final savedFilters = state.savedFilters;
            final userPreferences = context
                .watch<AppBloc>()
                .state
                .userContentPreferences;

            // Determine if the user is following any content to decide whether
            // to show the "Followed" filter chip.
            final isFollowingItems =
                (userPreferences?.followedTopics.isNotEmpty ?? false) ||
                (userPreferences?.followedSources.isNotEmpty ?? false) ||
                (userPreferences?.followedCountries.isNotEmpty ?? false);

            final activeFilterId = state.activeFilterId;

            // Lazily create and store a GlobalKey for each chip.
            // The key is associated with the Padding widget to ensure the
            // entire chip area is scrolled into view.
            final allKey = _chipKeys.putIfAbsent(_allFilterId, GlobalKey.new);
            final followedKey = _chipKeys.putIfAbsent(
              _followedFilterId,
              GlobalKey.new,
            );
            final customKey = _chipKeys.putIfAbsent(
              _customFilterId,
              GlobalKey.new,
            );

            final listView = ListView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: l10n.savedFiltersBarOpenTooltip,
                  onPressed: () {
                    // Read the current filter from the feed bloc.
                    final currentFilter = context
                        .read<HeadlinesFeedBloc>()
                        .state
                        .filter;
                    // Navigate to the filter page, passing the current filter
                    // as an argument. This ensures the filter page is
                    // initialized with the correct state.
                    context.goNamed(
                      Routes.feedFilterName,
                      extra: currentFilter,
                    );
                  },
                ),
                const VerticalDivider(
                  width: AppSpacing.md,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                ),
                Padding(
                  key: allKey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: ChoiceChip(
                    label: Text(l10n.savedFiltersBarAllLabel),
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    selected: activeFilterId == _allFilterId,
                    showCheckmark: false,
                    onSelected: (_) {
                      context.read<HeadlinesFeedBloc>().add(
                        AllFilterSelected(
                          adThemeStyle: AdThemeStyle.fromTheme(theme),
                        ),
                      );
                    },
                  ),
                ),
                // Conditionally display the "Followed" filter chip.
                if (isFollowingItems)
                  Padding(
                    key: followedKey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: ChoiceChip(
                      label: Text(l10n.savedFiltersBarFollowedLabel),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      selected: activeFilterId == _followedFilterId,
                      showCheckmark: false,
                      onSelected: (_) {
                        context.read<HeadlinesFeedBloc>().add(
                          FollowedFilterSelected(
                            adThemeStyle: AdThemeStyle.fromTheme(theme),
                          ),
                        );
                      },
                    ),
                  ),
                ...savedFilters.map((filter) {
                  final filterKey = _chipKeys.putIfAbsent(
                    filter.id,
                    GlobalKey.new,
                  );
                  return Padding(
                    key: filterKey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: ChoiceChip(
                      label: Text(filter.name),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      selected: activeFilterId == filter.id,
                      showCheckmark: false,
                      onSelected: (_) {
                        context.read<HeadlinesFeedBloc>().add(
                          SavedFilterSelected(
                            filter: filter,
                            adThemeStyle: AdThemeStyle.fromTheme(theme),
                          ),
                        );
                      },
                    ),
                  );
                }),
                if (activeFilterId == _customFilterId)
                  Padding(
                    key: customKey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: ChoiceChip(
                      label: Text(l10n.savedFiltersBarCustomLabel),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      showCheckmark: false,
                      selected: true,
                      onSelected: null,
                      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
              ],
            );

            // Determine if the fade should be shown based on scroll position.
            var showStartFade = false;
            var showEndFade = false;
            if (_scrollController.hasClients &&
                _scrollController.position.maxScrollExtent > 0) {
              final pixels = _scrollController.position.pixels;
              final minScroll = _scrollController.position.minScrollExtent;
              final maxScroll = _scrollController.position.maxScrollExtent;

              // Show start fade if not at the beginning.
              if (pixels > minScroll) {
                showStartFade = true;
              }
              // Show end fade if not at the end.
              if (pixels < maxScroll) {
                showEndFade = true;
              }
            }

            // Define the gradient colors and stops based on fade visibility.
            final colors = <Color>[
              if (showStartFade) Colors.transparent,
              Colors.black,
              Colors.black,
              if (showEndFade) Colors.transparent,
            ];

            final stops = <double>[
              if (showStartFade) 0.0,
              if (showStartFade) 0.05 else 0.0,
              if (showEndFade) 0.95 else 1.0,
              if (showEndFade) 1.0,
            ];

            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: colors,
                  stops: stops,
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: listView,
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
