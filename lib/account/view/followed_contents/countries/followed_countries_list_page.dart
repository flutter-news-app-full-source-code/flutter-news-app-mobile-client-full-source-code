import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template followed_countries_list_page}
/// Page to display and manage countries followed by the user.
/// {@endtemplate}
class FollowedCountriesListPage extends StatelessWidget {
  /// {@macro followed_countries_list_page}
  const FollowedCountriesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.followedCountriesPageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.addCountriesTooltip,
            onPressed: () {
              context.pushNamed(Routes.addCountryToFollowName);
            },
          ),
        ],
      ),
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, appState) {
          final userContentPreferences = appState.userContentPreferences;

          if (appState.status == AppLifeCycleStatus.loadingUserData ||
              userContentPreferences == null) {
            return LoadingStateWidget(
              icon: Icons.flag_outlined,
              headline: l10n.followedCountriesLoadingHeadline,
              subheadline: l10n.pleaseWait,
            );
          }

          if (appState.error != null) {
            return FailureStateWidget(
              exception: appState.error!,
              onRetry: () {
                context.read<AppBloc>().add(
                  const AppUserContentPreferencesRefreshed(),
                );
              },
            );
          }

          final followedCountries = userContentPreferences.followedCountries;

          if (followedCountries.isEmpty) {
            return InitialStateWidget(
              icon: Icons.location_off_outlined,
              headline: l10n.followedCountriesEmptyHeadline,
              subheadline: l10n.followedCountriesEmptySubheadline,
            );
          }

          return ListView.builder(
            itemCount: followedCountries.length,
            itemBuilder: (context, index) {
              final country = followedCountries[index];
              return ListTile(
                leading: SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.network(
                    country.flagUrl,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.flag_outlined),
                  ),
                ),
                title: Text(country.name),
                trailing: IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  tooltip: l10n.unfollowCountryTooltip(country.name),
                  onPressed: () {
                    final updatedFollowedCountries = List<Country>.from(
                      followedCountries,
                    )..removeWhere((c) => c.id == country.id);

                    final updatedPreferences = userContentPreferences.copyWith(
                      followedCountries: updatedFollowedCountries,
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
                      'type': ContentType.country.name,
                      'id': country.id,
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
