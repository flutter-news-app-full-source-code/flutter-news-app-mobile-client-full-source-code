//
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs, unused_field

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/models/headline_filter.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template headlines_filter_page}
/// A full-screen dialog page for selecting headline filters.
///
/// Allows users to navigate to specific pages for selecting categories,
/// sources, and event countries. Manages the temporary state of these
/// selections before applying them to the [HeadlinesFeedBloc].
/// {@endtemplate}
class HeadlinesFilterPage extends StatelessWidget {
  /// {@macro headlines_filter_page}
  const HeadlinesFilterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the HeadlinesFeedBloc to get the current filter state for initialization.
    final headlinesFeedBloc = context.read<HeadlinesFeedBloc>();
    final currentFilter = headlinesFeedBloc.state.filter;

    return BlocProvider(
      create: (context) => HeadlinesFilterBloc(
        topicsRepository: context.read<DataRepository<Topic>>(),
        sourcesRepository: context.read<DataRepository<Source>>(),
        countriesRepository: context.read<DataRepository<Country>>(),
        appBloc: context.read<AppBloc>(),
      )..add(
          FilterDataLoaded(
            initialSelectedTopics: currentFilter.topics ?? [],
            initialSelectedSources: currentFilter.sources ?? [],
            initialSelectedCountries: currentFilter.eventCountries ?? [],
            isUsingFollowedItems: currentFilter.isFromFollowedItems,
          ),
        ),
      child: const _HeadlinesFilterView(),
    );
  }
}

class _HeadlinesFilterView extends StatelessWidget {
  const _HeadlinesFilterView();

  /// Builds a [ListTile] representing a filter criterion (e.g., Categories).
  ///
  /// Displays the criterion [title], the number of currently selected items
  /// ([selectedCount]), and navigates to the corresponding selection page
  /// specified by [routeName] when tapped.
  Widget _buildFilterTile({
    required BuildContext context,
    required String title,
    required int selectedCount,
    required String routeName,
    bool enabled = true,
  }) {
    final l10n = AppLocalizationsX(context).l10n;
    final allLabel = l10n.headlinesFeedFilterAllLabel;
    final selectedLabel = l10n.headlinesFeedFilterSelectedCountLabel(
      selectedCount,
    );

    final subtitle = selectedCount == 0 ? allLabel : selectedLabel;

    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      enabled: enabled,
      onTap: enabled
          ? () {
              // Navigate to the child filter page. The child page will read
              // the current selections from HeadlinesFilterBloc directly.
              context.pushNamed(routeName);
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.headlinesFeedFilterTitle),
        actions: [
          // Reset All Filters Button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.headlinesFeedFilterResetButton,
            onPressed: () {
              context.read<HeadlinesFilterBloc>().add(
                    const FilterSelectionsCleared(),
                  );
            },
          ),
          // Apply My Followed Items Button
          BlocBuilder<HeadlinesFilterBloc, HeadlinesFilterState>(
            builder: (context, filterState) {
              final appState = context.watch<AppBloc>().state;
              final followedTopics =
                  appState.userContentPreferences?.followedTopics ?? [];
              final followedSources =
                  appState.userContentPreferences?.followedSources ?? [];
              final followedCountries =
                  appState.userContentPreferences?.followedCountries ?? [];

              final hasFollowedItems = followedTopics.isNotEmpty ||
                  followedSources.isNotEmpty ||
                  followedCountries.isNotEmpty;

              return IconButton(
                icon: filterState.isUsingFollowedItems
                    ? const Icon(Icons.favorite)
                    : const Icon(Icons.favorite_border),
                color: filterState.isUsingFollowedItems
                    ? theme.colorScheme.primary
                    : null,
                tooltip: l10n.headlinesFeedFilterApplyFollowedLabel,
                onPressed: hasFollowedItems
                    ? () {
                        context.read<HeadlinesFilterBloc>().add(
                              FollowedItemsFilterToggled(
                                isUsingFollowedItems:
                                    !filterState.isUsingFollowedItems,
                              ),
                            );
                      }
                    : () {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.noFollowedItemsForFilterSnackbar,
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                      },
              );
            },
          ),
          // Apply Filters Button
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () {
              final filterState = context.read<HeadlinesFilterBloc>().state;
              final newFilter = HeadlineFilter(
                topics: filterState.selectedTopics.isNotEmpty
                    ? filterState.selectedTopics.toList()
                    : null,
                sources: filterState.selectedSources.isNotEmpty
                    ? filterState.selectedSources.toList()
                    : null,
                eventCountries: filterState.selectedCountries.isNotEmpty
                    ? filterState.selectedCountries.toList()
                    : null,
                isFromFollowedItems: filterState.isUsingFollowedItems,
              );
              context.read<HeadlinesFeedBloc>().add(
                    HeadlinesFeedFiltersApplied(
                      filter: newFilter,
                      adThemeStyle: AdThemeStyle.fromTheme(Theme.of(context)),
                    ),
                  );
              context.pop();
            },
          ),
        ],
      ),
      body: BlocBuilder<HeadlinesFilterBloc, HeadlinesFilterState>(
        builder: (context, filterState) {
          // Determine if the "Apply my followed items" feature is active.
          // This will disable the individual filter tiles.
          final isFollowedFilterActive = filterState.isUsingFollowedItems;

          if (filterState.status == HeadlinesFilterStatus.loading) {
            return LoadingStateWidget(
              icon: Icons.filter_list,
              headline: l10n.headlinesFeedFilterLoadingHeadline,
              subheadline: l10n.pleaseWait,
            );
          }

          if (filterState.status == HeadlinesFilterStatus.failure) {
            return FailureStateWidget(
              exception: filterState.error ??
                  const UnknownException('Failed to load filter data.'),
              onRetry: () {
                final headlinesFeedBloc = context.read<HeadlinesFeedBloc>();
                final currentFilter = headlinesFeedBloc.state.filter;
                context.read<HeadlinesFilterBloc>().add(
                      FilterDataLoaded(
                        initialSelectedTopics: currentFilter.topics ?? [],
                        initialSelectedSources: currentFilter.sources ?? [],
                        initialSelectedCountries:
                            currentFilter.eventCountries ?? [],
                        isUsingFollowedItems: currentFilter.isFromFollowedItems,
                      ),
                    );
              },
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              const Divider(),
              _buildFilterTile(
                context: context,
                title: l10n.headlinesFeedFilterTopicLabel,
                enabled: !isFollowedFilterActive,
                selectedCount: filterState.selectedTopics.length,
                routeName: Routes.feedFilterTopicsName,
              ),
              _buildFilterTile(
                context: context,
                title: l10n.headlinesFeedFilterSourceLabel,
                enabled: !isFollowedFilterActive,
                selectedCount: filterState.selectedSources.length,
                routeName: Routes.feedFilterSourcesName,
              ),
              _buildFilterTile(
                context: context,
                title: l10n.headlinesFeedFilterEventCountryLabel,
                enabled: !isFollowedFilterActive,
                selectedCount: filterState.selectedCountries.length,
                routeName: Routes.feedFilterEventCountriesName,
              ),
            ],
          );
        },
      ),
    );
  }
}
