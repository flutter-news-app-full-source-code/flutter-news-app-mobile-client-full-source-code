import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template followed_sources_list_page}
/// Page to display and manage sources followed by the user.
/// {@endtemplate}
class FollowedSourcesListPage extends StatelessWidget {
  /// {@macro followed_sources_list_page}
  const FollowedSourcesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.followedSourcesPageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.addSourcesTooltip,
            onPressed: () {
              context.pushNamed(Routes.addSourceToFollowName);
            },
          ),
        ],
      ),
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, appState) {
          final user = appState.user;
          final userContentPreferences = appState.userContentPreferences;

          if (appState.status == AppLifeCycleStatus.loadingUserData ||
              userContentPreferences == null) {
            return LoadingStateWidget(
              icon: Icons.source_outlined,
              headline: l10n.followedSourcesLoadingHeadline,
              subheadline: l10n.pleaseWait,
            );
          }

          if (appState.initialUserPreferencesError != null) {
            return FailureStateWidget(
              exception: appState.initialUserPreferencesError!,
              onRetry: () {
                context.read<AppBloc>().add(AppStarted(initialUser: user));
              },
            );
          }

          final followedSources = userContentPreferences.followedSources;

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
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  tooltip: l10n.unfollowSourceTooltip(source.name),
                  onPressed: () {
                    final updatedFollowedSources = List<Source>.from(
                      followedSources,
                    )..removeWhere((s) => s.id == source.id);

                    final updatedPreferences = userContentPreferences.copyWith(
                      followedSources: updatedFollowedSources,
                    );

                    context.read<AppBloc>().add(
                      AppUserContentPreferencesChanged(
                        preferences: updatedPreferences,
                      ),
                    );
                  },
                ),
                onTap: () async {
                  // Await for the ad to be shown and dismissed.
                  await context
                      .read<InterstitialAdManager>()
                      .onPotentialAdTrigger();

                  // Check if the widget is still in the tree before navigating.
                  if (!context.mounted) return;

                  // Proceed with navigation after the ad is closed.
                  await context.pushNamed(
                    Routes.entityDetailsName,
                    pathParameters: {
                      'type': ContentType.source.name,
                      'id': source.id,
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
