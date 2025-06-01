//
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_data_repository/ht_data_repository.dart'; // Added
import 'package:ht_main/app/bloc/app_bloc.dart'; // Added
import 'package:ht_main/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:ht_main/headlines-feed/models/headline_filter.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_shared/ht_shared.dart'
    show
        Category,
        Source,
        SourceType,
        UserContentPreferences,
        User,
        HtHttpException, // Added
        NotFoundException; // Added

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
  late Set<String> _tempSelectedSourceCountryIsoCodes;
  late Set<SourceType> _tempSelectedSourceSourceTypes;

  // New state variables for the "Apply my followed items" feature
  bool _useFollowedFilters = false;
  bool _isLoadingFollowedFilters = false;
  String? _loadFollowedFiltersError;
  UserContentPreferences? _currentUserPreferences;

  @override
  void initState() {
    super.initState();
    final headlinesFeedState =
        BlocProvider.of<HeadlinesFeedBloc>(context).state;

    bool initialUseFollowedFilters = false;

    if (headlinesFeedState is HeadlinesFeedLoaded) {
      final currentFilter = headlinesFeedState.filter;
      _tempSelectedCategories = List.from(currentFilter.categories ?? []);
      _tempSelectedSources = List.from(currentFilter.sources ?? []);
      _tempSelectedSourceCountryIsoCodes =
          Set.from(currentFilter.selectedSourceCountryIsoCodes ?? {});
      _tempSelectedSourceSourceTypes =
          Set.from(currentFilter.selectedSourceSourceTypes ?? {});

      // Use the new flag from the filter to set the checkbox state
      initialUseFollowedFilters = currentFilter.isFromFollowedItems;
    } else {
      _tempSelectedCategories = [];
      _tempSelectedSources = [];
      _tempSelectedSourceCountryIsoCodes = {};
      _tempSelectedSourceSourceTypes = {};
    }

    _useFollowedFilters = initialUseFollowedFilters;
    _isLoadingFollowedFilters = false;
    _loadFollowedFiltersError = null;
    _currentUserPreferences = null;

    // If the checkbox should be initially checked, fetch the followed items
    // to ensure the _temp lists are correctly populated with the *latest*
    // followed items, and to correctly disable the manual filter tiles.
    if (_useFollowedFilters) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Ensure context is available for l10n and BLoC access
        if (mounted) {
          _fetchAndApplyFollowedFilters();
        }
      });
    }
  }

  Future<void> _fetchAndApplyFollowedFilters() async {
    setState(() {
      _isLoadingFollowedFilters = true;
      _loadFollowedFiltersError = null;
    });

    final appState = context.read<AppBloc>().state;
    final User? currentUser = appState.user;

    if (currentUser == null) {
      setState(() {
        _isLoadingFollowedFilters = false;
        _useFollowedFilters = false; // Uncheck the box
        _loadFollowedFiltersError =
            context.l10n.mustBeLoggedInToUseFeatureError;
      });
      return;
    }

    try {
      final preferencesRepo =
          context.read<HtDataRepository<UserContentPreferences>>();
      final preferences = await preferencesRepo.read(
        id: currentUser.id,
        userId: currentUser.id,
      ); // Assuming read by user ID

      // NEW: Check if followed items are empty
      if (preferences.followedCategories.isEmpty &&
          preferences.followedSources.isEmpty) {
        setState(() {
          _isLoadingFollowedFilters = false;
          _useFollowedFilters = false; // Uncheck the box
          _tempSelectedCategories = []; // Ensure lists are cleared
          _tempSelectedSources = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(context.l10n.noFollowedItemsForFilterSnackbar),
                duration: const Duration(seconds: 3),
              ),
            );
        }
        return; // Exit the function as no filters to apply
      } else {
        setState(() {
          _currentUserPreferences = preferences;
          _tempSelectedCategories = List.from(preferences.followedCategories);
          _tempSelectedSources = List.from(preferences.followedSources);
          // We don't auto-apply source country/type filters from user preferences here
          // as the "Apply my followed" checkbox is primarily for categories/sources.
          _isLoadingFollowedFilters = false;
        });
      }
    } on NotFoundException {
      setState(() {
        _currentUserPreferences =
            UserContentPreferences(id: currentUser.id); // Empty prefs
        _tempSelectedCategories = [];
        _tempSelectedSources = [];
        _isLoadingFollowedFilters = false;
        _useFollowedFilters = false; // Uncheck as no prefs found (implies no followed)
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(context.l10n.noFollowedItemsForFilterSnackbar),
              duration: const Duration(seconds: 3),
            ),
          );
      }
    } on HtHttpException catch (e) {
      setState(() {
        _isLoadingFollowedFilters = false;
        _useFollowedFilters = false; // Uncheck the box
        _loadFollowedFiltersError =
            e.message; // Or a generic "Failed to load"
      });
    } catch (e) {
      setState(() {
        _isLoadingFollowedFilters = false;
        _useFollowedFilters = false; // Uncheck the box
        _loadFollowedFiltersError = context.l10n.unknownError;
      });
    }
  }

  void _clearTemporaryFilters() {
    setState(() {
      _tempSelectedCategories = [];
      _tempSelectedSources = [];
      // Keep source country/type filters as they are not part of this quick filter
      // _tempSelectedSourceCountryIsoCodes = {};
      // _tempSelectedSourceSourceTypes = {};
    });
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
    bool enabled = true,
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
      enabled: enabled, // Use the enabled parameter
      onTap: enabled // Only allow tap if enabled
          ? () async {
              final result = await context.pushNamed<dynamic>(
                routeName,
                extra: currentSelectionData, // Pass the map or list
              );
              if (result != null && onResult != null) {
                onResult(result);
              }
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => context.pop(), // Discard changes
        ),
        title: Text(l10n.headlinesFeedFilterTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: l10n.headlinesFeedFilterResetButton,
            onPressed: () {
              context.read<HeadlinesFeedBloc>().add(
                    HeadlinesFeedFiltersCleared(),
                  );
              // Also reset local state for the checkbox
              setState(() {
                _useFollowedFilters = false;
                _isLoadingFollowedFilters = false;
                _loadFollowedFiltersError = null;
                _clearTemporaryFilters();
              });
              context.pop();
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () {
              final newFilter = HeadlineFilter(
                categories: _tempSelectedCategories.isNotEmpty
                    ? _tempSelectedCategories
                    : null,
                sources: _tempSelectedSources.isNotEmpty
                    ? _tempSelectedSources
                    : null,
                selectedSourceCountryIsoCodes:
                    _tempSelectedSourceCountryIsoCodes.isNotEmpty
                        ? _tempSelectedSourceCountryIsoCodes
                        : null,
                selectedSourceSourceTypes:
                    _tempSelectedSourceSourceTypes.isNotEmpty
                        ? _tempSelectedSourceSourceTypes
                        : null,
                isFromFollowedItems:
                    _useFollowedFilters, // Set the new flag
              );
              context.read<HeadlinesFeedBloc>().add(
                    HeadlinesFeedFiltersApplied(filter: newFilter),
                  );
              context.pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingSmall, // Consistent with ListTiles
            ),
            child: CheckboxListTile(
              title: Text(l10n.headlinesFeedFilterApplyFollowedLabel),
              value: _useFollowedFilters,
              onChanged: (bool? newValue) {
                setState(() {
                  _useFollowedFilters = newValue ?? false;
                  if (_useFollowedFilters) {
                    _fetchAndApplyFollowedFilters();
                  } else {
                    _isLoadingFollowedFilters = false;
                    _loadFollowedFiltersError = null;
                    _clearTemporaryFilters(); // Clear auto-applied filters
                  }
                });
              },
              secondary: _isLoadingFollowedFilters
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
          if (_loadFollowedFiltersError != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.paddingLarge,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                _loadFollowedFiltersError!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          const Divider(),
          _buildFilterTile(
            context: context,
            title: l10n.headlinesFeedFilterCategoryLabel,
            enabled: !_useFollowedFilters && !_isLoadingFollowedFilters,
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
            enabled: !_useFollowedFilters && !_isLoadingFollowedFilters,
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
        ],
      ),
    );
  }
}
