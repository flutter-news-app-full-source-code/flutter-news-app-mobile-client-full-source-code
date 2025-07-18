import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/entity_details/view/entity_details_page.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_shared/ht_shared.dart';
import 'package:ht_ui_kit/ht_ui_kit.dart';

/// {@template followed_sources_list_page}
/// Page to display and manage sources followed by the user.
/// {@endtemplate}
class FollowedSourcesListPage extends StatelessWidget {
  /// {@macro followed_sources_list_page}
  const FollowedSourcesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final followedSources =
        context.watch<AccountBloc>().state.preferences?.followedSources ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.followedSourcesPageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.addSourcesTooltip,
            onPressed: () {
              context.goNamed(Routes.addSourceToFollowName);
            },
          ),
        ],
      ),
      body: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          if (state.status == AccountStatus.loading &&
              state.preferences == null) {
            return LoadingStateWidget(
              icon: Icons.source_outlined,
              headline: l10n.followedSourcesLoadingHeadline,
              subheadline: l10n.pleaseWait,
            );
          }

          if (state.status == AccountStatus.failure &&
              state.preferences == null) {
            return FailureStateWidget(
              exception: OperationFailedException(
                state.errorMessage ?? l10n.followedSourcesErrorHeadline,
              ),
              onRetry: () {
                if (state.user?.id != null) {
                  context
                      .read<AccountBloc>()
                      .add(AccountLoadUserPreferences(userId: state.user!.id));
                }
              },
            );
          }

          if (followedSources.isEmpty) {
            return InitialStateWidget(
              icon: Icons.no_sim_outlined,
              headline: l10n.followedSourcesEmptyHeadline,
              subheadline: l10n.followedSourcesEmptySubheadline,
            );
          }

          return ListView.builder(
            itemCount: followedSources.length,
            itemBuilder: (context, index) {
              final source = followedSources[index];
              return ListTile(
                leading: const Icon(Icons.source_outlined),
                title: Text(source.name),
                subtitle: Text(
                  source.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  tooltip: l10n.unfollowSourceTooltip(source.name),
                  onPressed: () {
                    context
                        .read<AccountBloc>()
                        .add(AccountFollowSourceToggled(source: source));
                  },
                ),
                onTap: () {
                  context.push(
                    Routes.sourceDetails,
                    extra: EntityDetailsPageArguments(entity: source),
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
