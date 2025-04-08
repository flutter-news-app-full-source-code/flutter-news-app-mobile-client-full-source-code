// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/constants.dart';
import 'package:ht_main/shared/widgets/widgets.dart'; // For loading/error widgets
import 'package:ht_sources_client/ht_sources_client.dart';
import 'package:ht_sources_repository/ht_sources_repository.dart';

/// {@template source_filter_page}
/// A page dedicated to selecting news sources for filtering headlines.
///
/// Fetches sources paginatively, allows multiple selections, and returns
/// the selected list via `context.pop` when the user applies the changes.
/// {@endtemplate}
class SourceFilterPage extends StatefulWidget {
  /// {@macro source_filter_page}
  const SourceFilterPage({super.key});

  @override
  State<SourceFilterPage> createState() => _SourceFilterPageState();
}

/// State for the [SourceFilterPage].
///
/// Manages the local selection state ([_pageSelectedSources]), fetches
/// sources from the [HtSourcesRepository], handles pagination using a
/// [ScrollController], and displays loading/error/empty/loaded states.
class _SourceFilterPageState extends State<SourceFilterPage> {
  /// Stores the sources selected by the user on this page.
  /// Initialized from the `extra` parameter passed during navigation.
  late Set<Source> _pageSelectedSources;

  /// List of all sources fetched from the repository.
  List<Source> _allSources = [];

  /// Flag indicating if the initial source list is being loaded.
  bool _isLoading = true;

  /// Flag indicating if more sources are being loaded for pagination.
  bool _isLoadingMore = false;

  /// Flag indicating if more sources are available to fetch.
  bool _hasMore = true;

  /// Cursor for fetching the next page of sources.
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
      final initialSelection = GoRouterState.of(context).extra as List<Source>?;
      _pageSelectedSources = Set.from(initialSelection ?? []);
      _fetchSources(); // Initial fetch
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

  /// Fetches sources from the [HtSourcesRepository].
  ///
  /// Handles both initial fetch and pagination (`loadMore = true`). Updates
  /// loading states, fetched data ([_allSources]), pagination info
  /// ([_cursor], [_hasMore]), and error state ([_error]).
  Future<void> _fetchSources({bool loadMore = false}) async {
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
      // Ensure HtSourcesRepository is provided higher up in the widget tree
      final repo = context.read<HtSourcesRepository>();
      final response = await repo.getSources(
        limit: 20, // Adjust limit as needed
        startAfterId: loadMore ? _cursor : null,
      );

      setState(() {
        if (loadMore) {
          _allSources.addAll(response.items);
        } else {
          _allSources = response.items;
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
  /// fetching more sources if available.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= (maxScroll * 0.9) && _hasMore && !_isLoadingMore) {
      _fetchSources(loadMore: true);
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
              context.pop(_pageSelectedSources.toList());
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
        icon: Icons.source_outlined,
        headline: l10n.sourceFilterLoadingHeadline,
        subheadline: l10n.sourceFilterLoadingSubheadline,
      );
    }

    if (_error != null) {
      return FailureStateWidget(message: _error!, onRetry: _fetchSources);
    }

    if (_allSources.isEmpty) {
      return InitialStateWidget(
        icon: Icons.search_off,
        headline: l10n.sourceFilterEmptyHeadline,
        subheadline: l10n.sourceFilterEmptySubheadline,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: _allSources.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _allSources.length) {
          return _isLoadingMore
              ? const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
              : const SizedBox.shrink();
        }

        final source = _allSources[index];
        final isSelected = _pageSelectedSources.contains(source);

        // Sources don't have icons in the model, so just use text
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
            setState(() {
              if (value == true) {
                _pageSelectedSources.add(source);
              } else {
                _pageSelectedSources.remove(source);
              }
            });
          },
        );
      },
    );
  }
}
