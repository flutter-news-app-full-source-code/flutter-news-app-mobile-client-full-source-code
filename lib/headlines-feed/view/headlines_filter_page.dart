// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_categories_client/ht_categories_client.dart';
import 'package:ht_countries_client/ht_countries_client.dart';
import 'package:ht_main/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:ht_main/headlines-feed/models/headline_filter.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_sources_client/ht_sources_client.dart';

/// {@template headlines_filter_page}
/// A full-screen dialog page for selecting headline filters.
///
/// Allows users to navigate to specific pages for selecting categories,
/// sources, and event countries. Manages the temporary state of these
/// selections before applying them to the [HeadlinesFeedBloc].
/// {@endtemplate}
class HeadlinesFilterPage extends StatefulWidget {
  /// {@macro headlines_filter_page}
  const HeadlinesFilterPage({super.key});

  @override
  State<HeadlinesFilterPage> createState() => _HeadlinesFilterPageState();
}

class _HeadlinesFilterPageState extends State<HeadlinesFilterPage> {
  // Temporary state for filter selections within this modal flow
  late List<Category> _tempSelectedCategories;
  late List<Source> _tempSelectedSources;
  late List<Country> _tempSelectedCountries;

  @override
  void initState() {
    super.initState();
    // Initialize temporary state from the currently active filters in the BLoC
    final currentState = context.read<HeadlinesFeedBloc>().state;
    if (currentState is HeadlinesFeedLoaded) {
      _tempSelectedCategories = List.from(currentState.filter.categories ?? []);
      _tempSelectedSources = List.from(currentState.filter.sources ?? []);
      _tempSelectedCountries = List.from(
        currentState.filter.eventCountries ?? [],
      );
    } else {
      // Default to empty lists if the feed isn't loaded yet (should be rare)
      _tempSelectedCategories = [];
      _tempSelectedSources = [];
      _tempSelectedCountries = [];
    }
  }

  /// Builds a [ListTile] representing a filter criterion (e.g., Categories).
  ///
  /// Displays the criterion [title], the number of currently selected items
  /// ([selectedCount]), and navigates to the corresponding selection page
  /// specified by [routeName] when tapped.
  ///
  /// Uses [currentSelection] to pass the temporary selection state to the
  /// criterion page and updates the state via the [onResult] callback when
  /// the criterion page pops with a result.
  Widget _buildFilterTile({
    required BuildContext context,
    required String title,
    required int selectedCount,
    required String routeName,
    required List<dynamic> currentSelection, // Pass current temp selection
    required void Function(List<dynamic>?) onResult,
  }) {
    final l10n = context.l10n;
    final allLabel = l10n.headlinesFeedFilterAllLabel;
    final selectedLabel = l10n.headlinesFeedFilterSelectedCountLabel(
      selectedCount,
    );

    final subtitle = selectedCount == 0 ? allLabel : selectedLabel;

    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        // Use pushNamed to navigate and wait for a result
        final result = await context.pushNamed<List<dynamic>>(
          routeName,
          extra: currentSelection, // Pass current temp selection
        );
        // Update temp state if result is not null (user applied changes)
        if (result != null) {
          onResult(result);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => context.pop(), // Discard changes
        ),
        title: Text(l10n.headlinesFeedFilterTitle),
        actions: [
          // Clear Button
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: l10n.headlinesFeedFilterResetButton,
            onPressed: () {
              // Dispatch clear event immediately and pop
              context.read<HeadlinesFeedBloc>().add(
                HeadlinesFeedFiltersCleared(),
              );
              context.pop();
            },
          ),
          // Apply Button
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () {
              // Apply the temporary filters to the BLoC
              context.read<HeadlinesFeedBloc>().add(
                HeadlinesFeedFiltersApplied(
                  filter: HeadlineFilter(
                    categories:
                        _tempSelectedCategories.isNotEmpty
                            ? _tempSelectedCategories
                            : null,
                    sources:
                        _tempSelectedSources.isNotEmpty
                            ? _tempSelectedSources
                            : null,
                    eventCountries:
                        _tempSelectedCountries.isNotEmpty
                            ? _tempSelectedCountries
                            : null,
                  ),
                ),
              );
              context.pop(); // Close the filter page
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          _buildFilterTile(
            context: context,
            title: l10n.headlinesFeedFilterCategoryLabel,
            selectedCount: _tempSelectedCategories.length,
            routeName: Routes.feedFilterCategoriesName,
            currentSelection: _tempSelectedCategories,
            onResult: (result) {
              if (result is List<Category>) {
                setState(() => _tempSelectedCategories = result);
              }
            },
          ),
          _buildFilterTile(
            context: context,
            title: l10n.headlinesFeedFilterSourceLabel,
            selectedCount: _tempSelectedSources.length,
            routeName: Routes.feedFilterSourcesName,
            currentSelection: _tempSelectedSources,
            onResult: (result) {
              if (result is List<Source>) {
                setState(() => _tempSelectedSources = result);
              }
            },
          ),
          _buildFilterTile(
            context: context,
            title: l10n.headlinesFeedFilterEventCountryLabel,
            selectedCount: _tempSelectedCountries.length,
            routeName: Routes.feedFilterCountriesName,
            currentSelection: _tempSelectedCountries,
            onResult: (result) {
              if (result is List<Country>) {
                setState(() => _tempSelectedCountries = result);
              }
            },
          ),
        ],
      ),
    );
  }
}
