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
import 'package:flutter_news_app_mobile_client_full_source_code/shared/constants/app_layout.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_core/feed_core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/reporting/view/report_content_bottom_sheet.dart';
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
  bool _isFollowingInProgress = false;

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
    final remoteConfig = context.watch<AppBloc>().state.remoteConfig;
    final communityConfig = remoteConfig?.features.community;
    final isSourceReportingEnabled =
        (communityConfig?.enabled ?? false) &&
        (communityConfig?.reporting.sourceReportingEnabled ?? false);
    final entity = context.select(
      (EntityDetailsBloc bloc) => bloc.state.entity,
    );

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

          String appBarTitleText;
          IconData? appBarIconData;

          if (entity is Topic) {
            final topic = entity;
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

          final entityIconUrl = switch (entity) {
            final Topic topic => topic.iconUrl,
            final Country country => country.flagUrl,
            final Source source => source.logoUrl,
            _ => null,
          };

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < AppLayout.tabletBreakpoint) {
                    // Compact view (phones)
                    return _buildCompactView(
                      context,
                      state,
                      l10n,
                      textTheme,
                      colorScheme,
                      appBarTitleText,
                      appBarIconData,
                      entityIconUrl,
                      isSourceReportingEnabled,
                    );
                  } else {
                    // Expanded view (tablets)
                    return _buildExpandedView(
                      context,
                      state,
                      l10n,
                      textTheme,
                      colorScheme,
                      appBarTitleText,
                      appBarIconData,
                      entityIconUrl,
                      isSourceReportingEnabled,
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactView(
    BuildContext context,
    EntityDetailsState state,
    AppLocalizations l10n,
    TextTheme textTheme,
    ColorScheme colorScheme,
    String appBarTitleText,
    IconData? appBarIconData,
    String? entityIconUrl,
    bool isSourceReportingEnabled,
  ) {
    final followButton = _buildFollowButton(context, state, colorScheme, l10n);
    final appBarTitleWidget = _buildAppBarTitle(
      context,
      entityIconUrl,
      appBarIconData,
      colorScheme,
      appBarTitleText,
      textTheme,
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
            if (widget.args.contentType == ContentType.source &&
                isSourceReportingEnabled)
              _buildReportPopupMenu(context, l10n)
            else
              const SizedBox.shrink(),
          ],
        ),
        _buildFeedContent(context, state, l10n, textTheme, colorScheme),
      ],
    );
  }

  Widget _buildExpandedView(
    BuildContext context,
    EntityDetailsState state,
    AppLocalizations l10n,
    TextTheme textTheme,
    ColorScheme colorScheme,
    String appBarTitleText,
    IconData? appBarIconData,
    String? entityIconUrl,
    bool isSourceReportingEnabled,
  ) {
    final followButton = _buildFollowButton(context, state, colorScheme, l10n);
    final entityDescription = switch (state.entity) {
      final Topic topic => topic.description,
      final Source source => source.description,
      _ => '',
    };

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Material(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (entityIconUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          child: Image.network(
                            entityIconUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              appBarIconData,
                              size: 48,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          appBarTitleText,
                          style: textTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: followButton),
                      if (widget.args.contentType == ContentType.source &&
                          isSourceReportingEnabled)
                        _buildReportPopupMenu(context, l10n),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (entityDescription.isNotEmpty)
                    Text(entityDescription, style: textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildFeedContent(context, state, l10n, textTheme, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarTitle(
    BuildContext context,
    String? entityIconUrl,
    IconData? appBarIconData,
    ColorScheme colorScheme,
    String appBarTitleText,
    TextTheme textTheme,
  ) {
    return Row(
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
  }

  Widget _buildFollowButton(
    BuildContext context,
    EntityDetailsState state,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return IconButton(
      icon: _isFollowingInProgress
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              state.isFollowing ? Icons.check_circle : Icons.add_circle_outline,
              color: colorScheme.primary,
            ),
      tooltip: state.isFollowing
          ? l10n.unfollowButtonLabel
          : l10n.followButtonLabel,
      onPressed: _isFollowingInProgress
          ? null
          : () async {
              setState(() => _isFollowingInProgress = true);
              try {
                if (state.isFollowing) {
                  context.read<EntityDetailsBloc>().add(
                    const EntityDetailsToggleFollowRequested(),
                  );
                  return;
                }

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

                if (action == null) return;

                final status = await limitationService.checkAction(action);

                if (status != LimitationStatus.allowed) {
                  if (!mounted) return;
                  showContentLimitationBottomSheet(
                    context: context,
                    status: status,
                    action: action,
                  );
                  return;
                }

                context.read<EntityDetailsBloc>().add(
                  const EntityDetailsToggleFollowRequested(),
                );
                context.read<AppBloc>().add(
                  AppPositiveInteractionOcurred(context: context),
                );
              } on ForbiddenException catch (e) {
                if (!mounted) return;
                await showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => ContentLimitationBottomSheet(
                    title: l10n.limitReachedTitle,
                    body: e.message,
                    buttonText: l10n.gotItButton,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() => _isFollowingInProgress = false);
                }
              }
            },
    );
  }

  Widget _buildReportPopupMenu(BuildContext context, AppLocalizations l10n) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'report') {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => ReportContentBottomSheet(
              entityId: widget.args.entityId,
              reportableEntity: ReportableEntity.source,
            ),
          );
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'report',
          child: Text(l10n.reportActionLabel),
        ),
      ],
    );
  }

  Widget _buildFeedContent(
    BuildContext context,
    EntityDetailsState state,
    AppLocalizations l10n,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    if (state.feedItems.isEmpty &&
        state.status != EntityDetailsStatus.initial &&
        state.status != EntityDetailsStatus.loadingMore &&
        state.status == EntityDetailsStatus.success) {
      return SliverFillRemaining(
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
      );
    }

    return SliverPadding(
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
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final item = state.feedItems[index];

          if (item is Headline) {
            final imageStyle = context.read<AppBloc>().state.feedItemImageStyle;
            Widget tile;
            switch (imageStyle) {
              case FeedItemImageStyle.hidden:
                tile = HeadlineTileTextOnly(
                  headline: item,
                  onHeadlineTap: () =>
                      HeadlineTapHandler.handleHeadlineTap(context, item),
                );
              case FeedItemImageStyle.smallThumbnail:
                tile = HeadlineTileImageStart(
                  headline: item,
                  onHeadlineTap: () =>
                      HeadlineTapHandler.handleHeadlineTap(context, item),
                );
              case FeedItemImageStyle.largeThumbnail:
                tile = HeadlineTileImageTop(
                  headline: item,
                  onHeadlineTap: () =>
                      HeadlineTapHandler.handleHeadlineTap(context, item),
                );
            }
            return tile;
          } else if (item is AdPlaceholder) {
            final remoteConfig = context.read<AppBloc>().state.remoteConfig;
            if (remoteConfig?.features.ads == null) {
              return const SizedBox.shrink();
            }
            return FeedAdLoaderWidget(
              contextKey: widget.args.entityId,
              adPlaceholder: item,
              adThemeStyle: AdThemeStyle.fromTheme(Theme.of(context)),
              remoteConfig: remoteConfig!,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
