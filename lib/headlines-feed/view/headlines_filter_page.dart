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
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
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
  const HeadlinesFilterPage({
    required this.initialFilter,
    this.filterToEdit,
    super.key,
  });

  /// The filter state from the feed, used to initialize the filter page.
  final HeadlineFilter initialFilter;

  /// An optional existing filter passed when in 'edit' mode.
  /// If this is not null, the page will update the existing filter instead of
  /// creating a new one.
  final SavedHeadlineFilter? filterToEdit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          HeadlinesFilterBloc(
            topicsRepository: context.read<DataRepository<Topic>>(),
            sourcesRepository: context.read<DataRepository<Source>>(),
            countriesRepository: context.read<DataRepository<Country>>(),
          )..add(
            FilterDataLoaded(
              initialSelectedTopics: initialFilter.topics ?? [],
              initialSelectedSources: initialFilter.sources ?? [],
              initialSelectedCountries: initialFilter.eventCountries ?? [],
            ),
          ),
      child: _HeadlinesFilterView(
        initialFilter: initialFilter,
        filterToEdit: filterToEdit,
      ),
    );
  }
}

/// Builds a [ListTile] representing a filter criterion (e.g., Categories).
///
/// Displays the criterion [title], the number of currently selected items
/// ([selectedCount]), and navigates to the corresponding selection page
/// specified by [routeName] when tapped.
Widget _buildFilterTile({
  required BuildContext context,
  required AppLocalizations l10n,
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
Future<void> _onApplyTapped(
  BuildContext context,
  SavedHeadlineFilter? filterToEdit,
) async {
  final l10n = AppLocalizationsX(context).l10n;

  // If we are editing, skip the 'Apply Only' vs 'Save' dialog.
  if (filterToEdit != null) {
    await _updateAndApplyFilter(context, filterToEdit);
    return;
  }

  await showDialog<void>(
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
              // Apply the filter and exit the filter page.
              _applyAndExit(context);
            },
          ),
          FilledButton(
            child: Text(l10n.applyFilterDialogApplyAndSaveButton),
            onPressed: () {
              // Pop the dialog first.
              Navigator.of(dialogContext).pop();
              // Initiate the save and apply flow.
              _createAndApplyFilter(context);
            },
          ),
        ],
      );
    },
  );
}

/// Initiates the process of creating and saving a new filter.
///
/// It checks for content limitations, shows the naming dialog, creates the
/// new [SavedHeadlineFilter], adds it to the global state, and applies it
/// to the feed.
Future<void> _createAndApplyFilter(BuildContext context) async {
  // Before showing the save dialog, check if the user is allowed to save
  // another filter based on their subscription level and current usage.
  final contentLimitationService = context.read<ContentLimitationService>();
  final limitationStatus = contentLimitationService.checkAction(
    ContentAction.saveHeadlineFilter,
  );

  // If the user has reached their limit, show the limitation bottom sheet
  // and halt the save process.
  if (limitationStatus != LimitationStatus.allowed) {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) =>
          ContentLimitationBottomSheet(status: limitationStatus),
    );
    return;
  }

  final filterState = context.read<HeadlinesFilterBloc>().state;

  // `showDialog` returns a Future that completes when the dialog is popped.
  // We await its result (`true` on successful save) to synchronize navigation.
  final didSave = await showDialog<bool>(
    context: context,
    builder: (_) {
      return SaveFilterDialog(
        onSave: (name) {
          // This callback is executed when the user submits the save dialog.
          final newFilter = SavedHeadlineFilter(
            id: const Uuid().v4(),
            name: name,
            // The userId will be populated by the backend upon persistence.
            userId: '',
            criteria: HeadlineFilterCriteria(
              topics: filterState.selectedTopics.toList(),
              sources: filterState.selectedSources.toList(),
              countries: filterState.selectedCountries.toList(),
            ),
            // For this iteration, pinning and notifications are not yet
            // implemented in the UI. Default to false/empty.
            isPinned: false,
            deliveryTypes: const {},
          );
          // Add the new filter to the global AppBloc state.
          context.read<AppBloc>().add(
            SavedHeadlineFilterAdded(filter: newFilter),
          );

          // Apply the newly saved filter to the HeadlinesFeedBloc. The page
          // is not popped here; that action is deferred until after the
          // dialog has been successfully dismissed.
          _applyFilter(context, savedFilter: newFilter);
        },
      );
    },
  );

  // After the dialog is popped and we have the result, check if the save
  // was successful and if the widget is still in the tree.
  // This check prevents the "Don't use 'BuildContext's across async gaps"
  // lint warning and ensures we don't try to pop a disposed context.
  if (didSave == true && context.mounted) {
    context.pop();
  }
}

