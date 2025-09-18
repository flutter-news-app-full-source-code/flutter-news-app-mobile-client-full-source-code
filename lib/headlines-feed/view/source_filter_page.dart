// ignore_for_file: lines_longer_than_80_chars

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template source_filter_page}
/// A page dedicated to selecting news sources for filtering headlines.
///
/// This page allows users to refine the displayed list of sources using
/// country and source type capsules. It now interacts with the centralized
/// [HeadlinesFilterBloc] to manage the list of available sources and the
/// user's selections.
/// {@endtemplate}
class SourceFilterPage extends StatelessWidget {
  /// {@macro source_filter_page}
  ///
  /// Requires the [filterBloc] instance passed from the parent route.
  const SourceFilterPage({required this.filterBloc, super.key});

  /// The instance of [HeadlinesFilterBloc] provided by the parent route.
  final HeadlinesFilterBloc filterBloc;

  @override
  Widget build(BuildContext context) {
    // Provide the existing filterBloc to this subtree.
    return BlocProvider.value(
      value: filterBloc,
      child: const _SourceFilterView(),
    );
  }
}

class _SourceFilterView extends StatelessWidget {
  const _SourceFilterView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.headlinesFeedFilterSourceLabel,
          style: textTheme.titleLarge,
        ),
        actions: [
          // Apply My Followed Sources Button
          BlocBuilder<HeadlinesFilterBloc, HeadlinesFilterState>(
            builder: (context, filterState) {
              final appState = context.watch<AppBloc>().state;
              final followedSources =
                  appState.userContentPreferences?.followedSources ?? [];

              // Determine if the current selection matches the followed sources
              final isFollowedFilterActive =
                  followedSources.isNotEmpty &&
                  filterState.selectedSources.length ==
                      followedSources.length &&
                  filterState.selectedSources.containsAll(followedSources);

              return IconButton(
                icon: isFollowedFilterActive
                    ? const Icon(Icons.favorite)
                    : const Icon(Icons.favorite_border),
                color: isFollowedFilterActive
                    ? theme.colorScheme.primary
                    : null,
                tooltip: l10n.headlinesFeedFilterApplyFollowedLabel,
                onPressed: () {
                  if (followedSources.isEmpty) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(l10n.noFollowedItemsForFilterSnackbar),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                  } else {
                    // Toggle the followed items filter in the HeadlinesFilterBloc
                    context.read<HeadlinesFilterBloc>().add(
                      FollowedItemsFilterToggled(
                        isUsingFollowedItems: !isFollowedFilterActive,
                      ),
                    );
                  }
                },
              );
            },
          ),

          // Apply Filters Button (now just pops, as state is managed centrally)
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () {
              // The selections are already managed by HeadlinesFilterBloc.
              // Just pop the page.
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: BlocBuilder<HeadlinesFilterBloc, HeadlinesFilterState>(
        builder: (context, filterState) {
          final isLoadingMainList =
              filterState.status == HeadlinesFilterStatus.loading;

          if (isLoadingMainList) {
            return LoadingStateWidget(
              icon: Icons.source_outlined,
              headline: l10n.sourceFilterLoadingHeadline,
              subheadline: l10n.sourceFilterLoadingSubheadline,
            );
          }
          if (filterState.status == HeadlinesFilterStatus.failure &&
              filterState.allSources.isEmpty) {
            return FailureStateWidget(
              exception:
                  filterState.error ??
                  const UnknownException('Failed to load source filter data.'),
              onRetry: () {
                context.read<HeadlinesFilterBloc>().add(
                  FilterDataLoaded(
                    initialSelectedTopics: filterState.selectedTopics.toList(),
                    initialSelectedSources: filterState.selectedSources
                        .toList(),
                    initialSelectedCountries: filterState.selectedCountries
                        .toList(),
                    isUsingFollowedItems: filterState.isUsingFollowedItems,
                  ),
                );
              },
            );
          }

          // Filter sources based on selected countries and types from HeadlinesFilterBloc
          final displayableSources = filterState.allSources.where((source) {
            final matchesCountry =
                filterState.selectedCountries.isEmpty ||
                filterState.selectedCountries.any(
                  (c) => c.isoCode == source.headquarters.isoCode,
                );
            // Assuming all source types are available and selected by default if none are explicitly selected
            final matchesType =
                filterState.selectedSources.isEmpty ||
                filterState.selectedSources.contains(source);
            return matchesCountry && matchesType;
          }).toList();

          if (displayableSources.isEmpty &&
              filterState.status != HeadlinesFilterStatus.loading) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.paddingLarge),
                child: Text(
                  l10n.headlinesFeedFilterNoSourcesMatch,
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCountryCapsules(context, filterState, l10n, textTheme),
              const SizedBox(height: AppSpacing.md),
              _buildSourceTypeCapsules(context, filterState, l10n, textTheme),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.paddingMedium,
                ),
                child: Text(
                  l10n.headlinesFeedFilterSourceLabel,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: _buildSourcesList(
                  context,
                  filterState,
                  l10n,
                  textTheme,
                  displayableSources,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCountryCapsules(
    BuildContext context,
    HeadlinesFilterState filterState,
    AppLocalizations l10n,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMedium,
      ).copyWith(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.headlinesFeedFilterSourceCountryLabel,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.xl + AppSpacing.md,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filterState.allCountries.length + 1,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ChoiceChip(
                    label: Text(l10n.headlinesFeedFilterAllLabel),
                    labelStyle: textTheme.labelLarge,
                    selected: filterState.selectedCountries.isEmpty,
                    onSelected: (_) {
                      // Clear all country selections
                      for (final country in filterState.allCountries) {
                        context.read<HeadlinesFilterBloc>().add(
                          FilterCountryToggled(
                            country: country,
                            isSelected: false,
                          ),
                        );
                      }
                    },
                  );
                }
                final country = filterState.allCountries[index - 1];
                return ChoiceChip(
                  avatar: country.flagUrl.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(country.flagUrl),
                          radius: AppSpacing.sm + AppSpacing.xs,
                        )
                      : null,
                  label: Text(country.name),
                  labelStyle: textTheme.labelLarge,
                  selected: filterState.selectedCountries.contains(country),
                  onSelected: (isSelected) {
                    context.read<HeadlinesFilterBloc>().add(
                      FilterCountryToggled(
                        country: country,
                        isSelected: isSelected,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceTypeCapsules(
    BuildContext context,
    HeadlinesFilterState filterState,
    AppLocalizations l10n,
    TextTheme textTheme,
  ) {
    // For source types, we need to get all unique source types from all available sources
    final allSourceTypes =
        filterState.allSources.map((s) => s.sourceType).toSet().toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    // Determine which source types are currently selected based on the selected sources
    final selectedSourceTypes = filterState.selectedSources
        .map((s) => s.sourceType)
        .toSet();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.headlinesFeedFilterSourceTypeLabel,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.xl + AppSpacing.md,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allSourceTypes.length + 1,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ChoiceChip(
                    label: Text(l10n.headlinesFeedFilterAllLabel),
                    labelStyle: textTheme.labelLarge,
                    selected: selectedSourceTypes.isEmpty,
                    onSelected: (_) {
                      // Clear all source selections
                      for (final source in filterState.allSources) {
                        context.read<HeadlinesFilterBloc>().add(
                          FilterSourceToggled(
                            source: source,
                            isSelected: false,
                          ),
                        );
                      }
                    },
                  );
                }
                final sourceType = allSourceTypes[index - 1];
                return ChoiceChip(
                  label: Text(sourceType.name),
                  labelStyle: textTheme.labelLarge,
                  selected: selectedSourceTypes.contains(sourceType),
                  onSelected: (isSelected) {
                    // Toggle all sources of this type
                    for (final source in filterState.allSources.where(
                      (s) => s.sourceType == sourceType,
                    )) {
                      context.read<HeadlinesFilterBloc>().add(
                        FilterSourceToggled(
                          source: source,
                          isSelected: isSelected,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesList(
    BuildContext context,
    HeadlinesFilterState filterState,
    AppLocalizations l10n,
    TextTheme textTheme,
    List<Source> displayableSources,
  ) {
    if (filterState.status == HeadlinesFilterStatus.loading &&
        displayableSources.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (filterState.status == HeadlinesFilterStatus.failure &&
        displayableSources.isEmpty) {
      return FailureStateWidget(
        exception:
            filterState.error ??
            const UnknownException('Failed to load displayable sources.'),
        onRetry: () {
          context.read<HeadlinesFilterBloc>().add(
            FilterDataLoaded(
              initialSelectedTopics: filterState.selectedTopics.toList(),
              initialSelectedSources: filterState.selectedSources.toList(),
              initialSelectedCountries: filterState.selectedCountries.toList(),
              isUsingFollowedItems: filterState.isUsingFollowedItems,
            ),
          );
        },
      );
    }
    if (displayableSources.isEmpty &&
        filterState.status != HeadlinesFilterStatus.loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingLarge),
          child: Text(
            l10n.headlinesFeedFilterNoSourcesMatch,
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.paddingSmall,
      ).copyWith(bottom: AppSpacing.xxl),
      itemCount: displayableSources.length,
      itemBuilder: (context, index) {
        final source = displayableSources[index];
        return CheckboxListTile(
          title: Text(source.name, style: textTheme.titleMedium),
          value: filterState.selectedSources.contains(source),
          onChanged: (bool? value) {
            if (value != null) {
              context.read<HeadlinesFilterBloc>().add(
                FilterSourceToggled(source: source, isSelected: value),
              );
            }
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.paddingMedium,
          ),
        );
      },
    );
  }
}
