import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_search_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_core/feed_core.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template headline_search_delegate}
/// A search delegate for searching headlines.
///
/// This delegate provides the UI for the search page, handles user input,
/// and displays search results by interacting with a [HeadlineSearchBloc].
/// {@endtemplate}
class HeadlineSearchDelegate extends SearchDelegate<void> {
  /// {@macro headline_search_delegate}
  HeadlineSearchDelegate({required this.headlineSearchBloc});

  /// The BLoC responsible for handling search logic.
  final HeadlineSearchBloc headlineSearchBloc;

  @override
  Widget buildLeading(BuildContext context) {
    // An icon button to close the search interface.
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    // An icon button to clear the current search query.
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          // Also notify the BLoC that the query is cleared.
          headlineSearchBloc.add(const HeadlineSearchQueryChanged(''));
        },
      ),
    ];
  }

  @override
  Widget buildResults(BuildContext context) {
    // `buildResults` and `buildSuggestions` will share the same UI.
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // As the user types, dispatch an event to the BLoC to update the search.
    headlineSearchBloc.add(HeadlineSearchQueryChanged(query));
    // `buildResults` and `buildSuggestions` will share the same UI.
    return _buildSearchResults(context);
  }

  /// Builds the main content area for search results and suggestions.
  Widget _buildSearchResults(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    // Provide the BLoC instance to the widget tree.
    return BlocProvider.value(
      value: headlineSearchBloc,
      child: BlocBuilder<HeadlineSearchBloc, HeadlineSearchState>(
        builder: (context, state) {
          switch (state.status) {
            case HeadlineSearchStatus.initial:
              // Show a placeholder message before a search is performed.
              return InitialStateWidget(
                icon: Icons.search,
                headline: l10n.headlineSearchInitialHeadline,
                subheadline: l10n.headlineSearchInitialSubheadline,
              );
            case HeadlineSearchStatus.loading:
              // Show a loading indicator while fetching results.
              return const Center(child: CircularProgressIndicator());
            case HeadlineSearchStatus.failure:
              // Show an error widget if the search fails.
              return FailureStateWidget(
                exception: state.error ?? UnknownException(l10n.unknownError),
                onRetry: () =>
                    headlineSearchBloc.add(HeadlineSearchQueryChanged(query)),
              );
            case HeadlineSearchStatus.success:
              // If the search is successful but there are no results.
              if (state.headlines.isEmpty) {
                return InitialStateWidget(
                  icon: Icons.search_off,
                  headline: l10n.headlineSearchNoResults,
                  subheadline: l10n.headlineSearchNoResultsSubheadline,
                );
              }
              // Display the list of found headlines.
              return ListView.builder(
                itemCount: state.headlines.length,
                itemBuilder: (context, index) {
                  final headline = state.headlines[index];
                  return HeadlineTileImageStart(
                    headline: headline,
                    onHeadlineTap: () =>
                        HeadlineTapHandler.handleHeadlineTap(context, headline),
                  );
                },
              );
          }
        },
      ),
    );
  }

  @override
  void close(BuildContext context, void result) {
    // Dispose the BLoC when the search delegate is closed to prevent
    // memory leaks.
    headlineSearchBloc.close();
    super.close(context, result);
  }
}
