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
    required this.allItems,
    required this.initialSelectedItems,
    required this.itemBuilder,
    super.key,
  });

  /// The title displayed in the `AppBar`.
  final String title;

  /// The complete list of items of type [T] to be displayed and filtered.
  final List<T> allItems;

  /// The initial set of selected items.
  final Set<T> initialSelectedItems;

  /// A function that returns the display string for an item of type [T].
  final String Function(T item) itemBuilder;

  @override
  State<MultiSelectSearchPage<T>> createState() =>
      _MultiSelectSearchPageState<T>();
}

class _MultiSelectSearchPageState<T> extends State<MultiSelectSearchPage<T>> {
  late final Set<T> _selectedItems;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedItems = Set<T>.from(widget.initialSelectedItems);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    final filteredItems = widget.allItems.where((item) {
      final itemName = widget.itemBuilder(item).toLowerCase();
      return itemName.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () => Navigator.of(context).pop(_selectedItems),
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
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final isSelected = _selectedItems.contains(item);
                return CheckboxListTile(
                  title: Text(widget.itemBuilder(item)),
                  value: isSelected,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        if (value) {
                          _selectedItems.add(item);
                        } else {
                          _selectedItems.remove(item);
                        }
                      });
                    }
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
