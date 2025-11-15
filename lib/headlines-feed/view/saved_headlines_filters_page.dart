import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/saved_headlines_filters_bloc.dart';
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
      child: const _SavedHeadlinesFiltersView(),
    );
  }
}

/// The main view for the SavedHeadlinesFiltersPage.
class _SavedHeadlinesFiltersView extends StatelessWidget {
  const _SavedHeadlinesFiltersView();

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
          // 'extra' parameters. This includes an empty initial filter and
          // the HeadlinesFeedBloc instance for the page to communicate back.
          context.pushNamed(
            Routes.feedFilterName,
            extra: {
              'initialFilter': const HeadlineFilterCriteria(topics: [], sources: [], countries: []),
              'headlinesFeedBloc': context.read<HeadlinesFeedBloc>(),
              'filterToEdit': null,
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
              exception: state.error ??
                  const UnknownException('Failed to load saved filters.'),
              onRetry: () => context
                  .read<SavedHeadlinesFiltersBloc>()
                  .add(const SavedHeadlinesFiltersDataLoaded()),
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
                title: Text(filter.name),
                subtitle: (filter.isPinned || filter.deliveryTypes.isNotEmpty)
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Row(
                          children: [
                            if (filter.isPinned)
                              _IndicatorChip(
                                icon: Icons.push_pin,
                                label: l10n.saveFilterDialogPinToFeedLabel,
                              ),
                            if (filter.deliveryTypes.isNotEmpty) ...[
                              if (filter.isPinned)
                                const SizedBox(width: AppSpacing.sm),
                              _IndicatorChip(
                                icon: Icons.notifications,
                                label: l10n.saveFilterDialogNotificationsLabel,
                              ),
                            ],
                          ],
                        ),
                      )
                    : null,
                onTap: () {
                  // Apply the selected filter to the feed.
                  context.read<HeadlinesFeedBloc>().add(
                        SavedFilterSelected(
                          filter: filter,
                          adThemeStyle: AdThemeStyle.fromTheme(theme),
                        ),
                      );
                  // Pop back to the feed page.
                  context.pop();
                },
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      // Navigate to the filter page in 'edit' mode.
                      context.pushNamed(
                        Routes.feedFilterName,
                        extra: {
                          'initialFilter': filter.criteria,
                          'headlinesFeedBloc':
                              context.read<HeadlinesFeedBloc>(),
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
                              SavedHeadlinesFiltersDeleted(
                                filterId: filter.id,
                              ),
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
              // Adjust the index for reordering logic.
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final reorderedFilters = List<SavedHeadlineFilter>.from(
                state.filters,
              );
              final item = reorderedFilters.removeAt(oldIndex);
              reorderedFilters.insert(newIndex, item);
              context.read<SavedHeadlinesFiltersBloc>().add(
                    SavedHeadlineFiltersReordered(
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

/// A small, styled chip used as a visual indicator for filter properties.
class _IndicatorChip extends StatelessWidget {
  const _IndicatorChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: theme.colorScheme.secondary,
      ),
      label: Text(label),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.secondary,
      ),
      backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.25),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      visualDensity: VisualDensity.compact,
    );
  }
}
