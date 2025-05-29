import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';
import 'package:ht_shared/ht_shared.dart';

/// {@template content_preferences_page}
/// Page for managing user's content preferences, including followed
/// categories, sources, and countries.
/// {@endtemplate}
class ContentPreferencesPage extends StatelessWidget {
  /// {@macro content_preferences_page}
  const ContentPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DefaultTabController(
      length: 3, // Categories, Sources, Countries
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.accountContentPreferencesTile,
          ), // Reusing existing key
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.headlinesFeedFilterCategoryLabel), // Reusing
              Tab(text: l10n.headlinesFeedFilterSourceLabel), // Reusing
              Tab(text: l10n.headlinesFeedFilterEventCountryLabel), // Reusing
            ],
          ),
        ),
        body: BlocBuilder<AccountBloc, AccountState>(
          builder: (context, state) {
            if (state.status == AccountStatus.loading &&
                state.preferences == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == AccountStatus.failure &&
                state.preferences == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.paddingLarge),
                  child: Text(
                    state.errorMessage ?? l10n.unknownError,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // Preferences might be null initially or if loading failed but user existed
            final preferences =
                state.preferences ?? const UserContentPreferences(id: '');

            return TabBarView(
              children: [
                _buildCategoriesView(
                  context,
                  preferences.followedCategories,
                  l10n,
                ),
                _buildSourcesView(context, preferences.followedSources, l10n),
                _buildCountriesView(
                  context,
                  preferences.followedCountries,
                  l10n,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesView(
    BuildContext context,
    List<Category> followedCategories,
    AppLocalizations l10n,
  ) {
    if (followedCategories.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.categoryFilterEmptyHeadline), // Reusing key
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l10n.headlinesFeedFilterCategoryLabel), // "Category"
            onPressed: () {
              context.goNamed(Routes.feedFilterCategoriesName);
            },
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.paddingMedium),
            itemCount: followedCategories.length,
            itemBuilder: (context, index) {
              final category = followedCategories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  title: Text(category.name),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    tooltip: 'Unfollow ${category.name}', // Consider l10n
                    onPressed: () {
                      context.read<AccountBloc>().add(
                        AccountFollowCategoryToggled(category: category),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingMedium),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              'Manage ${l10n.headlinesFeedFilterCategoryLabel}',
            ), // "Manage Category"
            onPressed: () {
              context.goNamed(Routes.feedFilterCategoriesName);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourcesView(
    BuildContext context,
    List<Source> followedSources,
    AppLocalizations l10n,
  ) {
    if (followedSources.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.sourceFilterEmptyHeadline), // Reusing key
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l10n.headlinesFeedFilterSourceLabel), // "Source"
            onPressed: () {
              context.goNamed(Routes.feedFilterSourcesName);
            },
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.paddingMedium),
            itemCount: followedSources.length,
            itemBuilder: (context, index) {
              final source = followedSources[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  title: Text(source.name),
                  // Consider adding source.iconUrl if available and desired
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    tooltip: 'Unfollow ${source.name}', // Consider l10n
                    onPressed: () {
                      context.read<AccountBloc>().add(
                        AccountFollowSourceToggled(source: source),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingMedium),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              'Manage ${l10n.headlinesFeedFilterSourceLabel}',
            ), // "Manage Source"
            onPressed: () {
              context.goNamed(Routes.feedFilterSourcesName);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountriesView(
    BuildContext context,
    List<Country> followedCountries,
    AppLocalizations l10n,
  ) {
    if (followedCountries.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.countryFilterEmptyHeadline), // Reusing key
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l10n.headlinesFeedFilterEventCountryLabel), // "Country"
            onPressed:
                null, // TODO: Implement new navigation/management for followed countries
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.paddingMedium),
            itemCount: followedCountries.length,
            itemBuilder: (context, index) {
              final country = followedCountries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  // leading: country.flagUrl != null ? Image.network(country.flagUrl!, width: 36, height: 24, fit: BoxFit.cover) : null, // Optional: Display flag
                  title: Text(country.name),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    tooltip: 'Unfollow ${country.name}', // Consider l10n
                    onPressed: () {
                      context.read<AccountBloc>().add(
                        AccountFollowCountryToggled(country: country),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingMedium),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              'Manage ${l10n.headlinesFeedFilterEventCountryLabel}',
            ), // "Manage Country"
            // onPressed: () {
            //   context.goNamed(Routes.feedFilterCountriesName);
            // }, // TODO: Implement new navigation/management for followed countries
            onPressed: null, // Temporarily disable until new flow is defined
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }
}
