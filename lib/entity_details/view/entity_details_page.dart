// ignore_for_file: no_default_cases

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/account_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_placeholder.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/ad_loader_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/entity_details/bloc/entity_details_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/shared.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_core/feed_core.dart';
import 'package:go_router/go_router.dart';
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

  static Route<void> route({required EntityDetailsPageArguments args}) {
    return MaterialPageRoute<void>(
      builder: (_) => EntityDetailsPage(args: args),
    );
  }

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

          final description = state.entity is Topic
              ? (state.entity! as Topic).description
              : state.entity is Source
                  ? (state.entity! as Source).description
                  : state.entity is Country
                      ? (state.entity! as Country)
                          .name // Using name as description for country
                      : null;

          final followButton = IconButton(
            icon: Icon(
              state.isFollowing ? Icons.check_circle : Icons.add_circle_outline,
              color: colorScheme.primary,
            ),
            tooltip: state.isFollowing
                ? l10n.unfollowButtonLabel
                : l10n.followButtonLabel,
            onPressed: () {
              context.read<EntityDetailsBloc>().add(
                    const EntityDetailsToggleFollowRequested(),
                  );
            },
          );

          final entityIconUrl = (state.entity is Topic)
              ? (state.entity! as Topic).iconUrl
              : (state.entity is Country)
                  ? (state.entity! as Country).flagUrl
                  : null;

          final Widget appBarTitleWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entityIconUrl != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                    child: Image.network(
                      entityIconUrl,
                      width: kToolbarHeight - AppSpacing.lg,
                      height: kToolbarHeight - AppSpacing.lg,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        appBarIconData ?? Icons.info_outline,
                        size: kToolbarHeight - AppSpacing.xl,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else if (appBarIconData != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Icon(
                    appBarIconData,
                    size: kToolbarHeight - AppSpacing.xl,
                    color: colorScheme.onSurface,
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
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.paddingMedium),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (description != null && description.isNotEmpty) ...[
                      Text(
                        description,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (state.feedItems.isNotEmpty ||
                        state.status == EntityDetailsStatus.loadingMore) ...[
                      Text(
                        l10n.headlinesSectionTitle,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: AppSpacing.lg, thickness: 1),
                    ],
                  ]),
                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.paddingMedium,
                  ),
                  sliver: SliverList.separated(
                    itemCount: state.feedItems.length +
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
                            .watch<AppBloc>()
                            .state
                            .settings
                            .feedPreferences
                            .headlineImageStyle;
                        Widget tile;
                        switch (imageStyle) {
                          case HeadlineImageStyle.hidden:
                            tile = HeadlineTileTextOnly(
                              headline: item,
                              onHeadlineTap: () => context.pushNamed(
                                Routes.globalArticleDetailsName,
                                pathParameters: {'id': item.id},
                                extra: item,
                              ),
                            );
                          case HeadlineImageStyle.smallThumbnail:
                            tile = HeadlineTileImageStart(
                              headline: item,
                              onHeadlineTap: () => context.pushNamed(
                                Routes.globalArticleDetailsName,
                                pathParameters: {'id': item.id},
                                extra: item,
                              ),
                            );
                          case HeadlineImageStyle.largeThumbnail:
                            tile = HeadlineTileImageTop(
                              headline: item,
                              onHeadlineTap: () => context.pushNamed(
                                Routes.globalArticleDetailsName,
                                pathParameters: {'id': item.id},
                                extra: item,
                              ),
                            );
                        }
                        return tile;
                      } else if (item is AdPlaceholder) {
                        // Retrieve the user's preferred headline image style from the AppBloc.
                        // This is the single source of truth for this setting.
                        final imageStyle = context
                            .watch<AppBloc>()
                            .state
                            .settings
                            .feedPreferences
                            .headlineImageStyle;

                        return AdLoaderWidget(
                          adPlaceholder: item,
                          adService: context.read<AdService>(),
                          adThemeStyle: AdThemeStyle.fromTheme(
                            Theme.of(context),
                          ),
                          imageStyle: imageStyle,
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
