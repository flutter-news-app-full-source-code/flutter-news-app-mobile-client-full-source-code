//
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:ht_main/headlines-feed/models/headline_filter.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_shared/ht_shared.dart'
    show Category, Source, SourceType;

// Keys for passing data to/from SourceFilterPage
const String keySelectedSources = 'selectedSources';
const String keySelectedCountryIsoCodes = 'selectedCountryIsoCodes';
const String keySelectedSourceTypes = 'selectedSourceTypes';

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
  /// Temporary state for filter selections within this modal flow.
  /// These hold the selections made by the user *while* this filter page
  /// and its sub-pages (Category, Source, Country) are open.
  /// They are initialized from the main [HeadlinesFeedBloc]'s current filter
  /// and are only applied back to the BLoC when the user taps 'Apply'.
  late List<Category> _tempSelectedCategories;
  late List<Source> _tempSelectedSources;
  // State for source filter capsules, to be passed to and from SourceFilterPage
  late Set<String> _tempSelectedSourceCountryIsoCodes;
  late Set<SourceType> _tempSelectedSourceSourceTypes;

  @override
  void initState() {
    super.initState();
    // Initialize the temporary selection state based on the currently
    // active filters held within the HeadlinesFeedBloc. This ensures that
    // when the filter page opens, it reflects the filters already applied.
    final currentState = BlocProvider.of<HeadlinesFeedBloc>(context).state;
    if (currentState is HeadlinesFeedLoaded) {
      // Create copies of the lists to avoid modifying the BLoC state directly.
      _tempSelectedCategories = List.from(currentState.filter.categories ?? []);
      _tempSelectedSources = List.from(currentState.filter.sources ?? []);
      // Initialize source capsule states. These are persisted here.
      // For now, let's assume they start empty and are populated by SourceFilterPage's result.
      // Or, if HeadlineFilter could store them, we'd get them from there.
      // For this iteration, they start empty. SourceFilterPage will manage its own capsule
      // state and return it.
      _tempSelectedSourceCountryIsoCodes = {};
      _tempSelectedSourceSourceTypes = {};
    } else {
      _tempSelectedCategories = [];
      _tempSelectedSources = [];
      _tempSelectedSourceCountryIsoCodes = {};
      _tempSelectedSourceSourceTypes = {};
    }
  }

  /// Builds a [ListTile] representing a filter criterion (e.g., Categories).
  ///
  /// Displays the criterion [title], the number of currently selected items
  /// ([selectedCount]), and navigates to the corresponding selection page
  /// specified by [routeName] when tapped.
  ///
  /// Uses [currentSelection] to pass the current temporary selection state
  /// (e.g., `_tempSelectedSources`) to the corresponding criterion selection page
  /// (e.g., `SourceFilterPage`) via the `extra` parameter of `context.pushNamed`.
  /// Updates the temporary state via the [onResult] callback when the
  /// criterion page pops with a result (the user tapped 'Apply' on that page).
  Widget _buildFilterTile({
    required BuildContext context,
    required String title,
    required int selectedCount,
    required String routeName,
    // For sources, currentSelection will be a Map
    required dynamic currentSelectionData,
    required void Function(dynamic)? onResult, // Result can also be a Map
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
        final result = await context.pushNamed<dynamic>(
          routeName,
          extra: currentSelectionData, // Pass the map or list
        );
        if (result != null && onResult != null) {
          onResult(result);
        }
      },
    );
  }

  @override
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
              // When the user confirms their filter choices on this page,
              // create a new HeadlineFilter object using the final temporary
              // selections gathered from the sub-pages.
              final newFilter = HeadlineFilter(
                categories:
                    _tempSelectedCategories.isNotEmpty
                        ? _tempSelectedCategories
                        : null, // Use null if empty
                sources:
                    _tempSelectedSources.isNotEmpty
                        ? _tempSelectedSources
                        : null, // Use null if empty
              );

              // Add an event to the main HeadlinesFeedBloc to apply the
              // newly constructed filter and trigger a data refresh.
              context.read<HeadlinesFeedBloc>().add(
                HeadlinesFeedFiltersApplied(filter: newFilter),
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
            currentSelectionData: _tempSelectedCategories,
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
            currentSelectionData: {
              keySelectedSources: _tempSelectedSources,
              keySelectedCountryIsoCodes: _tempSelectedSourceCountryIsoCodes,
              keySelectedSourceTypes: _tempSelectedSourceSourceTypes,
            },
            onResult: (result) {
              if (result is Map<String, dynamic>) {
                setState(() {
                  _tempSelectedSources =
                      result[keySelectedSources] as List<Source>? ?? [];
                  _tempSelectedSourceCountryIsoCodes =
                      result[keySelectedCountryIsoCodes] as Set<String>? ?? {};
                  _tempSelectedSourceSourceTypes =
                      result[keySelectedSourceTypes] as Set<SourceType>? ?? {};
                });
              }
            },
          ),
          // _buildFilterTile for eventCountries removed
        ],
      ),
    );
  }
}
