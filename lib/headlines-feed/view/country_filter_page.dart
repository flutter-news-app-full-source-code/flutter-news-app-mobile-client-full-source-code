//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/headlines-feed/bloc/countries_filter_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_main/shared/widgets/widgets.dart';
import 'package:ht_shared/ht_shared.dart' show Country;

/// {@template country_filter_page}
/// A page dedicated to selecting event countries for filtering headlines.
///
/// Uses [CountriesFilterBloc] to fetch countries paginatively, allows multiple
/// selections, and returns the selected list via `context.pop` when the user
/// applies the changes.
/// {@endtemplate}
class CountryFilterPage extends StatefulWidget {
  /// {@macro country_filter_page}
  const CountryFilterPage({super.key});

  @override
  State<CountryFilterPage> createState() => _CountryFilterPageState();
}

/// State for the [CountryFilterPage].
///
/// Manages the local selection state ([_pageSelectedCountries]) and interacts
/// with [CountriesFilterBloc] for data fetching and pagination.
class _CountryFilterPageState extends State<CountryFilterPage> {
  /// Stores the countries selected by the user *on this specific page*.
  /// This state is local to the `CountryFilterPage` lifecycle.
  /// It's initialized in `initState` using the list of previously selected
  /// countries passed via the `extra` parameter during navigation from
  /// `HeadlinesFilterPage`. This ensures the checkboxes reflect the state
  /// from the main filter page when this page loads.
  late Set<Country> _pageSelectedCountries;

  /// Scroll controller to detect when the user reaches the end of the list
  /// for pagination.
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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
      //    potentially select from. The BLoC handles fetching, pagination,
      //    loading states, and errors for the *list of options*.
      context.read<CountriesFilterBloc>().add(CountriesFilterRequested());
    });
    // Add listener for pagination logic.
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Callback function for scroll events.
  ///
  /// Checks if the user has scrolled near the bottom of the list and triggers
  /// fetching more countries via the BLoC if available.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final bloc = context.read<CountriesFilterBloc>();
    // Fetch more when nearing the bottom, if BLoC has more and isn't already loading more
    if (currentScroll >= (maxScroll * 0.9) &&
        bloc.state.hasMore &&
        bloc.state.status != CountriesFilterStatus.loadingMore) {
      bloc.add(CountriesFilterLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.headlinesFeedFilterEventCountryLabel,
          style: textTheme.titleLarge,
        ),
        actions: [
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
      // Use BlocBuilder to react to state changes from CountriesFilterBloc
      body: BlocBuilder<CountriesFilterBloc, CountriesFilterState>(
        builder: _buildBody,
      ),
    );
  }

  /// Builds the main content body based on the current [CountriesFilterState].
  Widget _buildBody(BuildContext context, CountriesFilterState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // Handle initial loading state
    if (state.status == CountriesFilterStatus.loading) {
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
        message: state.error?.toString() ?? l10n.unknownError,
        onRetry: () =>
            context.read<CountriesFilterBloc>().add(CountriesFilterRequested()),
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

    // Handle loaded state (success or loading more)
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.paddingSmall,
      ).copyWith(bottom: AppSpacing.xxl),
      itemCount:
          state.countries.length +
          ((state.status == CountriesFilterStatus.loadingMore ||
                  (state.status == CountriesFilterStatus.failure &&
                      state.countries.isNotEmpty))
              ? 1
              : 0),
      itemBuilder: (context, index) {
        if (index >= state.countries.length) {
          if (state.status == CountriesFilterStatus.loadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (state.status == CountriesFilterStatus.failure) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.lg,
              ),
              child: Center(
                child: Text(
                  l10n.loadMoreError,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final country = state.countries[index];
        final isSelected = _pageSelectedCountries.contains(country);

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
                  color: colorScheme.onSurfaceVariant,
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
    );
  }
}