/// Initiates the process of updating an existing filter.
///
/// It shows the `SaveFilterDialog` pre-filled with the existing filter's
/// metadata, allowing the user to change the name, pinned status, or
/// notification settings.
Future<void> _updateAndApplyFilter(
  BuildContext context,
  SavedHeadlineFilter filterToEdit,
) async {
  final filterState = context.read<HeadlinesFilterBloc>().state;

  // Show the dialog, pre-filled with the existing filter's name.
  // The dialog will be enhanced in a later step to handle pinning and
  // notifications.
  final didSave = await showDialog<bool>(
    context: context,
    builder: (_) {
      return SaveFilterDialog(
        initialValue: filterToEdit.name,
        onSave: (name) {
          // Create the updated filter object with new criteria and metadata.
          final updatedFilter = filterToEdit.copyWith(
            name: name,
            criteria: HeadlineFilterCriteria(
              topics: filterState.selectedTopics.toList(),
              sources: filterState.selectedSources.toList(),
              countries: filterState.selectedCountries.toList(),
            ),
          );

          // Dispatch an update event to the global AppBloc.
          context.read<AppBloc>().add(
            SavedHeadlineFilterUpdated(filter: updatedFilter),
          );

          // Apply the updated filter to the feed.
          _applyFilter(context, savedFilter: updatedFilter);
        },
      );
    },
  );

  if (didSave == true && context.mounted) {
    context.pop();
  }
}

/// Applies the current filter selections to the feed and pops the page.
///
/// If a [savedFilter] is provided, it's passed to the event to ensure
/// its chip is correctly selected on the feed. Otherwise, the filter is
/// treated as a "custom" one.
void _applyFilter(BuildContext context, {SavedHeadlineFilter? savedFilter}) {
  final filterState = context.read<HeadlinesFilterBloc>().state;
  // The HeadlinesFeedBloc is now read directly from the context, which is
  // guaranteed to have it due to the BlocProvider.value in the router.
  // This resolves the ProviderNotFoundException.
  final headlinesFeedBloc = context.read<HeadlinesFeedBloc>();

  // Create a new HeadlineFilter from the current selections in the filter bloc.
  final newFilter = HeadlineFilter(
    topics: filterState.selectedTopics.toList(),
    sources: filterState.selectedSources.toList(),
    eventCountries: filterState.selectedCountries.toList(),
  );
  headlinesFeedBloc.add(
    HeadlinesFeedFiltersApplied(
      filter: newFilter,
      savedFilter: savedFilter,
      adThemeStyle: AdThemeStyle.fromTheme(Theme.of(context)),
    ),
  );
}

/// Applies the filter as a "custom" one-time filter and exits the page.
void _applyAndExit(BuildContext context) {
  // This helper method now separates applying the filter from exiting.
  // It's called for the "Apply Only" flow.
  _applyFilter(context);
  context.pop();
}

class _HeadlinesFilterView extends StatelessWidget {
  const _HeadlinesFilterView({required this.initialFilter, this.filterToEdit});

  final HeadlineFilter initialFilter;
  final SavedHeadlineFilter? filterToEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    // Watch both AppBloc and HeadlinesFilterBloc to react to changes in either.
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, appState) {
        return BlocBuilder<HeadlinesFilterBloc, HeadlinesFilterState>(
          builder: (context, filterState) {
            final theme = Theme.of(context);

            // Determine if the reset button should be enabled. It's enabled only
            // if there are active selections to clear.
            final isResetEnabled =
                filterState.selectedTopics.isNotEmpty ||
                filterState.selectedSources.isNotEmpty ||
                filterState.selectedCountries.isNotEmpty;

            // Determine if the "Apply" button should be enabled.
            final isFilterEmpty =
                filterState.selectedTopics.isEmpty &&
                filterState.selectedSources.isEmpty &&
                filterState.selectedCountries.isEmpty;

            // When editing, a duplicate check is not needed.
            final isEditing = filterToEdit != null;

            final savedHeadlineFilters =
                appState.userContentPreferences?.savedHeadlineFilters ?? [];

            // Check if the current selection matches any existing saved filter.
            // This check is skipped if we are in edit mode.
            final isDuplicate =
                !isEditing &&
                savedHeadlineFilters.any(
                  (savedHeadlineFilter) =>
                      setEquals(
                        savedHeadlineFilter.criteria.topics.toSet(),
                        filterState.selectedTopics,
                      ) &&
                      setEquals(
                        savedHeadlineFilter.criteria.sources.toSet(),
                        filterState.selectedSources,
                      ) &&
                      setEquals(
                        savedHeadlineFilter.criteria.countries.toSet(),
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
                  // Reset button to clear local selections on this page.
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: l10n.headlinesFeedFilterResetButton,
                    // The button is disabled if there are no selections to clear.
                    onPressed: isResetEnabled
                        ? () => context.read<HeadlinesFilterBloc>().add(
                            const FilterSelectionsCleared(),
                          )
                        : null,
                  ),
                  // Apply Filters Button
                  IconButton(
                    icon: const Icon(Icons.check),
                    tooltip: l10n.headlinesFeedFilterApplyButton,
                    // Disable the button if the filter is empty or a duplicate.
                    onPressed: isApplyEnabled || isEditing
                        ? () => _onApplyTapped(context, filterToEdit)
                        : null,
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
          context.read<HeadlinesFilterBloc>().add(
            FilterDataLoaded(
              initialSelectedTopics: initialFilter.topics ?? [],
              initialSelectedSources: initialFilter.sources ?? [],
              initialSelectedCountries: initialFilter.eventCountries ?? [],
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
          l10n: l10n,
          title: title,
          selectedCount: selectedCount,
          routeName: routeName,
        );
      },
    );
  }
}
