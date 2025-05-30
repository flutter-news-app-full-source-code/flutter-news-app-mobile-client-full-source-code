import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/headlines-feed/bloc/sources_filter_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';
import 'package:ht_main/shared/widgets/widgets.dart';
import 'package:ht_shared/ht_shared.dart';
import 'package:ht_data_repository/ht_data_repository.dart';

/// {@template add_source_to_follow_page}
/// A page that allows users to browse and select sources to follow.
/// {@endtemplate}
class AddSourceToFollowPage extends StatelessWidget {
  /// {@macro add_source_to_follow_page}
  const AddSourceToFollowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (context) => SourcesFilterBloc(
        sourcesRepository: context.read<HtDataRepository<Source>>(),
        countriesRepository: context.read<HtDataRepository<Country>>(),
      )..add(const LoadSourceFilterData()), // Use correct event
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.addSourcesPageTitle),
        ),
        body: BlocBuilder<SourcesFilterBloc, SourcesFilterState>(
          builder: (context, sourcesState) {
            if (sourcesState.dataLoadingStatus == SourceFilterDataLoadingStatus.loading || sourcesState.dataLoadingStatus == SourceFilterDataLoadingStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (sourcesState.dataLoadingStatus == SourceFilterDataLoadingStatus.failure) {
              return FailureStateWidget(
                message: sourcesState.errorMessage ?? l10n.sourceFilterError,
                onRetry: () => context
                    .read<SourcesFilterBloc>()
                    .add(const LoadSourceFilterData()), // Use correct event
              );
            }
            // Use allAvailableSources to display all sources for selection
            if (sourcesState.allAvailableSources.isEmpty) {
              return FailureStateWidget(
                message: l10n.sourceFilterEmptyHeadline, // Re-use
              );
            }

            return BlocBuilder<AccountBloc, AccountState>(
              buildWhen: (previous, current) =>
                  previous.preferences?.followedSources != current.preferences?.followedSources ||
                  previous.status != current.status,
              builder: (context, accountState) {
                final followedSources =
                    accountState.preferences?.followedSources ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: sourcesState.allAvailableSources.length, // Use allAvailableSources
                  itemBuilder: (context, index) {
                    final source = sourcesState.allAvailableSources[index]; // Use allAvailableSources
                    final isFollowed =
                        followedSources.any((fs) => fs.id == source.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        // Consider adding source.iconUrl if available
                        title: Text(source.name),
                        trailing: IconButton(
                          icon: isFollowed
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : const Icon(Icons.add_circle_outline),
                          tooltip: isFollowed
                              ? l10n.unfollowSourceTooltip(source.name)
                              : l10n.followSourceTooltip(source.name), // New
                          onPressed: () {
                            context.read<AccountBloc>().add(
                                  AccountFollowSourceToggled(source: source),
                                );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
