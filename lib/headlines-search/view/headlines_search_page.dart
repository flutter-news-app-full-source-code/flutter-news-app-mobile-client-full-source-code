//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/headlines-feed/widgets/headline_item_widget.dart';
import 'package:ht_main/headlines-search/bloc/headlines_search_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/app_spacing.dart'; // Import AppSpacing
import 'package:ht_main/shared/widgets/failure_state_widget.dart';
import 'package:ht_main/shared/widgets/initial_state_widget.dart';

/// Page widget responsible for providing the BLoC for the headlines search feature.
class HeadlinesSearchPage extends StatelessWidget {
  const HeadlinesSearchPage({super.key});

  /// Defines the route for this page.
  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HeadlinesSearchPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => HeadlinesSearchBloc(
            headlinesRepository: context.read<HtHeadlinesRepository>(),
          ),
      // The actual UI is built by the private _HeadlinesSearchView widget.
      child: const _HeadlinesSearchView(),
    );
  }
}

/// Private View widget that builds the UI for the headlines search page.
/// It listens to the HeadlinesSearchBloc state and displays the appropriate UI.
class _HeadlinesSearchView extends StatefulWidget {
  const _HeadlinesSearchView(); // Private constructor

  @override
  State<_HeadlinesSearchView> createState() => _HeadlinesSearchViewState();
}

class _HeadlinesSearchViewState extends State<_HeadlinesSearchView> {
  final _scrollController = ScrollController();
  final _textController =
      TextEditingController(); // Controller for the TextField
  bool _showClearButton = false; // State to control clear button visibility

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Listen to text changes to control clear button visibility
    _textController.addListener(() {
      setState(() {
        _showClearButton = _textController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _textController.dispose(); // Dispose the text controller
    super.dispose();
  }

  /// Handles scroll events to trigger fetching more results when near the bottom.
  void _onScroll() {
    final state = context.read<HeadlinesSearchBloc>().state;
    if (_isBottom && state is HeadlinesSearchSuccess) {
      final searchTerm = state.lastSearchTerm;
      if (state.hasMore) {
        context.read<HeadlinesSearchBloc>().add(
          HeadlinesSearchFetchRequested(searchTerm: searchTerm!),
        );
      }
    }
  }

  /// Checks if the scroll position is near the bottom of the list.
  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Trigger slightly before the absolute bottom for a smoother experience
    return currentScroll >= (maxScroll * 0.98);
  }

  /// Triggers a search request based on the current text input.
  void _performSearch() {
    context.read<HeadlinesSearchBloc>().add(
      HeadlinesSearchFetchRequested(searchTerm: _textController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appBarTheme = theme.appBarTheme;

    return Scaffold(
      appBar: AppBar(
        // Enhanced TextField integrated into the AppBar title
        title: TextField(
          controller: _textController,

          style: appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge,
          decoration: InputDecoration(
            hintText: l10n.headlinesSearchHintText,

            hintStyle:
                appBarTheme.titleTextStyle?.copyWith(
                  color: (appBarTheme.titleTextStyle?.color ??
                          colorScheme.onSurface)
                      .withAlpha(153), // Replaced withOpacity(0.6)
                ) ??
                theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface.withAlpha(
                    153,
                  ), // Replaced withOpacity(0.6)
                ),
            // Remove the default border
            border: InputBorder.none,
            // Remove focused border highlight if any
            focusedBorder: InputBorder.none,
            // Remove enabled border highlight if any
            enabledBorder: InputBorder.none,
            // Add a subtle background fill
            filled: true,

            fillColor: colorScheme.surface.withAlpha(
              26,
            ), // Replaced withOpacity(0.1)
            // Apply consistent padding using AppSpacing
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingMedium,
              vertical:
                  AppSpacing.paddingSmall, // Adjust vertical padding as needed
            ),
            // Add a clear button that appears when text is entered
            suffixIcon:
                _showClearButton
                    ? IconButton(
                      icon: Icon(
                        Icons.clear,

                        color:
                            appBarTheme.iconTheme?.color ??
                            colorScheme.onSurface,
                      ),
                      onPressed: _textController.clear,
                    )
                    : null, // No icon when text field is empty
          ),
          // Trigger search on submit (e.g., pressing Enter on keyboard)
          onSubmitted: (_) => _performSearch(),
        ),
        actions: [
          // Search action button
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.headlinesSearchActionTooltip, // Re-added tooltip
            onPressed: _performSearch,
          ),
        ],
      ),
      body: BlocBuilder<HeadlinesSearchBloc, HeadlinesSearchState>(
        builder: (context, state) {
          // Handle different states of the search BLoC
          return switch (state) {
            // Loading state
            HeadlinesSearchLoading() => InitialStateWidget(
              icon: Icons.manage_search, // Changed icon
              headline:
                  l10n.headlinesSearchInitialHeadline, // Keep initial text for loading phase
              subheadline: l10n.headlinesSearchInitialSubheadline,
            ),
            // Success state with results
            HeadlinesSearchSuccess(
              :final headlines,
              :final hasMore,
              :final errorMessage, // Check for specific error message within success
              :final lastSearchTerm,
            ) =>
              errorMessage != null
                  // Display error if present within success state
                  ? FailureStateWidget(
                    message: errorMessage,
                    onRetry: () {
                      // Retry with the last successful search term
                      context.read<HeadlinesSearchBloc>().add(
                        HeadlinesSearchFetchRequested(
                          searchTerm: lastSearchTerm ?? '',
                        ),
                      );
                    },
                  )
                  // Display "no results" if list is empty
                  : headlines.isEmpty
                  ? InitialStateWidget(
                    icon: Icons.search_off,
                    headline: l10n.headlinesSearchNoResultsHeadline,
                    subheadline: l10n.headlinesSearchNoResultsSubheadline,
                  )
                  // Display the list of headlines
                  : ListView.builder(
                    controller: _scrollController,
                    // Add 1 for loading indicator if more items exist
                    itemCount:
                        hasMore ? headlines.length + 1 : headlines.length,
                    itemBuilder: (context, index) {
                      // Show loading indicator at the end if hasMore
                      if (index >= headlines.length) {
                        // Ensure loading indicator is visible
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.paddingLarge),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      // Display headline item
                      return HeadlineItemWidget(headline: headlines[index]);
                    },
                  ),
            // Default case (should ideally not be reached if states are handled)
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}
