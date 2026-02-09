// ignore_for_file: lines_longer_than_80_chars

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template source_list_filter_page}
/// A dedicated page for selecting filter criteria for the source list.
///
/// This page allows users to filter sources by their headquarters country
/// and by their type (e.g., News Agency, Blog). It is driven by the
/// [HeadlinesFilterBloc] to maintain a centralized state.
/// {@endtemplate}
class SourceListFilterPage extends StatelessWidget {
  /// {@macro source_list_filter_page}
  const SourceListFilterPage({required this.filterBloc, super.key});

  /// The instance of [HeadlinesFilterBloc] provided by the parent route.
  final HeadlinesFilterBloc filterBloc;

  @override
  Widget build(BuildContext context) {
    // Provide the existing filterBloc to this subtree.
    return BlocProvider.value(
      value: filterBloc,
      child: const _SourceListFilterView(),
    );
  }
}

class _SourceListFilterView extends StatelessWidget {
  const _SourceListFilterView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.sourceListFilterPageTitle,
          style: textTheme.titleLarge,
        ),
        actions: [
          // The "Apply" button now just pops the page, as the state is
          // already updated in the shared BLoC.
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: BlocBuilder<HeadlinesFilterBloc, HeadlinesFilterState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              // Section for filtering by headquarters country.
              ListTile(
                title: Text(l10n.headlinesFeedFilterSourceCountryLabel),
                subtitle: Text(
                  state.selectedSourceHeadquarterCountries.isEmpty
                      ? l10n.headlinesFeedFilterAllLabel
                      : l10n.headlinesFeedFilterSelectedCountLabel(
                          state.selectedSourceHeadquarterCountries.length,
                        ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  // Navigate to a generic multi-select search page, passing
                  // the necessary data and the shared BLoC instance.
                  final result = await context.pushNamed<Set<dynamic>>(
                    Routes.multiSelectSearchName,
                    extra: {
                      'title': l10n.headlinesFeedFilterSourceCountryLabel,
                      'allItems': state.allHeadquarterCountries,
                      'initialSelectedItems':
                          state.selectedSourceHeadquarterCountries,
                      'itemBuilder': (Country country) => country.name,
                    },
                  );

                  if (result != null && context.mounted) {
                    // When the page returns, dispatch an event to the
                    // shared BLoC to update the source filter criteria.
                    context.read<HeadlinesFilterBloc>().add(
                      FilterSourceCriteriaChanged(
                        selectedCountries: result.cast<Country>(),
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              // Section for filtering by source type.
              ListTile(
                title: Text(l10n.headlinesFeedFilterSourceTypeLabel),
                subtitle: Text(
                  state.selectedSourceTypes.isEmpty
                      ? l10n.headlinesFeedFilterAllLabel
                      : l10n.headlinesFeedFilterSelectedCountLabel(
                          state.selectedSourceTypes.length,
                        ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  // Navigate to the new dedicated source type filter page.
                  // The logic is similar to the country filter.
                  await context.pushNamed(
                    Routes.sourceTypeFilterName, // New route
                    extra: context.read<HeadlinesFilterBloc>(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
