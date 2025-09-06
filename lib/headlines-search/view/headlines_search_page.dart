//
//
// ignore_for_file: lines_longer_than_80_chars

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_placeholder.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/feed_ad_loader_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
// HeadlineItemWidget import removed
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-search/bloc/headlines_search_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-search/widgets/country_item_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-search/widgets/source_item_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-search/widgets/topic_item_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/extensions/content_type_extensions.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/shared.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_core/feed_core.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// Page widget responsible for providing the BLoC for the headlines search feature.
class HeadlinesSearchPage extends StatelessWidget {
  const HeadlinesSearchPage({super.key});

  /// Defines the route for this page.
  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HeadlinesSearchPage());
  }

  @override
  Widget build(BuildContext context) {
    return const _HeadlinesSearchView();
  }
}

/// Private View widget that builds the UI for the headlines search page.
/// It listens to the HeadlinesSearchBloc state and displays the appropriate UI.
class _HeadlinesSearchView extends StatefulWidget {
  const _HeadlinesSearchView();

  @override
  State<_HeadlinesSearchView> createState() => _HeadlinesSearchViewState();
}

class _HeadlinesSearchViewState extends State<_HeadlinesSearchView> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  bool _showClearButton = false;
  ContentType _selectedModelType = ContentType.headline;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _textController.addListener(() {
      setState(() {
        _showClearButton = _textController.text.isNotEmpty;
      });
    });
    final searchableTypes = [
      ContentType.headline,
      ContentType.topic,
      ContentType.source,
      ContentType.country,
    ];
    if (!searchableTypes.contains(_selectedModelType)) {
      _selectedModelType = ContentType.headline;
    }
    context.read<HeadlinesSearchBloc>().add(
      HeadlinesSearchModelTypeChanged(_selectedModelType),
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = context.read<HeadlinesSearchBloc>().state;
    if (_isBottom && state is HeadlinesSearchSuccess && state.hasMore) {
      context.read<HeadlinesSearchBloc>().add(
        HeadlinesSearchFetchRequested(
          searchTerm: state.lastSearchTerm,
          adThemeStyle: AdThemeStyle.fromTheme(Theme.of(context)),
        ),
      );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.98);
  }

  void _performSearch() {
    context.read<HeadlinesSearchBloc>().add(
      HeadlinesSearchFetchRequested(
        searchTerm: _textController.text,
        adThemeStyle: AdThemeStyle.fromTheme(Theme.of(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final appBarTheme = theme.appBarTheme;

    final availableSearchModelTypes = [
      ContentType.headline,
      ContentType.topic,
      ContentType.source,
      ContentType.country,
    ];

    if (!availableSearchModelTypes.contains(_selectedModelType)) {
      _selectedModelType = ContentType.headline;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<HeadlinesSearchBloc>().add(
            HeadlinesSearchModelTypeChanged(_selectedModelType),
          );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.paddingSmall,
        // backgroundColor: appBarTheme.backgroundColor ?? colorScheme.surface,
        elevation: appBarTheme.elevation ?? 0,
        title: Row(
          children: [
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<ContentType>(
                value: _selectedModelType,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  isDense: true,
                ),
                style: textTheme.titleMedium?.copyWith(
                  color:
                      appBarTheme.titleTextStyle?.color ??
                      colorScheme.onSurface,
                ),
                dropdownColor: colorScheme.surfaceContainerHighest,
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color:
                      appBarTheme.iconTheme?.color ??
                      colorScheme.onSurfaceVariant,
                ),
                // TODO(fulleni): Use the new localization extension here.
                items: availableSearchModelTypes.map((ContentType type) {
                  return DropdownMenuItem<ContentType>(
                    value: type,
                    child: Text(type.displayName(context)),
                  );
                }).toList(),
                onChanged: (ContentType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedModelType = newValue;
                    });
                    context.read<HeadlinesSearchBloc>().add(
                      HeadlinesSearchModelTypeChanged(newValue),
                    );
                    // Optionally trigger search or clear text when type changes
                    // _textController.clear();
                    // _performSearch();
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _textController,
                style: appBarTheme.titleTextStyle ?? textTheme.titleMedium,
                decoration: InputDecoration(
                  hintText: l10n.searchHintTextGeneric,
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color:
                        (appBarTheme.titleTextStyle?.color ??
                                colorScheme.onSurface)
                            .withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  filled: false,
                  // fillColor: colorScheme.surface.withAlpha(26),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  suffixIcon: _showClearButton
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color:
                                appBarTheme.iconTheme?.color ??
                                colorScheme.onSurfaceVariant,
                          ),
                          onPressed: _textController.clear,
                        )
                      : null,
                ),
                onSubmitted: (_) => _performSearch(),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            tooltip: l10n.headlinesSearchActionTooltip,
            onPressed: _performSearch,
            // color: appBarTheme.actionsIconTheme?.color,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: BlocBuilder<HeadlinesSearchBloc, HeadlinesSearchState>(
        builder: (context, state) {
          return switch (state) {
            HeadlinesSearchInitial() => InitialStateWidget(
              icon: Icons.search_outlined,
              headline: l10n.searchPageInitialHeadline,
              subheadline: l10n.searchPageInitialSubheadline,
            ),
            HeadlinesSearchLoading() => LoadingStateWidget(
              // Use LoadingStateWidget
              icon: Icons.search_outlined,
              headline: l10n.headlinesFeedLoadingHeadline,
              subheadline: l10n.searchingFor(
                state.selectedModelType.displayName(context).toLowerCase(),
              ),
            ),
            HeadlinesSearchSuccess(
              items: final items,
              hasMore: final hasMore,
              errorMessage: final errorMessage,
              lastSearchTerm: final lastSearchTerm,
              selectedModelType: final resultsModelType,
            ) =>
              errorMessage != null
                  ? FailureStateWidget(
                      exception: UnknownException(errorMessage),
                      onRetry: () => context.read<HeadlinesSearchBloc>().add(
                        HeadlinesSearchFetchRequested(
                          searchTerm: lastSearchTerm,
                          adThemeStyle: AdThemeStyle.fromTheme(theme),
                        ),
                      ),
                    )
                  : items.isEmpty
                  ? InitialStateWidget(
                      // Use InitialStateWidget for no results as it's not a failure
                      icon: Icons.search_off_outlined,
                      headline: l10n.headlinesSearchNoResultsHeadline,
                      subheadline:
                          'For "$lastSearchTerm" in ${resultsModelType.displayName(context).toLowerCase()}.\n${l10n.headlinesSearchNoResultsSubheadline}',
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        // Consistent padding
                        horizontal: AppSpacing.paddingMedium,
                        vertical: AppSpacing.paddingSmall,
                      ).copyWith(bottom: AppSpacing.xxl),
                      itemCount: hasMore ? items.length + 1 : items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index >= items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final feedItem = items[index];

                        if (feedItem is Headline) {
                          final imageStyle = context
                              .watch<AppBloc>()
                              .state
                              .settings
                              .feedPreferences
                              .headlineImageStyle;
                          Widget tile;
                          switch (imageStyle) {
                            case HeadlineImageStyle.hidden:
                              tile = HeadlineTileTextOnly(
                                headline: feedItem,
                                onHeadlineTap: () => context.goNamed(
                                  Routes.searchArticleDetailsName,
                                  pathParameters: {'id': feedItem.id},
                                  extra: feedItem,
                                ),
                              );
                            case HeadlineImageStyle.smallThumbnail:
                              tile = HeadlineTileImageStart(
                                headline: feedItem,
                                onHeadlineTap: () => context.goNamed(
                                  Routes.searchArticleDetailsName,
                                  pathParameters: {'id': feedItem.id},
                                  extra: feedItem,
                                ),
                              );
                            case HeadlineImageStyle.largeThumbnail:
                              tile = HeadlineTileImageTop(
                                headline: feedItem,
                                onHeadlineTap: () => context.goNamed(
                                  Routes.searchArticleDetailsName,
                                  pathParameters: {'id': feedItem.id},
                                  extra: feedItem,
                                ),
                              );
                          }
                          return tile;
                        } else if (feedItem is Topic) {
                          return TopicItemWidget(topic: feedItem);
                        } else if (feedItem is Source) {
                          return SourceItemWidget(source: feedItem);
                        } else if (feedItem is Country) {
                          return CountryItemWidget(country: feedItem);
                        } else if (feedItem is AdPlaceholder) {
                          // Access the AppBloc to get the remoteConfig for ads.
                          final adConfig = context
                              .read<AppBloc>()
                              .state
                              .remoteConfig
                              ?.adConfig;

                          // Ensure adConfig is not null before building the AdLoaderWidget.
                          if (adConfig == null) {
                            // Return an empty widget or a placeholder if adConfig is not available.
                            return const SizedBox.shrink();
                          }

                          return FeedAdLoaderWidget(
                            adPlaceholder: feedItem,
                            adService: context.read<AdService>(),
                            adThemeStyle: AdThemeStyle.fromTheme(
                              Theme.of(context),
                            ),
                            adConfig: adConfig,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            HeadlinesSearchFailure(
              errorMessage: final errorMessage,
              lastSearchTerm: final lastSearchTerm,
              selectedModelType: final failedModelType,
            ) =>
              FailureStateWidget(
                exception: UnknownException(
                  'Failed to search "$lastSearchTerm" in ${failedModelType.displayName(context).toLowerCase()}:\n$errorMessage',
                ),
                onRetry: () => context.read<HeadlinesSearchBloc>().add(
                  HeadlinesSearchFetchRequested(
                    searchTerm: lastSearchTerm,
                    adThemeStyle: AdThemeStyle.fromTheme(theme),
                  ),
                ),
              ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}
