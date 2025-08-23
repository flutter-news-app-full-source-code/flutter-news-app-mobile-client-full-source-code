import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/account_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/entity_details/view/entity_details_page.dart';
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
    final followedCountries =
        context.watch<AccountBloc>().state.preferences?.followedCountries ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.followedCountriesPageTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.addCountriesTooltip,
            onPressed: () {
              context.goNamed(Routes.addCountryToFollowName);
            },
          ),
        ],
      ),
      body: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          if (state.status == AccountStatus.loading &&
              state.preferences == null) {
            return LoadingStateWidget(
              icon: Icons.flag_outlined,
              headline: l10n.followedCountriesLoadingHeadline,
              subheadline: l10n.pleaseWait,
            );
          }

          if (state.status == AccountStatus.failure &&
              state.preferences == null) {
            return FailureStateWidget(
              exception:
                  state.error ??
                  OperationFailedException(l10n.followedCountriesErrorHeadline),
              onRetry: () {
                if (state.user?.id != null) {
                  context.read<AccountBloc>().add(
                    AccountLoadUserPreferences(userId: state.user!.id),
                  );
                }
              },
            );
          }

          if (followedCountries.isEmpty) {
            return InitialStateWidget(
              icon: Icons.public_off_outlined,
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
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  tooltip: l10n.unfollowCountryTooltip(country.name),
                  onPressed: () {
                    context.read<AccountBloc>().add(
                      AccountFollowCountryToggled(country: country),
                    );
                  },
                ),
                onTap: () {
                  context.push(
                    Routes.countryDetails,
                    extra: EntityDetailsPageArguments(entity: country),
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
