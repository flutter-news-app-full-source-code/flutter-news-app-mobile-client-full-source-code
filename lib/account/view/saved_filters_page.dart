import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/confirmation_dialog.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/widgets/save_filter_dialog.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template saved_filters_page}
/// A page for managing saved feed filters, allowing users to reorder,
/// rename, or delete them.
///
/// Reordering is handled via a [ReorderableListView], which dispatches a
/// [SavedFiltersReordered] event to the [AppBloc] to persist the new order.
/// Renaming and deletion are handled via a [PopupMenuButton] on each list item.
/// {@endtemplate}
class SavedFiltersPage extends StatelessWidget {
  /// {@macro saved_filters_page}
  const SavedFiltersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
        title: Text(
          // Use the correct localization key for the page title.
          l10n.savedFiltersPageTitle,
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          final savedFilters = state.userContentPreferences?.savedFilters ?? [];

          if (savedFilters.isEmpty) {
            return InitialStateWidget(
              icon: Icons.filter_list_off_outlined,
              headline: l10n.savedFiltersEmptyHeadline,
              subheadline: l10n.savedFiltersEmptySubheadline,
            );
          }

          return ReorderableListView.builder(
            // Disable the default trailing drag handles to use only the
            // custom leading handle.
            buildDefaultDragHandles: false,
            itemCount: savedFilters.length,
            itemBuilder: (context, index) {
              final filter = savedFilters[index];
              return ListTile(
                // A key is required for ReorderableListView to work correctly.
                key: ValueKey(filter.id),
                leading: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
                title: Text(filter.name),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'rename':
                        showDialog<void>(
                          context: context,
                          builder: (_) => SaveFilterDialog(
                            initialValue: filter.name,
                            onSave: (newName) {
                              final updatedFilter = filter.copyWith(
                                name: newName,
                              );
                              context.read<AppBloc>().add(
                                SavedFilterUpdated(filter: updatedFilter),
                              );
                            },
                          ),
                        );
                      case 'delete':
                        // Awaiting the dialog result ensures the popup menu
                        // has time to close before the list rebuilds,
                        // preventing the red screen flicker.
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => ConfirmationDialog(
                            title: l10n.deleteConfirmationDialogTitle,
                            content: l10n.deleteConfirmationDialogContent,
                            confirmButtonText:
                                l10n.deleteConfirmationDialogConfirmButton,
                          ),
                        );

                        // Only proceed with deletion if the user confirmed
                        // and the widget is still mounted.
                        if (confirmed == true && context.mounted) {
                          context.read<AppBloc>().add(
                            SavedFilterDeleted(filterId: filter.id),
                          );
                        }
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'rename',
                          child: Text(l10n.savedFiltersMenuRename),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text(
                            l10n.savedFiltersMenuDelete,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              // This adjustment is necessary when moving an item downwards
              // in the list.
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }

              // Create a mutable copy of the list.
              final reorderedList = List<SavedFilter>.from(savedFilters);

              // Remove the item from its old position and insert it into the
              // new position.
              final movedFilter = reorderedList.removeAt(oldIndex);
              reorderedList.insert(newIndex, movedFilter);

              // Dispatch the event to the AppBloc to persist the new order.
              context.read<AppBloc>().add(
                SavedFiltersReordered(reorderedFilters: reorderedList),
              );
            },
          );
        },
      ),
    );
  }
}
