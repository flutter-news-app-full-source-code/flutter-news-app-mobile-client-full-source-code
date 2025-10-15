import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/models/headline_filter.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/widgets/save_filter_dialog.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:uuid/uuid.dart';

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
      create: (context) =>
          HeadlinesFilterBloc(
            topicsRepository: context.read<DataRepository<Topic>>(),
            sourcesRepository: context.read<DataRepository<Source>>(),
            countriesRepository: context.read<DataRepository<Country>>(),
          )..add(
            FilterDataLoaded(
              initialSelectedTopics: currentFilter.topics ?? [],
              initialSelectedSources: currentFilter.sources ?? [],
              initialSelectedCountries: currentFilter.eventCountries ?? [],
            ),
          ),
      child: const _HeadlinesFilterView(),
    );
  }
}

class _HeadlinesFilterView extends StatefulWidget {
  const _HeadlinesFilterView();

  @override
  State<_HeadlinesFilterView> createState() => _HeadlinesFilterViewState();
}

class _HeadlinesFilterViewState extends State<_HeadlinesFilterView> {
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
              // Navigate to the child filter page, passing the current
              // HeadlinesFilterBloc instance as an extra argument.
              // This ensures the child page can access the bloc directly.
              context.pushNamed(
                routeName,
                extra: context.read<HeadlinesFilterBloc>(),
              );
            }
          : null,
    );
  }

  /// Shows the dialog to let the user choose between applying the filter
  /// for one-time use or saving it for future use.
  Future<void> _showApplyOptionsDialog() async {
    final l10n = AppLocalizationsX(context).l10n;
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.applyFilterDialogTitle),
          content: Text(l10n.applyFilterDialogContent),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.applyFilterDialogApplyOnlyButton),
              onPressed: () {
                // Pop the dialog first.
                Navigator.of(dialogContext).pop();
                // Apply the filter as a "custom" one-time filter.
                _applyAndExit(null);
              },
            ),
            FilledButton(
              child: Text(l10n.applyFilterDialogApplyAndSaveButton),
              onPressed: () {
                // Pop the dialog first.
                Navigator.of(dialogContext).pop();
                // Initiate the save and apply flow.
                _saveAndApplyFilter();
              },
            ),
          ],
        );
      },
    );
  }

  /// Initiates the process of saving a filter by showing the naming dialog,
  /// and then applies it.
  ///
  /// This function `await`s the result of the `SaveFilterDialog`. This is
  /// crucial to prevent a race condition where the `HeadlinesFilterPage` might
  /// be popped before the dialog is fully dismissed, which was causing a
  /// navigation stack error and a black screen.
  Future<void> _saveAndApplyFilter() async {
    final filterState = context.read<HeadlinesFilterBloc>().state;

    // `showDialog` returns a Future that completes when the dialog is popped.
    // We await its result (`true` on successful save) to synchronize navigation.
    final didSave = await showDialog<bool>(
      context: context,
      builder: (_) {
        return SaveFilterDialog(
          onSave: (name) {
            // This callback is executed when the user submits the save dialog.
            final newFilter = SavedFilter(
              id: const Uuid().v4(),
              name: name,
              topics: filterState.selectedTopics.toList(),
              sources: filterState.selectedSources.toList(),
              countries: filterState.selectedCountries.toList(),
            );
            // Add the new filter to the global AppBloc state.
            context.read<AppBloc>().add(SavedFilterAdded(filter: newFilter));

            // Apply the filter to the HeadlinesFeedBloc. The page is not
            // popped here; that action is deferred until after the dialog
            // has been successfully dismissed.
            _applyFilter(newFilter);
          },
        );
      },
    );

    // After the dialog is popped and we have the result, check if the save
    // was successful and if the widget is still in the tree.
    // This check prevents the "Don't use 'BuildContext's across async gaps"
    // lint warning and ensures we don't try to pop a disposed context.
    if (didSave == true && mounted) {
      context.pop();
    }
  }

  /// Applies the current filter selections to the feed and pops the page.
  ///
  /// If a [savedFilter] is provided, it's passed to the event to ensure
  /// its chip is correctly selected on the feed. Otherwise, the filter is
  /// treated as a "custom" one.
  void _applyFilter(SavedFilter? savedFilter) {
    final filterState = context.read<HeadlinesFilterBloc>().state;
    final newFilter = HeadlineFilter(
      topics: filterState.selectedTopics.toList(),
      sources: filterState.selectedSources.toList(),
      eventCountries: filterState.selectedCountries.toList(),
    );
    context.read<HeadlinesFeedBloc>().add(
      HeadlinesFeedFiltersApplied(
        filter: newFilter,
        savedFilter: savedFilter,
        adThemeStyle: AdThemeStyle.fromTheme(Theme.of(context)),
      ),
    );
  }

  void _applyAndExit(SavedFilter? savedFilter) {
    // This helper method now separates applying the filter from exiting.
    // It's called for the "Apply Only" flow.
    _applyFilter(savedFilter);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    // Watch both AppBloc and HeadlinesFilterBloc to react to changes in either.
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, appState) {
        return BlocBuilder<HeadlinesFilterBloc, HeadlinesFilterState>(
          builder: (context, filterState) {
            final theme = Theme.of(context);

            // Determine if the "Apply" button should be enabled.
            final isFilterEmpty =
                filterState.selectedTopics.isEmpty &&
                filterState.selectedSources.isEmpty &&
                filterState.selectedCountries.isEmpty;

            final savedFilters =
                appState.userContentPreferences?.savedFilters ?? [];

            // Check if the current selection matches any existing saved filter.
            final isDuplicate = savedFilters.any(
              (savedFilter) =>
                  setEquals(
                    savedFilter.topics.toSet(),
                    filterState.selectedTopics,
                  ) &&
                  setEquals(
                    savedFilter.sources.toSet(),
                    filterState.selectedSources,
                  ) &&
                  setEquals(
                    savedFilter.countries.toSet(),
                    filterState.selectedCountries,
                  ),
            );

            final isApplyEnabled = !isFilterEmpty && !isDuplicate;

            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  l10n.headlinesFeedFilterTitle,
                  style: theme.textTheme.titleLarge,
                ),
                actions: [
                  // Reset All Filters Button
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: l10n.headlinesFeedFilterResetButton,
                    onPressed: () {
                      // Dispatch event to clear filters in the feed bloc
                      // and trigger a refresh to the "All" state.
                      context.read<HeadlinesFeedBloc>().add(
                        AllFilterSelected(
                          adThemeStyle: AdThemeStyle.fromTheme(theme),
                        ),
                      );
                      // Close the filter page.
                      context.pop();
                    },
                  ),
                  // Manage Saved Filters Button
                  IconButton(
                    tooltip: l10n.headlinesFilterManageTooltip,
                    icon: const Icon(Icons.edit_note_outlined),
                    onPressed: () =>
                        context.pushNamed(Routes.manageSavedFiltersName),
                  ),
                  // Apply Filters Button
                  IconButton(
                    icon: const Icon(Icons.check),
                    tooltip: l10n.headlinesFeedFilterApplyButton,
                    // Disable the button if the filter is empty or a duplicate.
                    onPressed: isApplyEnabled ? _showApplyOptionsDialog : null,
                  ),
                ],
              ),
              body: _buildBody(context, l10n, filterState),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    HeadlinesFilterState filterState,
  ) {
    if (filterState.status == HeadlinesFilterStatus.loading) {
      return LoadingStateWidget(
        icon: Icons.filter_list,
        headline: l10n.headlinesFeedFilterLoadingHeadline,
        subheadline: l10n.pleaseWait,
      );
    }

    if (filterState.status == HeadlinesFilterStatus.failure) {
      return FailureStateWidget(
        exception:
            filterState.error ??
            const UnknownException('Failed to load filter data.'),
        onRetry: () {
          final headlinesFeedBloc = context.read<HeadlinesFeedBloc>();
          final currentFilter = headlinesFeedBloc.state.filter;
          context.read<HeadlinesFilterBloc>().add(
            FilterDataLoaded(
              initialSelectedTopics: currentFilter.topics ?? [],
              initialSelectedSources: currentFilter.sources ?? [],
              initialSelectedCountries: currentFilter.eventCountries ?? [],
            ),
          );
        },
      );
    }

    // Use a Map to define the filter tiles for cleaner code.
    final filterTiles = {
      l10n.headlinesFeedFilterTopicLabel: Routes.feedFilterTopicsName,
      l10n.headlinesFeedFilterSourceLabel: Routes.feedFilterSourcesName,
      l10n.headlinesFeedFilterEventCountryLabel:
          Routes.feedFilterEventCountriesName,
    };

    return ListView.separated(
      itemCount: filterTiles.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final title = filterTiles.keys.elementAt(index);
        final routeName = filterTiles.values.elementAt(index);
        int selectedCount;

        if (routeName == Routes.feedFilterTopicsName) {
          selectedCount = filterState.selectedTopics.length;
        } else if (routeName == Routes.feedFilterSourcesName) {
          selectedCount = filterState.selectedSources.length;
        } else {
          selectedCount = filterState.selectedCountries.length;
        }

        return _buildFilterTile(
          context: context,
          title: title,
          selectedCount: selectedCount,
          routeName: routeName,
        );
      },
    );
  }
}
