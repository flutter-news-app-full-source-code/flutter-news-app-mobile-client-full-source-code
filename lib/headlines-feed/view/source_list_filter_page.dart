// ignore_for_file: lines_longer_than_80_chars

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
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
  late final Set<Country> _selectedHeadquarterCountries;
  late final Set<SourceType> _selectedSourceTypes;

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
          _buildSectionHeader(
            context,
            l10n.headlinesFeedFilterSourceCountryLabel,
          ),
          _buildCountryCapsules(context, widget.allCountries, l10n, textTheme),
          const SizedBox(height: AppSpacing.lg),

          // Section for filtering by source type.
          _buildSectionHeader(context, l10n.headlinesFeedFilterSourceTypeLabel),
          _buildSourceTypeCapsules(
            context,
            widget.allSourceTypes,
            l10n,
            textTheme,
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

  /// Builds the horizontal list of [ChoiceChip] widgets for countries.
  Widget _buildCountryCapsules(
    BuildContext context,
    List<Country> allCountries,
    AppLocalizations l10n,
    TextTheme textTheme,
  ) {
    return SizedBox(
      height: AppSpacing.xl + AppSpacing.md,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingMedium,
          vertical: AppSpacing.sm,
        ),
        itemCount: allCountries.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // The 'All' chip.
            return ChoiceChip(
              label: Text(l10n.headlinesFeedFilterAllLabel),
              labelStyle: textTheme.labelLarge,
              selected: _selectedHeadquarterCountries.isEmpty,
              onSelected: (_) => setState(_selectedHeadquarterCountries.clear),
            );
          }
          final country = allCountries[index - 1];
          return Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: ChoiceChip(
              avatar: country.flagUrl.isNotEmpty
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(country.flagUrl),
                      radius: AppSpacing.sm + AppSpacing.xs,
                    )
                  : null,
              label: Text(country.name),
              labelStyle: textTheme.labelLarge,
              selected: _selectedHeadquarterCountries.contains(country),
              onSelected: (isSelected) {
                setState(() {
                  if (isSelected) {
                    _selectedHeadquarterCountries.add(country);
                  } else {
                    _selectedHeadquarterCountries.remove(country);
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }

  /// Builds the horizontal list of [ChoiceChip] widgets for source types.
  Widget _buildSourceTypeCapsules(
    BuildContext context,
    List<SourceType> allSourceTypes,
    AppLocalizations l10n,
    TextTheme textTheme,
  ) {
    return SizedBox(
      height: AppSpacing.xl + AppSpacing.md,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingMedium,
          vertical: AppSpacing.sm,
        ),
        itemCount: allSourceTypes.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // The 'All' chip.
            return ChoiceChip(
              label: Text(l10n.headlinesFeedFilterAllLabel),
              labelStyle: textTheme.labelLarge,
              selected: _selectedSourceTypes.isEmpty,
              onSelected: (_) => setState(_selectedSourceTypes.clear),
            );
          }
          final sourceType = allSourceTypes[index - 1];
          return Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(sourceType.name),
              labelStyle: textTheme.labelLarge,
              selected: _selectedSourceTypes.contains(sourceType),
              onSelected: (isSelected) {
                setState(() {
                  if (isSelected) {
                    _selectedSourceTypes.add(sourceType);
                  } else {
                    _selectedSourceTypes.remove(sourceType);
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }
}
