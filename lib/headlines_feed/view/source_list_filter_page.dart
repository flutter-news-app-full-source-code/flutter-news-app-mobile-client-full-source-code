// ignore_for_file: lines_longer_than_80_chars

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/extensions/extensions.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/multi_select_search_page.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template source_list_filter_page}
/// A dedicated page for selecting filter criteria for the source list.
///
/// This page allows users to filter sources by their headquarters country
/// and by their type (e.g., News Agency, Blog). It is driven by the
/// [HeadlinesFilterBloc] to maintain a centralized state.
/// {@endtemplate}
class SourceListFilterPage extends StatelessWidget {
  /// {@macro source_list_filter_page}
  const SourceListFilterPage({required this.filterBloc, super.key});

  /// The instance of [HeadlinesFilterBloc] provided by the parent route.
  final HeadlinesFilterBloc filterBloc;

  @override
  Widget build(BuildContext context) {
    // Provide the existing filterBloc to this subtree.
    return BlocProvider.value(
      value: filterBloc,
      child: const _SourceListFilterView(),
    );
  }
}

class _SourceListFilterView extends StatelessWidget {
  const _SourceListFilterView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.sourceListFilterPageTitle,
          style: textTheme.titleLarge,
        ),
        actions: [
          // The "Apply" button now just pops the page, as the state is
          // already updated in the shared BLoC.
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: BlocBuilder<HeadlinesFilterBloc, HeadlinesFilterState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              // Section for filtering by headquarters country.
              ListTile(
                title: Text(l10n.headlinesFeedFilterSourceCountryLabel),
                subtitle: Text(
                  state.selectedSourceHeadquarterCountries.isEmpty
                      ? l10n.headlinesFeedFilterAllLabel
                      : l10n.headlinesFeedFilterSelectedCountLabel(
                          state.selectedSourceHeadquarterCountries.length,
                        ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final selectedCountries = await Navigator.of(context)
                      .push<Set<Country>>(
                        MaterialPageRoute(
                          builder: (_) => MultiSelectSearchPage<Country>(
                            title: l10n.headlinesFeedFilterSourceCountryLabel,
                            allItems: state.allHeadquarterCountries,
                            initialSelectedItems: state
                                .selectedSourceHeadquarterCountries
                                .toSet(),
                            itemBuilder: (country) => country.name,
                          ),
                        ),
                      );

                  if (selectedCountries != null && context.mounted) {
                    // When the page returns, dispatch an event to the
                    // shared BLoC to update the source filter criteria.
                    context.read<HeadlinesFilterBloc>().add(
                      FilterSourceCriteriaChanged(
                        selectedCountries: selectedCountries,
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              // Section for filtering by source type.
              ListTile(
                title: Text(l10n.headlinesFeedFilterSourceTypeLabel),
                subtitle: Text(
                  state.selectedSourceTypes.isEmpty
                      ? l10n.headlinesFeedFilterAllLabel
                      : l10n.headlinesFeedFilterSelectedCountLabel(
                          state.selectedSourceTypes.length,
                        ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSourceTypeFilterDialog(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showSourceTypeFilterDialog(
    BuildContext context,
    HeadlinesFilterState state,
  ) async {
    final l10n = AppLocalizationsX(context).l10n;
    final selectedTypes = await showDialog<Set<SourceType>>(
      context: context,
      builder: (dialogContext) {
        // Use a StatefulBuilder to manage the temporary selection state
        // within the dialog itself.
        return StatefulBuilder(
          builder: (context, setState) {
            final tempSelected = Set<SourceType>.from(
              state.selectedSourceTypes,
            );

            return AlertDialog(
              title: Text(l10n.headlinesFeedFilterSourceTypeLabel),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.allSourceTypes.length,
                  itemBuilder: (context, index) {
                    final type = state.allSourceTypes[index];
                    final isSelected = tempSelected.contains(type);
                    return CheckboxListTile(
                      title: Text(type.l10n(l10n)),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            tempSelected.add(type);
                          } else {
                            tempSelected.remove(type);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancelButtonLabel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(tempSelected),
                  child: Text(l10n.applyButtonLabel),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedTypes != null && context.mounted) {
      context.read<HeadlinesFilterBloc>().add(
        FilterSourceCriteriaChanged(selectedSourceTypes: selectedTypes),
      );
    }
  }
}
