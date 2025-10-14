import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template country_filter_page}
/// A page dedicated to selecting event countries for filtering headlines.
///
/// This page now interacts with the centralized [HeadlinesFilterBloc]
/// to manage the list of available countries and the user's selections.
/// {@endtemplate}
class CountryFilterPage extends StatelessWidget {
  /// {@macro country_filter_page}
  ///
  /// Requires a [title] for the app bar and the [filterBloc] instance
  /// passed from the parent route.
  const CountryFilterPage({
    required this.title,
    required this.filterBloc,
    super.key,
  });

  /// The title to display in the app bar for this filter page.
  final String title;

  /// The instance of [HeadlinesFilterBloc] provided by the parent route.
  final HeadlinesFilterBloc filterBloc;

  @override
  Widget build(BuildContext context) {
    // Provide the existing filterBloc to this subtree.
    return BlocProvider.value(
      value: filterBloc,
      child: _CountryFilterView(title: title),
    );
  }
}

class _CountryFilterView extends StatelessWidget {
  const _CountryFilterView({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: textTheme.titleLarge),
        actions: [
          // Apply My Followed Countries Button
          BlocBuilder<HeadlinesFilterBloc, HeadlinesFilterState>(
            builder: (context, filterState) {
              final appState = context.watch<AppBloc>().state;
              final followedCountries =
                  appState.userContentPreferences?.followedCountries ?? [];

              // Determine if the current selection matches the followed countries
              final isFollowedFilterActive =
                  followedCountries.isNotEmpty &&
                  filterState.selectedCountries.length ==
                      followedCountries.length &&
                  filterState.selectedCountries.containsAll(followedCountries);

              return IconButton(
                icon: isFollowedFilterActive
                    ? const Icon(Icons.favorite)
                    : const Icon(Icons.favorite_border),
                color: isFollowedFilterActive
                    ? theme.colorScheme.primary
                    : null,
                tooltip: l10n.headlinesFeedFilterApplyFollowedLabel,
                onPressed: () {
                  if (followedCountries.isEmpty) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(l10n.noFollowedItemsForFilterSnackbar),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                  } else {
                    // Toggle the followed items filter in the HeadlinesFilterBloc
                    context.read<HeadlinesFilterBloc>().add(
                      FollowedCountriesFilterToggled(
                        isSelected: !isFollowedFilterActive,
                      ),
                    );
                  }
                },
              );
            },
          ),
          // Apply Filters Button (now just pops, as state is managed centrally)
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () {
              // The selections are already managed by HeadlinesFilterBloc.
              // Just pop the page.
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: BlocBuilder<HeadlinesFilterBloc, HeadlinesFilterState>(
        builder: (context, filterState) {
          // Determine overall loading status for the main list
          final isLoadingMainList =
              filterState.status == HeadlinesFilterStatus.loading;

          // Handle initial loading state
          if (isLoadingMainList) {
            return LoadingStateWidget(
              icon: Icons.public_outlined,
              headline: l10n.countryFilterLoadingHeadline,
              subheadline: l10n.countryFilterLoadingSubheadline,
            );
          }

          // Handle failure state (show error and retry button)
          if (filterState.status == HeadlinesFilterStatus.failure &&
              filterState.allCountries.isEmpty) {
            return FailureStateWidget(
              exception:
                  filterState.error ?? const UnknownException('Unknown error'),
              onRetry: () => context.read<HeadlinesFilterBloc>().add(
                FilterDataLoaded(
                  initialSelectedTopics: filterState.selectedTopics.toList(),
                  initialSelectedSources: filterState.selectedSources.toList(),
                  initialSelectedCountries: filterState.selectedCountries
                      .toList(),
                  isUsingFollowedItems: filterState.isUsingFollowedItems,
                ),
              ),
            );
          }

          // Handle empty state (after successful load but no countries found)
          if (filterState.allCountries.isEmpty) {
            return InitialStateWidget(
              icon: Icons.flag_circle_outlined,
              headline: l10n.countryFilterEmptyHeadline,
              subheadline: l10n.countryFilterEmptySubheadline,
            );
          }

          // Handle loaded state (success)
          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.paddingSmall,
            ).copyWith(bottom: AppSpacing.xxl),
            itemCount: filterState.allCountries.length,
            itemBuilder: (context, index) {
              final country = filterState.allCountries[index];
              final isSelected = filterState.selectedCountries.contains(
                country,
              );

              return CheckboxListTile(
                title: Text(country.name, style: textTheme.titleMedium),
                secondary: SizedBox(
                  width: AppSpacing.xl + AppSpacing.xs,
                  height: AppSpacing.lg + AppSpacing.sm,
                  child: ClipRRect(
                    // Clip the image for rounded corners if desired
                    borderRadius: BorderRadius.circular(AppSpacing.xs / 2),
                    child: Image.network(
                      country.flagUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.flag_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: AppSpacing.lg,
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                value: isSelected,
                onChanged: (bool? value) {
                  if (value != null) {
                    context.read<HeadlinesFilterBloc>().add(
                      FilterCountryToggled(country: country, isSelected: value),
                    );
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.paddingMedium,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
