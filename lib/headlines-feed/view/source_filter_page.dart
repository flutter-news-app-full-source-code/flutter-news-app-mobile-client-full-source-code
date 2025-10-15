// ignore_for_file: lines_longer_than_80_chars

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
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

class _SourceFilterView extends StatefulWidget {
  const _SourceFilterView();

  @override
  State<_SourceFilterView> createState() => _SourceFilterViewState();
}

class _SourceFilterViewState extends State<_SourceFilterView> {
  // Local state to hold the filter criteria for the source list.
  // These are managed by the dedicated SourceListFilterPage and are used
  // only for filtering the UI in this page, not for the final headline query.
  Set<Country> _filteredHeadquarterCountries = {};
  Set<SourceType> _filteredSourceTypes = {};

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
          // Filter button to open the dedicated filter page.
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: l10n.sourceListFilterPageFilterButtonTooltip,
            onPressed: () async {
              final filterState = context.read<HeadlinesFilterBloc>().state;
              final result = await context.pushNamed<Map<String, dynamic>>(
                Routes.sourceListFilterName,
                extra: {
                  'allCountries': filterState.allCountries,
                  'allSourceTypes':
                      filterState.allSources
                          .map((s) => s.sourceType)
                          .toSet()
                          .toList()
                        ..sort((a, b) => a.name.compareTo(b.name)),
                  'initialSelectedHeadquarterCountries':
                      _filteredHeadquarterCountries,
                  'initialSelectedSourceTypes': _filteredSourceTypes,
                },
              );

              // When the filter page returns with new criteria, update the
              // local state to re-render the list.
              if (result != null && mounted) {
                setState(() {
                  _filteredHeadquarterCountries =
                      result['countries'] as Set<Country>;
                  _filteredSourceTypes = result['types'] as Set<SourceType>;
                });
              }
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
                  ),
                );
              },
            );
          }

          // Filter sources based on selected countries and types from HeadlinesFilterBloc
          final displayableSources = filterState.allSources.where((source) {
            // Filter by headquarters country.
            final matchesCountry =
                _filteredHeadquarterCountries.isEmpty ||
                _filteredHeadquarterCountries.any(
                  (c) => c.isoCode == source.headquarters.isoCode,
                );

            // Filter by source type.
            final matchesType =
                _filteredSourceTypes.isEmpty ||
                _filteredSourceTypes.contains(source.sourceType);
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

          // The main content is now just the list of sources.
          return _buildSourcesList(
            context,
            filterState,
            l10n,
            textTheme,
            displayableSources,
          );
        },
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
