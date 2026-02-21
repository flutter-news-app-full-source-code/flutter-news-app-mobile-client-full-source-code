import 'dart:async';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template multi_select_search_page}
/// A generic and reusable page for selecting multiple items from a searchable
/// list.
///
/// This widget is designed to be pushed onto the navigation stack and return
/// a `Set<T>` of the selected items when popped.
/// {@endtemplate}
class MultiSelectSearchPage<T> extends StatefulWidget {
  /// {@macro multi_select_search_page}
  const MultiSelectSearchPage({
    required this.title,
    required this.initialSelectedItems,
    required this.itemBuilder,
    this.maxSelectionCount,
    this.allItems,
    this.repository,
    super.key,
  }) : assert(
         (allItems != null && repository == null) ||
             (allItems == null && repository != null),
         'Provide either allItems (for client-side search) or a repository '
         '(for server-side search), but not both.',
       );

  /// The title displayed in the `AppBar`.
  final String title;

  /// The complete list of items of type [T] to be displayed and filtered.
  /// Used for legacy, client-side filtering.
  final List<T>? allItems;

  /// The data repository to fetch items from.
  /// Used for new, paginated, server-side filtering.
  final DataRepository<T>? repository;

  /// The initial set of selected items.
  final Set<T> initialSelectedItems;

  /// The maximum number of items that can be selected.
  /// If provided, disables selection when the limit is reached.
  final int? maxSelectionCount;

  /// A function that returns the display string for an item of type [T].
  final String Function(T item) itemBuilder;

  @override
  State<MultiSelectSearchPage<T>> createState() =>
      _MultiSelectSearchPageState<T>();
}

class _MultiSelectSearchPageState<T> extends State<MultiSelectSearchPage<T>> {
  late final Set<T> _selectedItems;
  late final bool _isPaginated;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  // State for paginated mode
  final List<T> _paginatedItems = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _cursor;
  String _searchQuery = '';
  HttpException? _error;

  @override
  void initState() {
    super.initState();
    _selectedItems = Set<T>.from(widget.initialSelectedItems);
    _isPaginated = widget.repository != null;

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (_searchQuery != _searchController.text) {
          setState(() => _searchQuery = _searchController.text);
          if (_isPaginated) {
            _resetAndFetch();
          }
        }
      });
    });

    if (_isPaginated) {
      _scrollController.addListener(_onScroll);
      _resetAndFetch();
    }
  }

  void _resetAndFetch() {
    _paginatedItems.clear();
    _cursor = null;
    _hasMore = true;
    _error = null;
    _fetchPage();
  }

  Future<void> _fetchPage() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final filter = _searchQuery.isNotEmpty
          ? <String, dynamic>{'q': _searchQuery}
          : null;

      final response = await widget.repository!.readAll(
        filter: filter,
        pagination: PaginationOptions(cursor: _cursor, limit: 20),
      );

      if (!mounted) return;

      setState(() {
        _paginatedItems.addAll(response.items);
        _hasMore = response.hasMore;
        _cursor = response.cursor;
        _isLoading = false;
      });
    } on HttpException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Widget _buildLeadingForItem(T item) {
    if (item is Topic) {
      return CircleAvatar(
        backgroundImage: item.iconUrl != null
            ? NetworkImage(item.iconUrl!)
            : null,
        child: item.iconUrl == null ? const Icon(Icons.tag) : null,
      );
    } else if (item is Source) {
      return CircleAvatar(
        backgroundImage: item.logoUrl != null
            ? NetworkImage(item.logoUrl!)
            : null,
        child: item.logoUrl == null ? const Icon(Icons.public) : null,
      );
    } else if (item is Country) {
      return CircleAvatar(backgroundImage: NetworkImage(item.flagUrl));
    }
    // Fallback for any other type that might be used with this page.
    return const CircleAvatar(child: Icon(Icons.article_outlined));
  }

  void _onScroll() {
    if (_isBottom) _fetchPage();
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    final List<T> displayItems;
    if (_isPaginated) {
      displayItems = _paginatedItems;
    } else {
      displayItems = widget.allItems!.where((item) {
        final itemName = widget.itemBuilder(item).toLowerCase();
        return itemName.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: theme.textTheme.titleLarge),
        actions: [
          if (widget.maxSelectionCount != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  l10n.multiSelectSearchPageSelectionCount(
                    _selectedItems.length,
                    widget.maxSelectionCount!,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(_selectedItems),
              child: Text(l10n.saveButtonLabel),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchHintTextGeneric,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppSpacing.sm),
                  ),
                ),
              ),
            ),
          ),
          if (_isPaginated && _error != null)
            Expanded(
              child: FailureStateWidget(
                exception: _error!,
                onRetry: _resetAndFetch,
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _isPaginated ? _scrollController : null,
                itemCount:
                    displayItems.length + (_isPaginated && _isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isPaginated &&
                      _isLoading &&
                      index == displayItems.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final item = displayItems[index];
                  final isSelected = _selectedItems.contains(item);
                  final isLimitReached =
                      widget.maxSelectionCount != null &&
                      _selectedItems.length >= widget.maxSelectionCount!;
                  final canSelectItem = !(!isSelected && isLimitReached);

                  return ListTile(
                    leading: _buildLeadingForItem(item),
                    title: Text(widget.itemBuilder(item)),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: canSelectItem
                          ? (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedItems.add(item);
                                } else {
                                  _selectedItems.remove(item);
                                }
                              });
                            }
                          : null,
                    ),
                    onTap: canSelectItem
                        ? () {
                            setState(() {
                              if (isSelected) {
                                _selectedItems.remove(item);
                              } else {
                                _selectedItems.add(item);
                              }
                            });
                          }
                        : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
