import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/widgets/save_filter_dialog.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template manage_saved_filters_page}
/// A page for managing saved feed filters.
///
/// Allows users to rename or delete their saved filters.
/// {@endtemplate}
class ManageSavedFiltersPage extends StatelessWidget {
  /// {@macro manage_saved_filters_page}
  const ManageSavedFiltersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.manageFiltersPageTitle,
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          final savedFilters = state.userContentPreferences?.savedFilters ?? [];

          if (savedFilters.isEmpty) {
            return InitialStateWidget(
              icon: Icons.filter_list_off_outlined,
              headline: l10n.manageFiltersEmptyHeadline,
              subheadline: l10n.manageFiltersEmptySubheadline,
            );
          }

          return ListView.separated(
            itemCount: savedFilters.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final filter = savedFilters[index];
              return ListTile(
                title: Text(filter.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: l10n.manageFiltersRenameTooltip,
                      onPressed: () {
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
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: l10n.manageFiltersDeleteTooltip,
                      onPressed: () {
                        context.read<AppBloc>().add(
                          SavedFilterDeleted(filterId: filter.id),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
