import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';
import 'package:ht_main/shared/widgets/widgets.dart';

/// {@template followed_countries_list_page}
/// Displays a list of countries the user is currently following.
/// Allows unfollowing and navigating to add more countries.
/// {@endtemplate}
class FollowedCountriesListPage extends StatelessWidget {
  /// {@macro followed_countries_list_page}
  const FollowedCountriesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
          if (state.status == AccountStatus.initial ||
              (state.status == AccountStatus.loading &&
                  state.preferences == null)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == AccountStatus.failure &&
              state.preferences == null) {
            return FailureStateWidget(
              message: state.errorMessage ?? l10n.unknownError,
              onRetry: () {
                if (state.user?.id != null) {
                  context.read<AccountBloc>().add(
                        AccountLoadContentPreferencesRequested(
                          userId: state.user!.id,
                        ),
                      );
                }
              },
            );
          }

          final followedCountries = state.preferences?.followedCountries;

          if (followedCountries == null || followedCountries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.public_outlined, size: 48),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.noFollowedCountriesMessage,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(l10n.addCountriesButtonLabel),
                      onPressed: () {
                        context.goNamed(Routes.addCountryToFollowName);
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: followedCountries.length,
            itemBuilder: (context, index) {
              final country = followedCountries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading: country.flagUrl.isNotEmpty &&
                          Uri.tryParse(country.flagUrl)?.isAbsolute == true
                      ? SizedBox(
                          width: 36,
                          height: 24,
                          child: Image.network(
                            country.flagUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.public_outlined),
                          ),
                        )
                      : const Icon(Icons.public_outlined),
                  title: Text(country.name),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    tooltip: l10n.unfollowCountryTooltip(country.name),
                    onPressed: () {
                      context.read<AccountBloc>().add(
                            AccountFollowCountryToggled(country: country),
                          );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
