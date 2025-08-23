// ignore_for_file: lines_longer_than_80_chars

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart'; // Import AppBloc
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/sources_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart';

// Keys are defined in headlines_filter_page.dart and imported by router.dart
/// {@template source_filter_page}
/// A page dedicated to selecting news sources for filtering headlines.
///
/// This page allows users to refine the displayed list of sources using
/// country and source type capsules. However, these internal UI filter
/// selections (country and source type) are *not* returned or persisted
/// outside this page. Its sole purpose is to return the list of
/// *explicitly checked* [Source] items.
/// {@endtemplate}
class SourceFilterPage extends StatelessWidget {
  /// {@macro source_filter_page}
  const SourceFilterPage({super.key, this.initialSelectedSources = const []});

  /// The list of sources that were initially selected on the previous page.
  final List<Source> initialSelectedSources;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SourcesFilterBloc(
            sourcesRepository: context.read<DataRepository<Source>>(),
            countriesRepository: context.read<DataRepository<Country>>(),
            userContentPreferencesRepository: context
                .read<DataRepository<UserContentPreferences>>(),
            appBloc: context.read<AppBloc>(),
          )..add(
            LoadSourceFilterData(
              initialSelectedSources: initialSelectedSources,
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
          // Apply My Followed Sources Button
          BlocBuilder<SourcesFilterBloc, SourcesFilterState>(
            builder: (context, state) {
              // Determine if the "Apply My Followed" icon should be filled
              final isFollowedFilterActive =
                  state.followedSources.isNotEmpty &&
                  state.finallySelectedSourceIds.length ==
                      state.followedSources.length &&
                  state.followedSources.every(
                    (source) =>
                        state.finallySelectedSourceIds.contains(source.id),
                  );

              return IconButton(
                icon: isFollowedFilterActive
                    ? const Icon(Icons.favorite)
                    : const Icon(Icons.favorite_border),
                color: isFollowedFilterActive
                    ? theme.colorScheme.primary
                    : null,
                tooltip: l10n.headlinesFeedFilterApplyFollowedLabel,
                onPressed:
                    state.followedSourcesStatus ==
                        SourceFilterDataLoadingStatus.loading
                    ? null // Disable while loading
                    : () {
                        // Dispatch event to BLoC to fetch and apply followed sources
                        context.read<SourcesFilterBloc>().add(
                          SourcesFilterApplyFollowedRequested(),
                        );
                      },
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
              Navigator.of(context).pop(selectedSources);
            },
          ),
        ],
      ),
      body: BlocListener<SourcesFilterBloc, SourcesFilterState>(
        listenWhen: (previous, current) =>
            previous.followedSourcesStatus != current.followedSourcesStatus ||
            previous.followedSources != current.followedSources,
        listener: (context, state) {
          if (state.followedSourcesStatus ==
              SourceFilterDataLoadingStatus.success) {
            if (state.followedSources.isEmpty) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(l10n.noFollowedItemsForFilterSnackbar),
                    duration: const Duration(seconds: 3),
                  ),
                );
            }
          } else if (state.followedSourcesStatus ==
              SourceFilterDataLoadingStatus.failure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.error?.message ?? l10n.unknownError),
                  duration: const Duration(seconds: 3),
                ),
              );
          }
        },
        child: BlocBuilder<SourcesFilterBloc, SourcesFilterState>(
          builder: (context, state) {
            final isLoadingMainList =
                state.dataLoadingStatus ==
                    SourceFilterDataLoadingStatus.loading &&
                state.allAvailableSources.isEmpty;
            final isLoadingFollowedSources =
                state.followedSourcesStatus ==
                SourceFilterDataLoadingStatus.loading;

            if (isLoadingMainList) {
              return LoadingStateWidget(
                icon: Icons.source_outlined,
                headline: l10n.sourceFilterLoadingHeadline,
                subheadline: l10n.sourceFilterLoadingSubheadline,
              );
            }
            if (state.dataLoadingStatus ==
                    SourceFilterDataLoadingStatus.failure &&
                state.allAvailableSources.isEmpty) {
              return FailureStateWidget(
                exception:
                    state.error ??
                    const UnknownException(
                      'Failed to load source filter data.',
                    ),
                onRetry: () {
                  context.read<SourcesFilterBloc>().add(
                    const LoadSourceFilterData(),
                  );
                },
              );
            }

            return Stack(
              children: [
                Column(
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
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: _buildSourcesList(context, state, l10n, textTheme),
                    ),
                  ],
                ),
                // Show loading overlay if followed sources are being fetched
                if (isLoadingFollowedSources)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black54, // Semi-transparent overlay
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.headlinesFeedLoadingHeadline,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.headlinesFeedFilterSourceCountryLabel,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.xl + AppSpacing.md,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.countriesWithActiveSources.length + 1,
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
                final country = state.countriesWithActiveSources[index - 1];
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
