import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/countries_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template country_filter_page}
/// A page dedicated to selecting event countries for filtering headlines.
///
/// Uses [CountriesFilterBloc] to fetch countries paginatively, allows multiple
/// selections, and returns the selected list via `context.pop` when the user
/// applies the changes.
/// {@endtemplate}
class CountryFilterPage extends StatefulWidget {
  /// {@macro country_filter_page}
  const CountryFilterPage({required this.title, this.usage, super.key});

  /// The title to display in the app bar for this filter page.
  final String title;

  /// The usage context for filtering countries (e.g., 'eventCountry', 'headquarters').
  /// If null, fetches all countries (though this is not the primary use case for this page).
  final String? usage;

  @override
  State<CountryFilterPage> createState() => _CountryFilterPageState();
}

/// State for the [CountryFilterPage].
///
/// Manages the local selection state ([_pageSelectedCountries]) and interacts
/// with [CountriesFilterBloc] for data fetching.
class _CountryFilterPageState extends State<CountryFilterPage> {
  /// Stores the countries selected by the user *on this specific page*.
  /// This state is local to the `CountryFilterPage` lifecycle.
  /// It's initialized in `initState` using the list of previously selected
  /// countries passed via the `extra` parameter during navigation from
  /// `HeadlinesFilterPage`. This ensures the checkboxes reflect the state
  /// from the main filter page when this page loads.
  late Set<Country> _pageSelectedCountries;
  late final CountriesFilterBloc _countriesFilterBloc;

  @override
  void initState() {
    super.initState();
    _countriesFilterBloc = context.read<CountriesFilterBloc>();

    // Initialization needs to happen after the first frame to safely access
    // GoRouterState.of(context).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Retrieve the list of countries that were already selected on the
      //    previous page (HeadlinesFilterPage). This list is passed dynamically
      //    via the `extra` parameter in the `context.pushNamed` call.
      final initialSelection =
          GoRouterState.of(context).extra as List<Country>?;

      // 2. Initialize the local selection state (`_pageSelectedCountries`) for this
      //    page. Use a Set for efficient add/remove/contains operations.
      //    This ensures the checkboxes on this page are initially checked
      //    correctly based on the selections made previously.
      _pageSelectedCountries = Set.from(initialSelection ?? []);

      // 3. Trigger the page-specific BLoC (CountriesFilterBloc) to start
      //    fetching the list of *all available* countries that the user can
      //    potentially select from, using the specified usage filter.
      _countriesFilterBloc.add(CountriesFilterRequested(usage: widget.usage));
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title, // Use the dynamic title
          style: textTheme.titleLarge,
        ),
        actions: [
          // Apply My Followed Countries Button
          BlocBuilder<CountriesFilterBloc, CountriesFilterState>(
            builder: (context, state) {
              // Determine if the "Apply My Followed" icon should be filled
              final bool isFollowedFilterActive =
                  state.followedCountries.isNotEmpty &&
                  _pageSelectedCountries.length ==
                      state.followedCountries.length &&
                  _pageSelectedCountries.every(
                    state.followedCountries.contains,
                  );

              return IconButton(
                icon: isFollowedFilterActive
                    ? const Icon(Icons.favorite)
                    : const Icon(Icons.favorite_border),
                color: isFollowedFilterActive
                    ? theme.colorScheme.primary
                    : null,
                tooltip: l10n.headlinesFeedFilterApplyFollowedLabel,
                onPressed:
                    state.followedCountriesStatus ==
                        CountriesFilterStatus.loading
                    ? null // Disable while loading
                    : () {
                        // Dispatch event to BLoC to fetch and apply followed countries
                        _countriesFilterBloc.add(
                          CountriesFilterApplyFollowedRequested(),
                        );
                      },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () {
              // When the user taps 'Apply' (checkmark), pop the current route
              // and return the final list of selected countries (`_pageSelectedCountries`)
              // from this page back to the previous page (`HeadlinesFilterPage`).
              // `HeadlinesFilterPage` receives this list in its `onResult` callback.
              context.pop(_pageSelectedCountries.toList());
            },
          ),
        ],
      ),
      // Use BlocListener to react to state changes from CountriesFilterBloc
      body: BlocListener<CountriesFilterBloc, CountriesFilterState>(
        listenWhen: (previous, current) =>
            previous.followedCountriesStatus !=
                current.followedCountriesStatus ||
            previous.followedCountries != current.followedCountries,
        listener: (context, state) {
          if (state.followedCountriesStatus == CountriesFilterStatus.success) {
            // Update local state with followed countries from BLoC
            setState(() {
              _pageSelectedCountries = Set.from(state.followedCountries);
            });
            if (state.followedCountries.isEmpty) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(l10n.noFollowedItemsForFilterSnackbar),
                    duration: const Duration(seconds: 3),
                  ),
                );
            }
          } else if (state.followedCountriesStatus ==
              CountriesFilterStatus.failure) {
            // Show error message if fetching followed countries failed
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.error?.message ?? l10n.unknownError),
                  duration: const Duration(seconds: 3),
                ),
              );
          }
        },
        child: BlocBuilder<CountriesFilterBloc, CountriesFilterState>(
          builder: (context, state) {
            // Determine overall loading status for the main list
            final bool isLoadingMainList =
                state.status == CountriesFilterStatus.loading;

            // Determine if followed countries are currently loading
            final bool isLoadingFollowedCountries =
                state.followedCountriesStatus == CountriesFilterStatus.loading;

            // Handle initial loading state
            if (isLoadingMainList) {
              return LoadingStateWidget(
                icon: Icons.public_outlined,
                headline: l10n.countryFilterLoadingHeadline,
                subheadline: l10n.countryFilterLoadingSubheadline,
              );
            }

            // Handle failure state (show error and retry button)
            if (state.status == CountriesFilterStatus.failure &&
                state.countries.isEmpty) {
              return FailureStateWidget(
                exception:
                    state.error ?? const UnknownException('Unknown error'),
                onRetry: () => _countriesFilterBloc.add(
                  CountriesFilterRequested(usage: widget.usage),
                ),
              );
            }

            // Handle empty state (after successful load but no countries found)
            if (state.status == CountriesFilterStatus.success &&
                state.countries.isEmpty) {
              return InitialStateWidget(
                icon: Icons.flag_circle_outlined,
                headline: l10n.countryFilterEmptyHeadline,
                subheadline: l10n.countryFilterEmptySubheadline,
              );
            }

            // Handle loaded state (success)
            return Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.paddingSmall,
                  ).copyWith(bottom: AppSpacing.xxl),
                  itemCount: state.countries.length,
                  itemBuilder: (context, index) {
                    final country = state.countries[index];
                    final isSelected = _pageSelectedCountries.contains(country);

                    return CheckboxListTile(
                      title: Text(country.name, style: textTheme.titleMedium),
                      secondary: SizedBox(
                        width: AppSpacing.xl + AppSpacing.xs,
                        height: AppSpacing.lg + AppSpacing.sm,
                        child: ClipRRect(
                          // Clip the image for rounded corners if desired
                          borderRadius: BorderRadius.circular(
                            AppSpacing.xs / 2,
                          ),
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
                                  value:
                                      loadingProgress.expectedTotalBytes != null
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
                        setState(() {
                          if (value == true) {
                            _pageSelectedCountries.add(country);
                          } else {
                            _pageSelectedCountries.remove(country);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.paddingMedium,
                      ),
                    );
                  },
                ),
                // Show loading overlay if followed countries are being fetched
                if (isLoadingFollowedCountries)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54, // Semi-transparent overlay
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.headlinesFeedLoadingHeadline,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
