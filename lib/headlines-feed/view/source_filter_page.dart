// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/headlines-feed/bloc/sources_filter_bloc.dart'; // Import the BLoC
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_main/shared/widgets/widgets.dart'; // For loading/error widgets
import 'package:ht_sources_client/ht_sources_client.dart';
// Removed repository import: import 'package:ht_sources_repository/ht_sources_repository.dart';

/// {@template source_filter_page}
/// A page dedicated to selecting news sources for filtering headlines.
///
/// Uses [SourcesFilterBloc] to fetch sources paginatively, allows multiple
/// selections, and returns the selected list via `context.pop` when the user
/// applies the changes.
/// {@endtemplate}
class SourceFilterPage extends StatefulWidget {
  /// {@macro source_filter_page}
  const SourceFilterPage({super.key});

  @override
  State<SourceFilterPage> createState() => _SourceFilterPageState();
}

/// State for the [SourceFilterPage].
///
/// Manages the local selection state ([_pageSelectedSources]) and interacts
/// with [SourcesFilterBloc] for data fetching and pagination.
class _SourceFilterPageState extends State<SourceFilterPage> {
  /// Stores the sources selected by the user *on this specific page*.
  /// This state is local to the `SourceFilterPage` lifecycle.
  /// It's initialized in `initState` using the list of previously selected
  /// sources passed via the `extra` parameter during navigation from
  /// `HeadlinesFilterPage`. This ensures the checkboxes reflect the state
  /// from the main filter page when this page loads.
  late Set<Source> _pageSelectedSources;

  /// Scroll controller to detect when the user reaches the end of the list
  /// for pagination.
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialization needs to happen after the first frame to safely access
    // GoRouterState.of(context).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Retrieve the list of sources that were already selected on the
      //    previous page (HeadlinesFilterPage). This list is passed dynamically
      //    via the `extra` parameter in the `context.pushNamed` call.
      final initialSelection = GoRouterState.of(context).extra as List<Source>?;

      // 2. Initialize the local selection state (`_pageSelectedSources`) for this
      //    page. Use a Set for efficient add/remove/contains operations.
      //    This ensures the checkboxes on this page are initially checked
      //    correctly based on the selections made previously.
      _pageSelectedSources = Set.from(initialSelection ?? []);

      // 3. Trigger the page-specific BLoC (SourcesFilterBloc) to start
      //    fetching the list of *all available* sources that the user can
      //    potentially select from. The BLoC handles fetching, pagination,
      //    loading states, and errors for the *list of options*.
      context.read<SourcesFilterBloc>().add(SourcesFilterRequested());
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
  /// fetching more sources via the BLoC if available.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final bloc = context.read<SourcesFilterBloc>();
    // Fetch more when nearing the bottom, if BLoC has more and isn't already loading more
    if (currentScroll >= (maxScroll * 0.9) &&
        bloc.state.hasMore &&
        bloc.state.status != SourcesFilterStatus.loadingMore) {
      bloc.add(SourcesFilterLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.headlinesFeedFilterSourceLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () {
              // When the user taps 'Apply' (checkmark), pop the current route
              // and return the final list of selected sources (`_pageSelectedSources`)
              // from this page back to the previous page (`HeadlinesFilterPage`).
              // `HeadlinesFilterPage` receives this list in its `onResult` callback.
              context.pop(_pageSelectedSources.toList());
            },
          ),
        ],
      ),
      // Use BlocBuilder to react to state changes from SourcesFilterBloc
      body: BlocBuilder<SourcesFilterBloc, SourcesFilterState>(
        builder: (context, state) {
          return _buildBody(context, state);
        },
      ),
    );
  }

  /// Builds the main content body based on the current [SourcesFilterState].
  Widget _buildBody(BuildContext context, SourcesFilterState state) {
    final l10n = context.l10n;

    // Handle initial loading state
    if (state.status == SourcesFilterStatus.loading) {
      return LoadingStateWidget(
        icon: Icons.source_outlined,
        headline: l10n.sourceFilterLoadingHeadline,
        subheadline: l10n.sourceFilterLoadingSubheadline,
      );
    }

    // Handle failure state (show error and retry button)
    if (state.status == SourcesFilterStatus.failure && state.sources.isEmpty) {
      return FailureStateWidget(
        message: state.error?.toString() ?? l10n.unknownError, // Assumes unknownError exists
        onRetry: () =>
            context.read<SourcesFilterBloc>().add(SourcesFilterRequested()),
      );
    }

    // Handle empty state (after successful load but no sources found)
    if (state.status == SourcesFilterStatus.success && state.sources.isEmpty) {
      return InitialStateWidget(
        icon: Icons.search_off,
        headline: l10n.sourceFilterEmptyHeadline,
        subheadline: l10n.sourceFilterEmptySubheadline,
      );
    }

    // Handle loaded state (success or loading more)
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: state.sources.length +
          ((state.status == SourcesFilterStatus.loadingMore ||
                  (state.status == SourcesFilterStatus.failure &&
                      state.sources.isNotEmpty))
              ? 1
              : 0),
      itemBuilder: (context, index) {
        if (index >= state.sources.length) {
          if (state.status == SourcesFilterStatus.loadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (state.status == SourcesFilterStatus.failure) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.lg,
              ),
              child: Center(
                child: Text(
                  l10n.loadMoreError, // Assumes loadMoreError exists
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        }

        final source = state.sources[index];
        final isSelected = _pageSelectedSources.contains(source);

        return CheckboxListTile(
          title: Text(source.name),
          subtitle:
              source.description != null && source.description!.isNotEmpty
                  ? Text(
                      source.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
          value: isSelected,
          onChanged: (bool? value) {
            // When a checkbox state changes, update the local selection set
            // (`_pageSelectedSources`) for this page.
            setState(() {
              if (value == true) {
                // Add the source if checked.
                _pageSelectedSources.add(source);
              } else {
                // Remove the source if unchecked.
                _pageSelectedSources.remove(source);
              }
            });
          },
        );
      },
    );
  }
}
