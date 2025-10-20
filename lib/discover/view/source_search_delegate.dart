import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/discover/search/bloc/source_search_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template source_search_delegate}
/// A search delegate for searching news sources.
///
/// This delegate provides the UI for the search page, handles user input,
/// and displays search results by interacting with a [SourceSearchBloc].
/// {@endtemplate}
class SourceSearchDelegate extends SearchDelegate<void> {
  /// {@macro source_search_delegate}
  SourceSearchDelegate({required this.sourceSearchBloc});

  /// The BLoC responsible for handling search logic.
  final SourceSearchBloc sourceSearchBloc;

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
          sourceSearchBloc.add(const SourceSearchQueryChanged(''));
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
    sourceSearchBloc.add(SourceSearchQueryChanged(query));
    // `buildResults` and `buildSuggestions` will share the same UI.
    return _buildSearchResults(context);
  }

  /// Builds the main content area for search results and suggestions.
  Widget _buildSearchResults(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    // Provide the BLoC instance to the widget tree.
    return BlocProvider.value(
      value: sourceSearchBloc,
      child: BlocBuilder<SourceSearchBloc, SourceSearchState>(
        builder: (context, state) {
          switch (state.status) {
            case SourceSearchStatus.initial:
              // Show a placeholder message before a search is performed.
              return InitialStateWidget(
                icon: Icons.search,
                headline: l10n.searchPageInitialHeadline,
                subheadline: l10n.searchHintTextSource,
              );
            case SourceSearchStatus.loading:
              // Show a loading indicator while fetching results.
              return const Center(child: CircularProgressIndicator());
            case SourceSearchStatus.failure:
              // Show an error widget if the search fails.
              return FailureStateWidget(
                exception: state.error ?? UnknownException(l10n.unknownError),
                onRetry: () =>
                    sourceSearchBloc.add(SourceSearchQueryChanged(query)),
              );
            case SourceSearchStatus.success:
              // If the search is successful but there are no results.
              if (state.sources.isEmpty) {
                return InitialStateWidget(
                  icon: Icons.search_off,
                  headline: l10n.headlinesSearchNoResults,
                  subheadline: l10n.headlinesSearchNoResultsSubheadline,
                );
              }
              // Display the list of found sources.
              return ListView.builder(
                itemCount: state.sources.length,
                itemBuilder: (context, index) {
                  final source = state.sources[index];
                  return ListTile(
                    title: Text(source.name),
                    onTap: () => context.pushNamed(
                      Routes.entityDetailsName,
                      pathParameters: {
                        'type': ContentType.source.name,
                        'id': source.id,
                      },
                    ),
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
    sourceSearchBloc.close();
    super.close(context, result);
  }
}
