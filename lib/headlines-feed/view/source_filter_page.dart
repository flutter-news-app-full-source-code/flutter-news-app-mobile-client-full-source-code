// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_main/headlines-feed/bloc/sources_filter_bloc.dart';
import 'package:ht_main/headlines-feed/view/headlines_filter_page.dart'
    show keySelectedCountryIsoCodes, keySelectedSourceTypes, keySelectedSources;
import 'package:ht_main/l10n/app_localizations.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_shared/ht_shared.dart';
import 'package:ht_ui_kit/ht_ui_kit.dart';

// Keys are defined in headlines_filter_page.dart and imported by router.dart
// const String keySelectedSources = 'selectedSources';
// const String keySelectedCountryIsoCodes = 'selectedCountryIsoCodes';
// const String keySelectedSourceTypes = 'selectedSourceTypes';

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
      create: (context) =>
          SourcesFilterBloc(
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
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final state = context.watch<SourcesFilterBloc>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.headlinesFeedFilterSourceLabel,
          style: textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all_outlined),
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
              final selectedSources = state.displayableSources
                  .where((s) => state.finallySelectedSourceIds.contains(s.id))
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (state.dataLoadingStatus == SourceFilterDataLoadingStatus.loading &&
        state.allAvailableSources.isEmpty) {
      // Check allAvailableSources
      return LoadingStateWidget(
        icon: Icons.source_outlined,
        headline: l10n.sourceFilterLoadingHeadline,
        subheadline: l10n.sourceFilterLoadingSubheadline,
      );
    }
    if (state.dataLoadingStatus == SourceFilterDataLoadingStatus.failure &&
        state.allAvailableSources.isEmpty) {
      // Check allAvailableSources
      return FailureStateWidget(
        exception:
            state.error ??
            const UnknownException('Failed to load source filter data.'),
        onRetry: () {
          context.read<SourcesFilterBloc>().add(const LoadSourceFilterData());
        },
      );
    }

    return Column(
      // Removed Padding, handled by children
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCountryCapsules(context, state, l10n, textTheme),
        const SizedBox(height: AppSpacing.md),
        _buildSourceTypeCapsules(context, state, l10n, textTheme),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.paddingMedium,
          ),
          child: Text(
            l10n.headlinesFeedFilterSourceLabel,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(child: _buildSourcesList(context, state, l10n, textTheme)),
      ],
    );
  }

  Widget _buildCountryCapsules(
    BuildContext context,
    SourcesFilterState state,
    AppLocalizations l10n,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMedium,
      ).copyWith(top: AppSpacing.md),
      child: Column(
        // Use Column for label and then list
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.headlinesFeedFilterCountryLabel,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.xl + AppSpacing.md,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.availableCountries.length + 1,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ChoiceChip(
                    label: Text(l10n.headlinesFeedFilterAllLabel),
                    labelStyle: textTheme.labelLarge,
                    selected: state.selectedCountryIsoCodes.isEmpty,
                    onSelected: (_) {
                      context.read<SourcesFilterBloc>().add(
                        const CountryCapsuleToggled(''),
                      );
                    },
                  );
                }
                final country = state.availableCountries[index - 1];
                return ChoiceChip(
                  avatar: country.flagUrl.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(country.flagUrl),
                          radius: AppSpacing.sm + AppSpacing.xs,
                        )
                      : null,
                  label: Text(country.name),
                  labelStyle: textTheme.labelLarge,
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
        ],
      ),
    );
  }

  Widget _buildSourceTypeCapsules(
    BuildContext context,
    SourcesFilterState state,
    AppLocalizations l10n,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.paddingMedium),
      child: Column(
        // Use Column for label and then list
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.headlinesFeedFilterSourceTypeLabel,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.xl + AppSpacing.md,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.availableSourceTypes.length + 1,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ChoiceChip(
                    label: Text(l10n.headlinesFeedFilterAllLabel),
                    labelStyle: textTheme.labelLarge,
                    selected: state.selectedSourceTypes.isEmpty,
                    onSelected: (_) {
                      context.read<SourcesFilterBloc>().add(
                        const AllSourceTypesCapsuleToggled(),
                      );
                    },
                  );
                }
                final sourceType = state.availableSourceTypes[index - 1];
                return ChoiceChip(
                  label: Text(sourceType.name),
                  labelStyle: textTheme.labelLarge,
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
        ],
      ),
    );
  }

  Widget _buildSourcesList(
    BuildContext context,
    SourcesFilterState state,
    AppLocalizations l10n,
    TextTheme textTheme,
  ) {
    if (state.dataLoadingStatus == SourceFilterDataLoadingStatus.loading &&
        state.displayableSources.isEmpty) {
      // Added check for displayableSources
      return const Center(child: CircularProgressIndicator());
    }
    if (state.dataLoadingStatus == SourceFilterDataLoadingStatus.failure &&
        state.displayableSources.isEmpty) {
      return FailureStateWidget(
        exception:
            state.error ??
            const UnknownException('Failed to load displayable sources.'),
        onRetry: () {
          context.read<SourcesFilterBloc>().add(const LoadSourceFilterData());
        },
      );
    }
    if (state.displayableSources.isEmpty &&
        state.dataLoadingStatus != SourceFilterDataLoadingStatus.loading) {
      // Avoid showing if still loading
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingLarge),
          child: Text(
            l10n.headlinesFeedFilterNoSourcesMatch,
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.paddingSmall,
      ).copyWith(bottom: AppSpacing.xxl),
      itemCount: state.displayableSources.length,
      itemBuilder: (context, index) {
        final source = state.displayableSources[index];
        return CheckboxListTile(
          title: Text(source.name, style: textTheme.titleMedium),
          value: state.finallySelectedSourceIds.contains(source.id),
          onChanged: (bool? value) {
            if (value != null) {
              context.read<SourcesFilterBloc>().add(
                SourceCheckboxToggled(source.id, value),
              );
            }
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.paddingMedium,
          ),
        );
      },
    );
  }
}
