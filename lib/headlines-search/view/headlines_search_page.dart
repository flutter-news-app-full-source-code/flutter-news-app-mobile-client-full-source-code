//
//
// ignore_for_file: lines_longer_than_80_chars

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/interstitial_ad_manager.dart';
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

/// {@template headlines_search_page}
/// The main page for the headlines search feature.
///
/// This widget is responsible for building the UI for the headlines search
/// page, including the search bar, model type selection, and displaying
/// search results. It consumes state from [HeadlinesSearchBloc] and
/// dispatches events for search operations. It also leverages [AppBloc]
/// for global settings like `headlineImageStyle` and `adConfig`.
/// {@endtemplate}
class HeadlinesSearchPage extends StatefulWidget {
  /// {@macro headlines_search_page}
  const HeadlinesSearchPage({super.key});

  @override
  State<HeadlinesSearchPage> createState() => _HeadlinesSearchPageState();
}

class _HeadlinesSearchPageState extends State<HeadlinesSearchPage> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _textController.addListener(() {
      setState(() {
        _showClearButton = _textController.text.isNotEmpty;
      });
    });
    // Initialize the selected model type from the BLoC's initial state.
    // This ensures consistency if the BLoC was already initialized with a
    // specific type (e.g., after a hot restart).
    final initialModelType = context
        .read<HeadlinesSearchBloc>()
        .state
        .selectedModelType;
    context.read<HeadlinesSearchBloc>().add(
      HeadlinesSearchModelTypeChanged(initialModelType),
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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.paddingSmall,
        elevation: appBarTheme.elevation ?? 0,
        title: Row(
          children: [
            // BlocBuilder to react to changes in selectedModelType from HeadlinesSearchBloc
            BlocBuilder<HeadlinesSearchBloc, HeadlinesSearchState>(
              buildWhen: (previous, current) =>
                  previous.selectedModelType != current.selectedModelType,
              builder: (context, state) {
                // Ensure the selected model type is always one of the available types.
                // If not, default to headline.
                final currentSelectedModelType =
                    availableSearchModelTypes.contains(state.selectedModelType)
                    ? state.selectedModelType
                    : ContentType.headline;

                return SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<ContentType>(
                    value: currentSelectedModelType,
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
                    items: availableSearchModelTypes.map((ContentType type) {
                      return DropdownMenuItem<ContentType>(
                        value: type,
                        child: Text(type.displayName(context)),
                      );
                    }).toList(),
                    onChanged: (ContentType? newValue) {
                      if (newValue != null) {
                        context.read<HeadlinesSearchBloc>().add(
                          HeadlinesSearchModelTypeChanged(newValue),
                        );
                      }
                    },
                  ),
                );
              },
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
                      icon: Icons.search_off_outlined,
                      headline: l10n.headlinesSearchNoResultsHeadline,
                      subheadline:
                          'For "$lastSearchTerm" in ${resultsModelType.displayName(context).toLowerCase()}.\n${l10n.headlinesSearchNoResultsSubheadline}',
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
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
                              .headlineImageStyle;
                          Widget tile;
                          Future<void> onHeadlineTap() async {
                            await context
                                .read<InterstitialAdManager>()
                                .onPotentialAdTrigger();

                            if (!context.mounted) return;

                            await context.pushNamed(
                              Routes.searchArticleDetailsName,
                              pathParameters: {'id': feedItem.id},
                              extra: feedItem,
                            );
                          }

                          switch (imageStyle) {
                            case HeadlineImageStyle.hidden:
                              tile = HeadlineTileTextOnly(
                                headline: feedItem,
                                onHeadlineTap: onHeadlineTap,
                              );
                            case HeadlineImageStyle.smallThumbnail:
                              tile = HeadlineTileImageStart(
                                headline: feedItem,
                                onHeadlineTap: onHeadlineTap,
                              );
                            case HeadlineImageStyle.largeThumbnail:
                              tile = HeadlineTileImageTop(
                                headline: feedItem,
                                onHeadlineTap: onHeadlineTap,
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
                          final adConfig = context
                              .watch<AppBloc>()
                              .state
                              .remoteConfig
                              ?.adConfig;

                          if (adConfig == null) {
                            return const SizedBox.shrink();
                          }

                          return FeedAdLoaderWidget(
                            adPlaceholder: feedItem,
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
