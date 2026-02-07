import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/shared.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template source_type_filter_page}
/// A page for selecting source types for filtering the source list.
///
/// This page is driven by the centralized [HeadlinesFilterBloc].
/// {@endtemplate}
class SourceTypeFilterPage extends StatelessWidget {
  /// {@macro source_type_filter_page}
  const SourceTypeFilterPage({required this.filterBloc, super.key});

  /// The instance of [HeadlinesFilterBloc] provided by the parent route.
  final HeadlinesFilterBloc filterBloc;

  @override
  Widget build(BuildContext context) {
    // Provide the existing filterBloc to this subtree.
    return BlocProvider.value(
      value: filterBloc,
      child: const _SourceTypeFilterView(),
    );
  }
}

class _SourceTypeFilterView extends StatelessWidget {
  const _SourceTypeFilterView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.headlinesFeedFilterSourceTypeLabel,
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          // Apply button just pops the page.
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: BlocBuilder<HeadlinesFilterBloc, HeadlinesFilterState>(
        builder: (context, state) {
          if (state.allSourceTypes.isEmpty) {
            return InitialStateWidget(
              icon: Icons.sell_outlined,
              headline: l10n.sourceTypeFilterEmptyHeadline,
              subheadline: l10n.sourceTypeFilterEmptySubheadline,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
            ).copyWith(bottom: AppSpacing.xxl),
            itemCount: state.allSourceTypes.length,
            itemBuilder: (context, index) {
              final sourceType = state.allSourceTypes[index];
              final isSelected = state.selectedSourceTypes.contains(sourceType);

              return CheckboxListTile(
                title: Text(sourceType.l10n(l10n)),
                value: isSelected,
                onChanged: (bool? value) {
                  if (value == null) return;

                  final newSelection = Set<SourceType>.from(
                    state.selectedSourceTypes,
                  );
                  if (value) {
                    newSelection.add(sourceType);
                  } else {
                    newSelection.remove(sourceType);
                  }
                  context.read<HeadlinesFilterBloc>().add(
                    FilterSourceCriteriaChanged(
                      selectedSourceTypes: newSelection,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
