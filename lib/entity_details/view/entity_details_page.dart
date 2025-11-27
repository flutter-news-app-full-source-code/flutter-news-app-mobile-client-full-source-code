// ignore_for_file: no_default_cases

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_placeholder.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/feed_ad_loader_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/entity_details/bloc/entity_details_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_core/feed_core.dart';
import 'package:ui_kit/ui_kit.dart';

class EntityDetailsPageArguments {
  const EntityDetailsPageArguments({
    required this.entityId,
    required this.contentType,
  });

  final String entityId;
  final ContentType contentType;
}

class EntityDetailsPage extends StatelessWidget {
  const EntityDetailsPage({required this.args, super.key});
  final EntityDetailsPageArguments args;

  @override
  Widget build(BuildContext context) {
    return EntityDetailsView(args: args);
  }
}

class EntityDetailsView extends StatefulWidget {
  const EntityDetailsView({required this.args, super.key});

  final EntityDetailsPageArguments args;

  @override
  State<EntityDetailsView> createState() => _EntityDetailsViewState();
}

class _EntityDetailsViewState extends State<EntityDetailsView> {
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
      context.read<EntityDetailsBloc>().add(
        EntityDetailsLoadMoreHeadlinesRequested(
          adThemeStyle: AdThemeStyle.fromTheme(Theme.of(context)),
        ),
      );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Trigger load a bit before reaching the absolute bottom
    return currentScroll >= (maxScroll * 0.9);
  }

  String _getContentTypeDisplayName(ContentType? type, AppLocalizations l10n) {
    if (type == null) return l10n.detailsPageTitle;
    String name;
    switch (type) {
      case ContentType.topic:
        name = l10n.entityDetailsTopicTitle;
      case ContentType.source:
        name = l10n.entityDetailsSourceTitle;
      case ContentType.country:
        name = l10n.entityDetailsCountryTitle;
      default:
        name = l10n.detailsPageTitle;
    }
    return name.isNotEmpty
        ? '${name[0].toUpperCase()}${name.substring(1)}'
        : name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: BlocBuilder<EntityDetailsBloc, EntityDetailsState>(
        builder: (context, state) {
          final entityTypeDisplayNameForTitle = _getContentTypeDisplayName(
            state.contentType,
            l10n,
          );

          if (state.status == EntityDetailsStatus.initial ||
              (state.status == EntityDetailsStatus.loading &&
                  state.entity == null)) {
            return LoadingStateWidget(
              icon: Icons.info_outline,
              headline: entityTypeDisplayNameForTitle,
              subheadline: l10n.pleaseWait,
            );
          }

          if (state.status == EntityDetailsStatus.failure &&
              state.entity == null) {
            return FailureStateWidget(
              exception: state.exception!,
              onRetry: () => context.read<EntityDetailsBloc>().add(
                EntityDetailsLoadRequested(
                  entityId: widget.args.entityId,
                  contentType: widget.args.contentType,
                  adThemeStyle: AdThemeStyle.fromTheme(theme),
                ),
              ),
            );
          }

          final String appBarTitleText;
          IconData? appBarIconData;

          if (state.entity is Topic) {
            final topic = state.entity! as Topic;
            appBarTitleText = topic.name;
            appBarIconData = Icons.category_outlined;
          } else if (state.entity is Source) {
            final src = state.entity! as Source;
            appBarTitleText = src.name;
            appBarIconData = Icons.source_outlined;
          } else if (state.entity is Country) {
            final country = state.entity! as Country;
            appBarTitleText = country.name;
            appBarIconData = Icons.flag_outlined;
          } else {
            appBarTitleText = l10n.detailsPageTitle;
          }

          final followButton = IconButton(
            icon: Icon(
              state.isFollowing ? Icons.check_circle : Icons.add_circle_outline,
              color: colorScheme.primary,
            ),
            tooltip: state.isFollowing
                ? l10n.unfollowButtonLabel
                : l10n.followButtonLabel,
            onPressed: () {
              // If the user is unfollowing, always allow it.
              if (state.isFollowing) {
                context.read<EntityDetailsBloc>().add(
                  const EntityDetailsToggleFollowRequested(),
                );
              } else {
                // If the user is following, check the limit first.
                final limitationService = context
                    .read<ContentLimitationService>();
                final contentType = state.contentType;

                if (contentType == null) return;

                final action = switch (contentType) {
                  ContentType.topic => ContentAction.followTopic,
                  ContentType.source => ContentAction.followSource,
                  ContentType.country => ContentAction.followCountry,
                  _ => null,
                };

                if (action == null) {
                  return;
                }

                final status = limitationService.checkAction(action);

                if (status == LimitationStatus.allowed) {
                  context.read<EntityDetailsBloc>().add(
                    const EntityDetailsToggleFollowRequested(),
                  );
                } else {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (_) =>
                        ContentLimitationBottomSheet(status: status),
                  );
                }
              }
            },
          );

          final entityIconUrl = switch (state.entity) {
            final Topic topic => topic.iconUrl,
            final Country country => country.flagUrl,
            final Source source => source.logoUrl,
            _ => null,
          };

          final Widget appBarTitleWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entityIconUrl != null)
                Padding(
                  padding: Directionality.of(context) == TextDirection.ltr
                      ? const EdgeInsets.only(right: AppSpacing.md)
                      : const EdgeInsets.only(left: AppSpacing.md),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                    child: Image.network(
                      entityIconUrl,
                      width: AppSpacing.xxl,
                      height: AppSpacing.xxl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        appBarIconData,
                        size: AppSpacing.xxl,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  appBarTitleText,
                  style: textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                title: appBarTitleWidget,
                pinned: true,
                floating: false,
                snap: false,
                actions: [
                  followButton,
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),
              if (state.feedItems.isEmpty &&
                  state.status != EntityDetailsStatus.initial &&
                  state.status != EntityDetailsStatus.loadingMore &&
                  state.status == EntityDetailsStatus.success)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.paddingLarge),
                      child: Text(
                        l10n.noHeadlinesFoundMessage,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.paddingMedium,
                    left: AppSpacing.paddingMedium,
                    right: AppSpacing.paddingMedium,
                  ),
                  sliver: SliverList.separated(
                    itemCount:
                        state.feedItems.length +
                        (state.hasMoreHeadlines &&
                                state.status == EntityDetailsStatus.loadingMore
                            ? 1
                            : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index >= state.feedItems.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final item = state.feedItems[index];

                      if (item is Headline) {
                        final imageStyle = context
                            .read<AppBloc>()
                            .state
                            .feedItemImageStyle;
                        Widget tile;
                        switch (imageStyle) {
                          case FeedItemImageStyle.hidden:
                            tile = HeadlineTileTextOnly(
                              headline: item,
                              onHeadlineTap: () =>
                                  HeadlineTapHandler.handleHeadlineTap(
                                      context, item),
                            );
                          case FeedItemImageStyle.smallThumbnail:
                            tile = HeadlineTileImageStart(
                              headline: item,
                              onHeadlineTap: () =>
                                  HeadlineTapHandler.handleHeadlineTap(
                                      context, item),
                            );
                          case FeedItemImageStyle.largeThumbnail:
                            tile = HeadlineTileImageTop(
                              headline: item,
                              onHeadlineTap: () =>
                                  HeadlineTapHandler.handleHeadlineTap(
                                      context, item),
                            );
                        }
                        return tile;
                      } else if (item is AdPlaceholder) {
                        // Retrieve the user's preferred headline image style from the AppBloc.
                        // This is the single source of truth for this setting.
                        // Access the AppBloc to get the remoteConfig for ads.
                        final remoteConfig = context
                            .read<AppBloc>()
                            .state
                            .remoteConfig;

                        // Ensure adConfig is not null before building the AdLoaderWidget.
                        if (remoteConfig?.features.ads == null) {
                          // Return an empty widget or a placeholder if adConfig is not available.
                          return const SizedBox.shrink();
                        }

                        return FeedAdLoaderWidget(
                          contextKey: widget.args.entityId,
                          adPlaceholder: item,
                          adThemeStyle: AdThemeStyle.fromTheme(
                            Theme.of(context),
                          ),
                          remoteConfig: remoteConfig!,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              if (state.status == EntityDetailsStatus.partialFailure &&
                  state.feedItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.paddingMedium),
                    child: Text(
                      state.exception?.toFriendlyMessage(context) ??
                          l10n.failedToLoadMoreHeadlines,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          );
        },
      ),
    );
  }
}
