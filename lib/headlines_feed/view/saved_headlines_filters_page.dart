import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/saved_headlines_filters_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template saved_headlines_filters_page}
/// A page for managing a user's saved headline filters.
///
/// This page displays a list of all saved filters, allowing users to apply,
/// reorder, edit, or delete them. It also provides an entry point for creating
/// new filters.
/// {@endtemplate}
class SavedHeadlinesFiltersPage extends StatelessWidget {
  /// {@macro saved_headlines_filters_page}
  const SavedHeadlinesFiltersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SavedHeadlinesFiltersBloc(
        // The AppBloc is read from the context to get the initial list of
        // saved filters and to dispatch update events.
        appBloc: context.read<AppBloc>(),
      )..add(const SavedHeadlinesFiltersDataLoaded()),
      child: const SavedHeadlinesFiltersView(),
    );
  }
}

/// The main view for the SavedHeadlinesFiltersPage.
class SavedHeadlinesFiltersView extends StatelessWidget {
  const SavedHeadlinesFiltersView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.savedHeadlineFiltersPageTitle,
          style: theme.textTheme.titleLarge,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to the filter creation page, passing the necessary
          // 'extra' parameters. This includes an empty initial filter.
          // The HeadlinesFeedBloc instance is no longer passed, as it is
          // now available in the context via the router's ShellRoute.
          context.pushNamed(
            Routes.feedFilterName,
            extra: {
              'initialFilter': const HeadlineFilterCriteria(
                topics: [],
                sources: [],
                countries: [],
              ),
            },
          );
        },
        label: Text(l10n.savedHeadlineFiltersCreateNewButton),
        icon: const Icon(Icons.add),
      ),
      body: BlocBuilder<SavedHeadlinesFiltersBloc, SavedHeadlinesFiltersState>(
        builder: (context, state) {
          if (state.status == SavedHeadlinesFiltersStatus.initial ||
              state.status == SavedHeadlinesFiltersStatus.loading) {
            return LoadingStateWidget(
              icon: Icons.save_alt_outlined,
              headline: l10n.savedHeadlineFiltersLoadingHeadline,
              subheadline: l10n.pleaseWait,
            );
          }

          if (state.status == SavedHeadlinesFiltersStatus.failure) {
            return FailureStateWidget(
              exception:
                  state.error ??
                  const UnknownException('Failed to load saved filters.'),
              onRetry: () => context.read<SavedHeadlinesFiltersBloc>().add(
                const SavedHeadlinesFiltersDataLoaded(),
              ),
            );
          }

          if (state.filters.isEmpty) {
            return InitialStateWidget(
              icon: Icons.filter_list_off,
              headline: l10n.savedHeadlineFiltersEmptyHeadline,
              subheadline: l10n.savedHeadlineFiltersEmptySubheadline,
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 2),
            itemCount: state.filters.length,
            buildDefaultDragHandles: false,
            itemBuilder: (context, index) {
              final filter = state.filters[index];
              return ListTile(
                key: ValueKey(filter.id),
                leading: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    if (filter.isPinned) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.push_pin,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                    if (filter.deliveryTypes.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.notifications,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ],
                ),
                onTap: () {
                  // Apply the selected filter to the feed.
                  context.read<HeadlinesFeedBloc>().add(
                    SavedFilterSelected(
                      filter: filter,
                      adThemeStyle: AdThemeStyle.fromTheme(theme),
                    ),
                  );
                  // Pop the current page (SavedHeadlinesFiltersPage) to return
                  // to the underlying HeadlinesFeedPage, which will now show
                  // the content for the applied filter.
                  context.pop();
                },
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      // Navigate to the filter page in 'edit' mode.
                      await context.pushNamed(
                        Routes.feedFilterName,
                        extra: {
                          'initialFilter': filter.criteria,
                          'filterToEdit': filter,
                        },
                      );
                    } else if (value == 'delete') {
                      // Show a confirmation dialog before deleting.
                      final didConfirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.deleteConfirmationDialogTitle),
                          content: Text(l10n.deleteConfirmationDialogContent),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(l10n.cancelButtonLabel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                l10n.deleteConfirmationDialogConfirmButton,
                              ),
                            ),
                          ],
                        ),
                      );
                      if (didConfirm == true && context.mounted) {
                        context.read<SavedHeadlinesFiltersBloc>().add(
                          SavedHeadlinesFiltersDeleted(filterId: filter.id),
                        );
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Text(l10n.savedFiltersMenuEdit),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text(l10n.savedFiltersMenuDelete),
                        ),
                      ],
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              // When an item is moved down the list, the newIndex needs to be
              // adjusted because the item's removal from its old position
              // shifts the indices of subsequent items.
              var adjustedNewIndex = newIndex;
              if (newIndex > oldIndex) {
                adjustedNewIndex -= 1;
              }
              final reorderedFilters = List<SavedHeadlineFilter>.from(
                state.filters,
              );
              final item = reorderedFilters.removeAt(oldIndex);
              reorderedFilters.insert(adjustedNewIndex, item);
              context.read<SavedHeadlinesFiltersBloc>().add(
                SavedHeadlinesFiltersReordered(
                  reorderedFilters: reorderedFilters,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
