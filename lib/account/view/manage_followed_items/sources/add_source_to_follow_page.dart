import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/account/bloc/available_sources_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_shared/ht_shared.dart';
import 'package:ht_ui_kit/ht_ui_kit.dart';

/// {@template add_source_to_follow_page}
/// A page that allows users to browse and select sources to follow.
/// {@endtemplate}
class AddSourceToFollowPage extends StatelessWidget {
  /// {@macro add_source_to_follow_page}
  const AddSourceToFollowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    return BlocProvider(
      create: (context) => AvailableSourcesBloc(
        sourcesRepository: context.read<HtDataRepository<Source>>(),
      )..add(const FetchAvailableSources()),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.addSourcesPageTitle)),
        body: BlocBuilder<AvailableSourcesBloc, AvailableSourcesState>(
          builder: (context, sourcesState) {
            if (sourcesState.status == AvailableSourcesStatus.loading ||
                sourcesState.status == AvailableSourcesStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (sourcesState.status == AvailableSourcesStatus.failure) {
              return FailureStateWidget(
                exception: OperationFailedException(
                  sourcesState.error ?? l10n.sourceFilterError,
                ),
                onRetry: () => context.read<AvailableSourcesBloc>().add(
                  const FetchAvailableSources(),
                ),
              );
            }
            if (sourcesState.availableSources.isEmpty) {
              return InitialStateWidget(
                icon: Icons.source_outlined,
                headline: l10n.sourceFilterEmptyHeadline,
                subheadline: l10n.sourceFilterEmptySubheadline,
              );
            }

            return BlocBuilder<AccountBloc, AccountState>(
              buildWhen: (previous, current) =>
                  previous.preferences?.followedSources !=
                      current.preferences?.followedSources ||
                  previous.status != current.status,
              builder: (context, accountState) {
                final followedSources =
                    accountState.preferences?.followedSources ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: sourcesState.availableSources.length,
                  itemBuilder: (context, index) {
                    final source = sourcesState.availableSources[index];
                    final isFollowed = followedSources.any(
                      (fs) => fs.id == source.id,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
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
                              : l10n.followSourceTooltip(source.name),
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
