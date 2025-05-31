import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/entity_details/view/entity_details_page.dart'; // Import for Arguments
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/widgets/widgets.dart'; // For common widgets

/// {@template followed_sources_list_page}
/// Page to display and manage sources followed by the user.
/// {@endtemplate}
class FollowedSourcesListPage extends StatelessWidget {
  /// {@macro followed_sources_list_page}
  const FollowedSourcesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final followedSources =
        context.watch<AccountBloc>().state.preferences?.followedSources ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Followed Sources'), // Placeholder
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Source to Follow', // Placeholder
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
              headline: 'Loading Followed Sources...', // Placeholder
              subheadline: l10n.pleaseWait, // Assuming this exists
            );
          }

          if (state.status == AccountStatus.failure &&
              state.preferences == null) {
            return FailureStateWidget(
              message: state.errorMessage ?? 'Could not load followed sources.', // Placeholder
              onRetry: () {
                if (state.user?.id != null) {
                  context.read<AccountBloc>().add(
                        AccountLoadUserPreferences( // Corrected event name
                          userId: state.user!.id,
                        ),
                      );
                }
              },
            );
          }

          if (followedSources.isEmpty) {
            return const InitialStateWidget(
              icon: Icons.no_sim_outlined, // Placeholder icon
              headline: 'No Followed Sources', // Placeholder
              subheadline: 'Start following sources to see them here.', // Placeholder
            );
          }

          return ListView.builder(
            itemCount: followedSources.length,
            itemBuilder: (context, index) {
              final source = followedSources[index];
              return ListTile(
                leading: const Icon(Icons.source_outlined), // Generic icon
                title: Text(source.name),
                subtitle: source.description != null
                    ? Text(
                        source.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  tooltip: 'Unfollow Source', // Placeholder
                  onPressed: () {
                    context.read<AccountBloc>().add(
                          AccountFollowSourceToggled(source: source),
                        );
                  },
                ),
                onTap: () {
                  context.push(
                    Routes.sourceDetails, // Navigate to source details
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
