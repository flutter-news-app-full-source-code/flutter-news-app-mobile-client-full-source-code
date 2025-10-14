import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template saved_filters_bar}
/// A horizontal, scrollable bar that displays saved feed filters.
///
/// This widget allows users to quickly switch between their saved filters,
/// an "All" filter, and a "Custom" filter state. It also provides an entry
/// point to the main filter page.
/// {@endtemplate}
class SavedFiltersBar extends StatelessWidget {
  /// {@macro saved_filters_bar}
  const SavedFiltersBar({super.key});

  static const _allFilterId = 'all';
  static const _customFilterId = 'custom';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    return SizedBox(
      height: 48,
      child: BlocBuilder<HeadlinesFeedBloc, HeadlinesFeedState>(
        builder: (context, state) {
          final savedFilters = state.savedFilters;
          final activeFilterId = state.activeFilterId;

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              // Button to open the filter page
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: l10n.savedFiltersBarOpenTooltip,
                onPressed: () => context.goNamed(Routes.feedFilterName),
              ),
              const VerticalDivider(
                width: AppSpacing.md,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),

              // "All" filter chip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: ChoiceChip(
                  label: Text(l10n.savedFiltersBarAllLabel),
                  selected: activeFilterId == _allFilterId,
                  onSelected: (_) {
                    context.read<HeadlinesFeedBloc>().add(
                      AllFilterSelected(
                        adThemeStyle: AdThemeStyle.fromTheme(theme),
                      ),
                    );
                  },
                ),
              ),

              // Saved filter chips
              ...savedFilters.map(
                (filter) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: ChoiceChip(
                    label: Text(filter.name),
                    selected: activeFilterId == filter.id,
                    onSelected: (_) {
                      context.read<HeadlinesFeedBloc>().add(
                        SavedFilterSelected(
                          filter: filter,
                          adThemeStyle: AdThemeStyle.fromTheme(theme),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // "Custom" filter chip (conditionally rendered)
              if (activeFilterId == _customFilterId)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: ChoiceChip(
                    label: Text(l10n.savedFiltersBarCustomLabel),
                    // Always selected when visible, but disabled to prevent
                    // user interaction. It's a status indicator.
                    selected: true,
                    onSelected: null,
                    selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
