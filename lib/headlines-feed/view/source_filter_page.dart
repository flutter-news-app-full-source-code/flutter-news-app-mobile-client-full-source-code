// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_main/headlines-feed/bloc/sources_filter_bloc.dart';
import 'package:ht_main/headlines-feed/view/headlines_filter_page.dart'
    show keySelectedCountryIsoCodes, keySelectedSourceTypes, keySelectedSources;
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';
import 'package:ht_main/shared/widgets/failure_state_widget.dart';
import 'package:ht_main/shared/widgets/loading_state_widget.dart';
import 'package:ht_shared/ht_shared.dart' show Country, Source, SourceType;

// Keys are defined in headlines_filter_page.dart and imported by router.dart
// const String keySelectedSources = 'selectedSources'; // REMOVED
// const String keySelectedCountryIsoCodes = 'selectedCountryIsoCodes'; // REMOVED
// const String keySelectedSourceTypes = 'selectedSourceTypes'; // REMOVED

class SourceFilterPage extends StatelessWidget {
  const SourceFilterPage({
    super.key,
    this.initialSelectedSources = const [],
    this.initialSelectedCountryIsoCodes = const {},
    this.initialSelectedSourceTypes = const {},
  });

  final List<Source> initialSelectedSources;
  final Set<String> initialSelectedCountryIsoCodes;
  final Set<SourceType> initialSelectedSourceTypes;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => SourcesFilterBloc(
            sourcesRepository: context.read<HtDataRepository<Source>>(),
            countriesRepository: context.read<HtDataRepository<Country>>(),
          )..add(
            LoadSourceFilterData(
              initialSelectedSources: initialSelectedSources,
              initialSelectedCountryIsoCodes: initialSelectedCountryIsoCodes,
              initialSelectedSourceTypes: initialSelectedSourceTypes,
            ),
          ),
      child: const _SourceFilterView(),
    );
  }
}

