import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
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
        onPressed: () => context.goNamed(Routes.feedFilterName),
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
            itemBuilder: (context, index) {
              final filter = state.filters[index];
              return Dismissible(
                key: ValueKey(filter.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  context.read<SavedHeadlinesFiltersBloc>().add(
                    SavedHeadlinesFiltersDeleted(filterId: filter.id),
                  );
                },
                background: Container(
                  color: theme.colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.onError,
                  ),
                ),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(filter.name),
                  // TODO(fulleni): Add onTap to edit the filter name.
                  onTap: () {},
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
