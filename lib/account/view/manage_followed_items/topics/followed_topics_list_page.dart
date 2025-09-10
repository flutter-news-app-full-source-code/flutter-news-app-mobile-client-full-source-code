import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/account_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template followed_topics_list_page}
/// Page to display and manage topics followed by the user.
/// {@endtemplate}
class FollowedTopicsListPage extends StatelessWidget {
  /// {@macro followed_topics_list_page}
  const FollowedTopicsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final followedTopics =
        context.watch<AccountBloc>().state.preferences?.followedTopics ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.followedTopicsPageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.addTopicsTooltip,
            onPressed: () {
              context.goNamed(Routes.addTopicToFollowName);
            },
          ),
        ],
      ),
      body: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          if (state.status == AccountStatus.loading &&
              state.preferences == null) {
            return LoadingStateWidget(
              icon: Icons.topic_outlined,
              headline: l10n.followedTopicsLoadingHeadline,
              subheadline: l10n.pleaseWait,
            );
          }

          if (state.status == AccountStatus.failure &&
              state.preferences == null) {
            return FailureStateWidget(
              exception:
                  state.error ??
                  OperationFailedException(l10n.followedTopicsErrorHeadline),
              onRetry: () {
                if (state.user?.id != null) {
                  context.read<AccountBloc>().add(
                    AccountLoadUserPreferences(userId: state.user!.id),
                  );
                }
              },
            );
          }

          if (followedTopics.isEmpty) {
            return InitialStateWidget(
              icon: Icons.no_sim_outlined,
              headline: l10n.followedTopicsEmptyHeadline,
              subheadline: l10n.followedTopicsEmptySubheadline,
            );
          }

          return ListView.builder(
            itemCount: followedTopics.length,
            itemBuilder: (context, index) {
              final topic = followedTopics[index];
              return ListTile(
                leading: SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.network(
                    topic.iconUrl,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.topic_outlined),
                  ),
                ),
                title: Text(topic.name),
                subtitle: Text(
                  topic.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  tooltip: l10n.unfollowTopicTooltip(topic.name),
                  onPressed: () {
                    context.read<AccountBloc>().add(
                      AccountFollowTopicToggled(topic: topic),
                    );
                  },
                ),
                onTap: () {
                  context.read<InterstitialAdManager>().onPotentialAdTrigger();
                  context.pushNamed(
                    Routes.entityDetailsName,
                    pathParameters: {
                      'type': ContentType.topic.name,
                      'id': topic.id,
                    },
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
