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
        final isSelected = filterState.selectedSources.contains(source);

        void handleTap(bool? value) {
          if (value != null) {
            context.read<HeadlinesFilterBloc>().add(
              FilterSourceToggled(source: source, isSelected: value),
            );
          }
        }

        return ListTile(
          leading: SizedBox(
            width: 40,
            height: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: Image.network(
                source.logoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.source_outlined),
              ),
            ),
          ),
          title: Text(source.name, style: textTheme.titleMedium),
          trailing: Checkbox(value: isSelected, onChanged: handleTap),
          onTap: () => handleTap(!isSelected),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.paddingMedium,
          ),
        );
      },
    );
  }

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
                      filterState.selectedSourceHeadquarterCountries,
                  'initialSelectedSourceTypes': filterState.selectedSourceTypes,
                },
              );

              // When the filter page returns with new criteria, update the
              // bloc to re-render the list.
              if (result != null && mounted) {
                // ignore: use_build_context_synchronously
                context.read<HeadlinesFilterBloc>().add(
                  FilterSourceCriteriaChanged(
                    selectedCountries: result['countries'] as Set<Country>,
                    selectedSourceTypes: result['types'] as Set<SourceType>,
                  ),
                );
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
                filterState.selectedSourceHeadquarterCountries.isEmpty ||
                filterState.selectedSourceHeadquarterCountries.any(
                  (c) => c.isoCode == source.headquarters.isoCode,
                );

            // Filter by source type.
            final matchesType =
                filterState.selectedSourceTypes.isEmpty ||
                filterState.selectedSourceTypes.contains(source.sourceType);
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
}
