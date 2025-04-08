// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_countries_client/ht_countries_client.dart';
import 'package:ht_countries_repository/ht_countries_repository.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_main/shared/widgets/widgets.dart'; // For loading/error widgets

/// {@template country_filter_page}
/// A page dedicated to selecting event countries for filtering headlines.
///
/// Fetches countries paginatively, allows multiple selections, and returns
/// the selected list via `context.pop` when the user applies the changes.
/// {@endtemplate}
class CountryFilterPage extends StatefulWidget {
  /// {@macro country_filter_page}
  const CountryFilterPage({super.key});

  @override
  State<CountryFilterPage> createState() => _CountryFilterPageState();
}

/// State for the [CountryFilterPage].
///
/// Manages the local selection state ([_pageSelectedCountries]), fetches
/// countries from the [HtCountriesRepository], handles pagination using a
/// [ScrollController], and displays loading/error/empty/loaded states.
class _CountryFilterPageState extends State<CountryFilterPage> {
  /// Stores the countries selected by the user on this page.
  /// Initialized from the `extra` parameter passed during navigation.
  late Set<Country> _pageSelectedCountries;

  /// List of all countries fetched from the repository.
  List<Country> _allCountries = [];

  /// Flag indicating if the initial country list is being loaded.
  bool _isLoading = true;

  /// Flag indicating if more countries are being loaded for pagination.
  bool _isLoadingMore = false;

  /// Flag indicating if more countries are available to fetch.
  bool _hasMore = true;

  /// Cursor for fetching the next page of countries.
  String? _cursor;

  /// Stores any error message that occurred during fetching.
  String? _error;

  /// Scroll controller to detect when the user reaches the end of the list
  /// for pagination.
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize local selections from the data passed via 'extra'
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialSelection =
          GoRouterState.of(context).extra as List<Country>?;
      _pageSelectedCountries = Set.from(initialSelection ?? []);
      _fetchCountries(); // Initial fetch
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Fetches countries from the [HtCountriesRepository].
  ///
  /// Handles both initial fetch and pagination (`loadMore = true`). Updates
  /// loading states, fetched data ([_allCountries]), pagination info
  /// ([_cursor], [_hasMore]), and error state ([_error]).
  Future<void> _fetchCountries({bool loadMore = false}) async {
    // Prevent unnecessary fetches
    if (!loadMore && _isLoading) return;
    if (loadMore && (_isLoadingMore || !_hasMore)) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _error = null;
      }
    });

    try {
      // Ensure HtCountriesRepository is provided higher up
      final repo = context.read<HtCountriesRepository>();
      // Note: fetchCountries uses 'cursor' which corresponds to 'startAfterId'
      final response = await repo.fetchCountries(
        limit: 20, // Adjust limit as needed
        cursor: loadMore ? _cursor : null,
      );

      setState(() {
        if (loadMore) {
          _allCountries.addAll(response.items);
        } else {
          _allCountries = response.items;
        }
        _cursor = response.cursor;
        _hasMore = response.hasMore;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = e.toString();
      });
    }
  }

  /// Callback function for scroll events.
  ///
  /// Checks if the user has scrolled near the bottom of the list and triggers
  /// fetching more countries if available.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= (maxScroll * 0.9) && _hasMore && !_isLoadingMore) {
      _fetchCountries(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.headlinesFeedFilterEventCountryLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () {
              context.pop(_pageSelectedCountries.toList());
            },
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  /// Builds the main content body based on the current loading/error/data state.
  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;
    if (_isLoading) {
      // Show initial loading indicator
      return LoadingStateWidget(
        icon: Icons.public_outlined,
        headline: l10n.countryFilterLoadingHeadline,
        subheadline: l10n.countryFilterLoadingSubheadline,
      );
    }

    if (_error != null) {
      return FailureStateWidget(message: _error!, onRetry: _fetchCountries);
    }

    if (_allCountries.isEmpty) {
      return InitialStateWidget(
        icon: Icons.search_off,
        headline: l10n.countryFilterEmptyHeadline,
        subheadline: l10n.countryFilterEmptySubheadline,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: _allCountries.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _allCountries.length) {
          return _isLoadingMore
              ? const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
              : const SizedBox.shrink();
        }

        final country = _allCountries[index];
        final isSelected = _pageSelectedCountries.contains(country);

        // Show country flag
        return CheckboxListTile(
          title: Text(country.name),
          secondary: SizedBox(
            width: 40, // Consistent size
            height: 40,
            child: Image.network(
              country.flagUrl,
              fit: BoxFit.contain,
              // Add error builder for network images
              errorBuilder:
                  (context, error, stackTrace) => const Icon(
                    Icons.flag_circle_outlined,
                  ), // Placeholder icon
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
        );
      },
    );
  }
}
