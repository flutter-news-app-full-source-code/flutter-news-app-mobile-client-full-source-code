import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/discover/bloc/source_list_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template source_list_filter_page}
/// A page for filtering sources by their headquarters country.
/// {@endtemplate}
class SourceListFilterPage extends StatelessWidget {
  /// {@macro source_list_filter_page}
  const SourceListFilterPage({required this.sourceListBloc, super.key});

  /// The BLoC that manages the state of the source list.
  final SourceListBloc sourceListBloc;

  @override
  Widget build(BuildContext context) {
    // Provide the existing bloc instance to this widget subtree.
    return BlocProvider.value(
      value: sourceListBloc,
      child: const _SourceListFilterView(),
    );
  }
}

class _SourceListFilterView extends StatefulWidget {
  const _SourceListFilterView();

  @override
  State<_SourceListFilterView> createState() => _SourceListFilterViewState();
}

class _SourceListFilterViewState extends State<_SourceListFilterView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<SourceListBloc>().add(
        SourceListCountriesLoadMoreRequested(),
      );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sourceListFilterByHeadquartersPageTitle),
        actions: [
          // The "Apply" button simply pops the page. The BLoC handles the
          // state change and triggers a refetch on the previous page.
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.headlinesFeedFilterApplyButton,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: BlocBuilder<SourceListBloc, SourceListState>(
        builder: (context, state) {
          if (state.countries.isEmpty) {
            return InitialStateWidget(
              icon: Icons.flag_circle_outlined,
              headline: l10n.countryFilterEmptyHeadline,
              subheadline: l10n.countryFilterEmptySubheadline,
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
            ).copyWith(bottom: AppSpacing.xxl),
            itemCount: state.countriesHasMore
                ? state.countries.length + 1
                : state.countries.length,
            itemBuilder: (context, index) {
              // If we've reached the end of the list, show a loading indicator
              // if more items are being fetched.
              if (index >= state.countries.length) {
                return state.status == SourceListStatus.loadingMoreCountries
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox.shrink();
              }
              final country = state.countries[index];
              final isSelected = state.selectedCountries.contains(country);

              return CheckboxListTile(
                title: Text(country.name, style: textTheme.titleMedium),
                secondary: SizedBox(
                  width: AppSpacing.xl + AppSpacing.xs,
                  height: AppSpacing.lg + AppSpacing.sm,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.xs / 2),
                    child: Image.network(
                      country.flagUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.flag_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: AppSpacing.lg,
                      ),
                    ),
                  ),
                ),
                value: isSelected,
                onChanged: (bool? value) {
                  if (value == null) return;
                  final newSelection = Set<Country>.from(
                    state.selectedCountries,
                  );
                  if (value) {
                    newSelection.add(country);
                  } else {
                    newSelection.remove(country);
                  }
                  context.read<SourceListBloc>().add(
                    SourceListCountryFilterChanged(
                      selectedCountries: newSelection,
                    ),
                  );
                },
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          );
        },
      ),
    );
  }
}
