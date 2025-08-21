//
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs, unused_field

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/models/headline_filter.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

// Keys for passing data to/from SourceFilterPage
const String keySelectedSources = 'selectedSources';

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
  late List<Topic> _tempSelectedTopics;
  late List<Source> _tempSelectedSources;
  late List<Country> _tempSelectedEventCountries;

  // New state variables for the "Apply my followed items" feature
  bool _useFollowedFilters = false;
  bool _isLoadingFollowedFilters = false;
  String? _loadFollowedFiltersError;
  UserContentPreferences? _currentUserPreferences;

  @override
  void initState() {
    super.initState();
    final headlinesFeedState = BlocProvider.of<HeadlinesFeedBloc>(
      context,
    ).state;

    final currentFilter = headlinesFeedState.filter;
    _tempSelectedTopics = List.from(currentFilter.topics ?? []);
    _tempSelectedSources = List.from(currentFilter.sources ?? []);
    _tempSelectedEventCountries = List.from(currentFilter.eventCountries ?? []);

    _useFollowedFilters = currentFilter.isFromFollowedItems;
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
    final currentUser = appState.user;

    if (currentUser == null) {
      setState(() {
        _isLoadingFollowedFilters = false;
        _useFollowedFilters = false;
        _loadFollowedFiltersError = AppLocalizationsX(
          context,
        ).l10n.mustBeLoggedInToUseFeatureError;
      });
      return;
    }

    try {
      final preferencesRepo = context
          .read<DataRepository<UserContentPreferences>>();
      final preferences = await preferencesRepo.read(
        id: currentUser.id,
        userId: currentUser.id,
      );

      // NEW: Check if followed items are empty
      if (preferences.followedTopics.isEmpty &&
          preferences.followedSources.isEmpty) {
        setState(() {
          _isLoadingFollowedFilters = false;
          _useFollowedFilters = false;
          _tempSelectedTopics = [];
          _tempSelectedSources = [];
          _tempSelectedEventCountries = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizationsX(
                    context,
                  ).l10n.noFollowedItemsForFilterSnackbar,
                ),
                duration: const Duration(seconds: 3),
              ),
            );
        }
        return;
      } else {
        setState(() {
          _currentUserPreferences = preferences;
          _tempSelectedTopics = List.from(preferences.followedTopics);
          _tempSelectedSources = List.from(preferences.followedSources);
          // We don't auto-apply source country/type filters from user preferences here
          // as the "Apply my followed" checkbox is primarily for topics/sources.
          _isLoadingFollowedFilters = false;
        });
      }
    } on NotFoundException {
      setState(() {
        _currentUserPreferences = UserContentPreferences(
          id: currentUser.id,
          followedTopics: const [],
          followedSources: const [],
          followedCountries: const [],
          savedHeadlines: const [],
        );
        _tempSelectedTopics = [];
        _tempSelectedSources = [];
        _tempSelectedEventCountries = [];
        _isLoadingFollowedFilters = false;
        _useFollowedFilters = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizationsX(
                  context,
                ).l10n.noFollowedItemsForFilterSnackbar,
              ),
              duration: const Duration(seconds: 3),
            ),
          );
      }
    } on HttpException catch (e) {
      setState(() {
        _isLoadingFollowedFilters = false;
        _useFollowedFilters = false;
        _loadFollowedFiltersError = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoadingFollowedFilters = false;
        _useFollowedFilters = false;
        _loadFollowedFiltersError = AppLocalizationsX(
          context,
        ).l10n.unknownError;
      });
    }
  }

  void _clearTemporaryFilters() {
    setState(() {
      _tempSelectedTopics = [];
      _tempSelectedSources = [];
      _tempSelectedEventCountries = [];
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
  Widget _buildFilterTile<T>({
    required BuildContext context,
    required String title,
    required int selectedCount,
    required String routeName,
    required List<T> currentSelectionData,
    required void Function(List<T>)? onResult,
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
      onTap:
          enabled // Only allow tap if enabled
          ? () async {
              final result = await context.pushNamed<List<T>>(
                routeName,
                extra: currentSelectionData,
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
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.headlinesFeedFilterResetButton,
            onPressed: () {
              context.read<HeadlinesFeedBloc>().add(
                HeadlinesFeedFiltersCleared(
                  adThemeStyle: AdThemeStyle.fromTheme(Theme.of(context)),
                ),
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
                topics: _tempSelectedTopics.isNotEmpty
                    ? _tempSelectedTopics
                    : null,
                sources: _tempSelectedSources.isNotEmpty
                    ? _tempSelectedSources
                    : null,
                eventCountries: _tempSelectedEventCountries.isNotEmpty
                    ? _tempSelectedEventCountries
                    : null,
                isFromFollowedItems: _useFollowedFilters,
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
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingSmall,
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
                    _clearTemporaryFilters();
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
          _buildFilterTile<Topic>(
            context: context,
            title: l10n.headlinesFeedFilterTopicLabel,
            enabled: !_useFollowedFilters && !_isLoadingFollowedFilters,
            selectedCount: _tempSelectedTopics.length,
            routeName: Routes.feedFilterTopicsName,
            currentSelectionData: _tempSelectedTopics,
            onResult: (result) {
              setState(() => _tempSelectedTopics = result);
            },
          ),
          _buildFilterTile<Source>(
            context: context,
            title: l10n.headlinesFeedFilterSourceLabel,
            enabled: !_useFollowedFilters && !_isLoadingFollowedFilters,
            selectedCount: _tempSelectedSources.length,
            routeName: Routes.feedFilterSourcesName,
            currentSelectionData: _tempSelectedSources,
            onResult: (result) {
              setState(() => _tempSelectedSources = result);
            },
          ),
          _buildFilterTile<Country>(
            context: context,
            title: l10n.headlinesFeedFilterEventCountryLabel,
            enabled: !_useFollowedFilters && !_isLoadingFollowedFilters,
            selectedCount: _tempSelectedEventCountries.length,
            routeName: Routes.feedFilterEventCountriesName,
            currentSelectionData: _tempSelectedEventCountries,
            onResult: (result) {
              setState(() => _tempSelectedEventCountries = result);
            },
          ),
        ],
      ),
    );
  }
}
