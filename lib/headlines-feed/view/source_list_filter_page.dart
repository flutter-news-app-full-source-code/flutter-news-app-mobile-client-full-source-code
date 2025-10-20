// ignore_for_file: lines_longer_than_80_chars

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/extensions/extensions.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template source_list_filter_page}
/// A dedicated page for selecting filter criteria for the source list.
///
/// This page allows users to filter sources by their headquarters country
/// and by their type (e.g., News Agency, Blog). It manages its own local
/// state and returns the selected criteria to the previous page.
/// {@endtemplate}
class SourceListFilterPage extends StatefulWidget {
  /// {@macro source_list_filter_page}
  const SourceListFilterPage({
    required this.allCountries,
    required this.allSourceTypes,
    required this.initialSelectedHeadquarterCountries,
    required this.initialSelectedSourceTypes,
    super.key,
  });

  /// All available countries to be used as headquarters filter options.
  final List<Country> allCountries;

  /// All available source types to be used as filter options.
  final List<SourceType> allSourceTypes;

  /// The set of headquarters countries that were initially selected.
  final Set<Country> initialSelectedHeadquarterCountries;

  /// The set of source types that were initially selected.
  final Set<SourceType> initialSelectedSourceTypes;

  @override
  State<SourceListFilterPage> createState() => _SourceListFilterPageState();
}

class _SourceListFilterPageState extends State<SourceListFilterPage> {
  late Set<Country> _selectedHeadquarterCountries;
  late Set<SourceType> _selectedSourceTypes;

  @override
  void initState() {
    super.initState();
    // Initialize the local state with the initial selections passed in.
    _selectedHeadquarterCountries = Set.from(
      widget.initialSelectedHeadquarterCountries,
    );
    _selectedSourceTypes = Set.from(widget.initialSelectedSourceTypes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.sourceListFilterPageTitle,
          style: textTheme.titleLarge,
        ),
        actions: [
          // Apply button returns the selected criteria to the previous page.
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () {
              Navigator.of(context).pop({
                'countries': _selectedHeadquarterCountries,
                'types': _selectedSourceTypes,
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          // Section for filtering by headquarters country.
          ListTile(
            title: Text(l10n.headlinesFeedFilterSourceCountryLabel),
            subtitle: Text(
              _selectedHeadquarterCountries.isEmpty
                  ? l10n.headlinesFeedFilterAllLabel
                  : l10n.headlinesFeedFilterSelectedCountLabel(
                      _selectedHeadquarterCountries.length,
                    ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final result = await context.pushNamed<Set<dynamic>>(
                Routes.multiSelectSearchName,
                extra: {
                  'title': l10n.headlinesFeedFilterSourceCountryLabel,
                  'allItems': widget.allCountries,
                  'initialSelectedItems': _selectedHeadquarterCountries,
                  'itemBuilder': (Country country) => country.name,
                },
              );

              if (result != null && mounted) {
                setState(
                  () => _selectedHeadquarterCountries = result.cast<Country>(),
                );
              }
            },
          ),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.lg),

          // Section for filtering by source type.
          _buildSectionHeader(context, l10n.headlinesFeedFilterSourceTypeLabel),
          ...widget.allSourceTypes.map(
            (sourceType) => CheckboxListTile(
              title: Text(sourceType.l10n(l10n)),
              value: _selectedSourceTypes.contains(sourceType),
              onChanged: (isSelected) {
                setState(() {
                  if (isSelected == true) {
                    _selectedSourceTypes.add(sourceType);
                  } else {
                    _selectedSourceTypes.remove(sourceType);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header for a filter section.
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.paddingMedium),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