class _SourceFilterView extends StatelessWidget {
  const _SourceFilterView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SourcesFilterBloc>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.headlinesFeedFilterSourceLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: l10n.headlinesFeedFilterResetButton,
            onPressed: () {
              context.read<SourcesFilterBloc>().add(
                const ClearSourceFiltersRequested(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () {
              final selectedSources =
                  state.displayableSources
                      .where(
                        (s) => state.finallySelectedSourceIds.contains(s.id),
                      )
                      .toList();
              // Pop with a map containing all relevant filter state
              Navigator.of(context).pop({
                keySelectedSources: selectedSources,
                keySelectedCountryIsoCodes: state.selectedCountryIsoCodes,
                keySelectedSourceTypes: state.selectedSourceTypes,
              });
            },
          ),
        ],
      ),
      body: _buildBody(context, state, l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SourcesFilterState state,
    AppLocalizations l10n,
  ) {
    if (state.dataLoadingStatus == SourceFilterDataLoadingStatus.loading &&
        state.availableCountries.isEmpty) {
      return LoadingStateWidget(
        icon: Icons.filter_list_alt, // Added generic icon
        headline: l10n.headlinesFeedFilterLoadingCriteria,
        subheadline: l10n.pleaseWait, // Added generic subheadline (l10n key)
      );
    }
    if (state.dataLoadingStatus == SourceFilterDataLoadingStatus.failure &&
        state.availableCountries.isEmpty) {
      return FailureStateWidget(
        message: state.errorMessage ?? l10n.headlinesFeedFilterErrorCriteria,
        onRetry: () {
          context.read<SourcesFilterBloc>().add(
            // When retrying, we don't have initial capsule states from arguments
            // So, we pass empty sets, BLoC will load all sources and countries.
            // User can then re-apply capsule filters if needed.
            // Or, we could try to persist/retrieve the last known good capsule state.
            // For now, simple retry reloads all.
            const LoadSourceFilterData(
              initialSelectedSources: [], // Or pass current selections if needed
              initialSelectedCountryIsoCodes: {},
              initialSelectedSourceTypes: {},
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCountryCapsules(context, state, l10n),
        const SizedBox(height: AppSpacing.lg),
        _buildSourceTypeCapsules(context, state, l10n),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: _buildSourcesList(context, state, l10n)),
      ],
    );
  }

  Widget _buildCountryCapsules(
    BuildContext context,
    SourcesFilterState state,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.paddingMedium),
      child: Row(
        children: [
          Text(
            '${l10n.headlinesFeedFilterCountryLabel}:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SizedBox(
              height: 40, // Fixed height for the capsule list
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.availableCountries.length + 1, // +1 for "All"
                separatorBuilder:
                    (context, index) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // "All" chip
                    return ChoiceChip(
                      label: Text(l10n.headlinesFeedFilterAllLabel),
                      selected: state.selectedCountryIsoCodes.isEmpty,
                      onSelected: (_) {
                        context.read<SourcesFilterBloc>().add(
                          const CountryCapsuleToggled(
                            '',
                          ), // Special value for "All"
                        );
                      },
                    );
                  }
                  final country = state.availableCountries[index - 1];
                  return ChoiceChip(
                    label: Text(country.name),
                    selected: state.selectedCountryIsoCodes.contains(
                      country.isoCode,
                    ),
                    onSelected: (_) {
                      context.read<SourcesFilterBloc>().add(
                        CountryCapsuleToggled(country.isoCode),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceTypeCapsules(
    BuildContext context,
    SourcesFilterState state,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.paddingMedium),
      child: Row(
        children: [
          Text(
            '${l10n.headlinesFeedFilterSourceTypeLabel}:', // Assuming l10n key exists
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SizedBox(
              height: 40, // Fixed height for the capsule list
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount:
                    state.availableSourceTypes.length + 1, // +1 for "All"
                separatorBuilder:
                    (context, index) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // "All" chip
                    return ChoiceChip(
                      label: Text(l10n.headlinesFeedFilterAllLabel),
                      selected: state.selectedSourceTypes.isEmpty,
                      onSelected: (_) {
                        // For "All", if it's selected, it means no specific types are chosen.
                        // The BLoC should interpret an empty selectedSourceTypes set as "All".
                        // Toggling "All" when it's already selected (meaning list is empty)
                        // doesn't have a clear action here without more complex "select all" logic.
                        // For now, if "All" is tapped, we ensure the specific selections are cleared.
                        // This is best handled in the BLoC.
                        // We can send a specific event or a toggle that the BLoC interprets.
                        // For simplicity, let's make it so tapping "All" when selected does nothing,
                        // Tapping "All" for source types should clear specific selections.
                        // This is now handled by the AllSourceTypesCapsuleToggled event.
                        context.read<SourcesFilterBloc>().add(
                          const AllSourceTypesCapsuleToggled(),
                        );
                      },
                    );
                  }
                  final sourceType = state.availableSourceTypes[index - 1];
                  return ChoiceChip(
                    label: Text(
                      sourceType.name,
                    ), // Or a more user-friendly name
                    selected: state.selectedSourceTypes.contains(sourceType),
                    onSelected: (_) {
                      context.read<SourcesFilterBloc>().add(
                        SourceTypeCapsuleToggled(sourceType),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesList(
    BuildContext context,
    SourcesFilterState state,
    AppLocalizations l10n,
  ) {
    if (state.dataLoadingStatus == SourceFilterDataLoadingStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.dataLoadingStatus == SourceFilterDataLoadingStatus.failure &&
        state.displayableSources.isEmpty) {
      return FailureStateWidget(
        message: state.errorMessage ?? l10n.headlinesFeedFilterErrorSources,
        onRetry: () {
          // Dispatch a public event to reload/retry, BLoC will handle internally
          context.read<SourcesFilterBloc>().add(
            LoadSourceFilterData(
              initialSelectedSources:
                  state.displayableSources
                      .where(
                        (s) => state.finallySelectedSourceIds.contains(s.id),
                      )
                      .toList(), // Or pass current selections if needed for retry context
            ),
          );
        },
      );
    }
    if (state.displayableSources.isEmpty) {
      return Center(child: Text(l10n.headlinesFeedFilterNoSourcesMatch));
    }

    return ListView.builder(
      itemCount: state.displayableSources.length,
      itemBuilder: (context, index) {
        final source = state.displayableSources[index];
        return CheckboxListTile(
          title: Text(source.name),
          value: state.finallySelectedSourceIds.contains(source.id),
          onChanged: (bool? value) {
            if (value != null) {
              context.read<SourcesFilterBloc>().add(
                SourceCheckboxToggled(source.id, value),
              );
            }
          },
        );
      },
    );
  }
}
