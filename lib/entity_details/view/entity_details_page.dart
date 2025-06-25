import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/entity_details/bloc/entity_details_bloc.dart';
import 'package:ht_main/entity_details/models/entity_type.dart';
import 'package:ht_main/l10n/app_localizations.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';
import 'package:ht_main/shared/services/feed_injector_service.dart';
import 'package:ht_main/shared/widgets/widgets.dart';
import 'package:ht_shared/ht_shared.dart';

class EntityDetailsPageArguments {
  const EntityDetailsPageArguments({
    this.entityId,
    this.entityType,
    this.entity,
  }) : assert(
         (entityId != null && entityType != null) || entity != null,
         'Either entityId/entityType or entity must be provided.',
       );

  final String? entityId;
  final EntityType? entityType;
  final dynamic entity;
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
    return BlocProvider<EntityDetailsBloc>(
      // Explicitly type BlocProvider
      create: (context) {
        final feedInjectorService = FeedInjectorService();
        final entityDetailsBloc = EntityDetailsBloc(
          headlinesRepository: context.read<HtDataRepository<Headline>>(),
          categoryRepository: context.read<HtDataRepository<Category>>(),
          sourceRepository: context.read<HtDataRepository<Source>>(),
          accountBloc: context.read<AccountBloc>(),
          appBloc: context.read<AppBloc>(),
          feedInjectorService: feedInjectorService,
        )
        ..add(
          EntityDetailsLoadRequested(
            entityId: args.entityId,
            entityType: args.entityType,
            entity: args.entity,
          ),
        );
        return entityDetailsBloc;
      },
      child: EntityDetailsView(args: args),
    );
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
        const EntityDetailsLoadMoreHeadlinesRequested(),
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

  String _getEntityTypeDisplayName(EntityType? type, AppLocalizations l10n) {
    if (type == null) return l10n.detailsPageTitle;
    String name;
    switch (type) {
      case EntityType.category:
        name = l10n.entityDetailsCategoryTitle;
      case EntityType.source:
        name = l10n.entityDetailsSourceTitle;
      }
    // Manual capitalization
    return name.isNotEmpty
        ? '${name[0].toUpperCase()}${name.substring(1)}'
        : name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: BlocBuilder<EntityDetailsBloc, EntityDetailsState>(
        builder: (context, state) {
          final entityTypeDisplayNameForTitle = _getEntityTypeDisplayName(
            widget.args.entityType,
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
              //TODO(fulleni): add entityDetailsErrorLoadingto l10n
              // message: state.errorMessage ?? l10n.entityDetailsErrorLoading(entityType: entityTypeDisplayNameForTitle),
              message: state.errorMessage ?? '...',
              onRetry: () => context.read<EntityDetailsBloc>().add(
                EntityDetailsLoadRequested(
                  entityId: widget.args.entityId,
                  entityType: widget.args.entityType,
                  entity: widget.args.entity,
                ),
              ),
            );
          }

          final String appBarTitleText;
          IconData? appBarIconData;
          // String? entityImageHeroTag;

          if (state.entity is Category) {
            final cat = state.entity as Category;
            appBarTitleText = cat.name;
            appBarIconData = Icons.category_outlined;
            // entityImageHeroTag = 'category-image-${cat.id}';
          } else if (state.entity is Source) {
            final src = state.entity as Source;
            appBarTitleText = src.name;
            appBarIconData = Icons.source_outlined;
          } else {
            appBarTitleText = l10n.detailsPageTitle;
          }

          final description = state.entity is Category
              ? (state.entity as Category).description
              : state.entity is Source
              ? (state.entity as Source).description
              : null;

          final entityIconUrl =
              (state.entity is Category &&
                  (state.entity as Category).iconUrl != null)
              ? (state.entity as Category).iconUrl
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
                        state.headlinesStatus ==
                            EntityHeadlinesStatus.loadingMore) ...[
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
                  state.headlinesStatus != EntityHeadlinesStatus.initial &&
                  state.headlinesStatus != EntityHeadlinesStatus.loadingMore &&
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
                    itemCount:
                        state.feedItems.length +
                        (state.hasMoreHeadlines &&
                                state.headlinesStatus ==
                                    EntityHeadlinesStatus.loadingMore
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
                              currentContextEntityType: state.entityType,
                              currentContextEntityId: state.entity is Category
                                  ? (state.entity as Category).id
                                  : state.entity is Source
                                  ? (state.entity as Source).id
                                  : null,
                            );
                          case HeadlineImageStyle.smallThumbnail:
                            tile = HeadlineTileImageStart(
                              headline: item,
                              onHeadlineTap: () => context.pushNamed(
                                Routes.globalArticleDetailsName,
                                pathParameters: {'id': item.id},
                                extra: item,
                              ),
                              currentContextEntityType: state.entityType,
                              currentContextEntityId: state.entity is Category
                                  ? (state.entity as Category).id
                                  : state.entity is Source
                                  ? (state.entity as Source).id
                                  : null,
                            );
                          case HeadlineImageStyle.largeThumbnail:
                            tile = HeadlineTileImageTop(
                              headline: item,
                              onHeadlineTap: () => context.pushNamed(
                                Routes.globalArticleDetailsName,
                                pathParameters: {'id': item.id},
                                extra: item,
                              ),
                              currentContextEntityType: state.entityType,
                              currentContextEntityId: state.entity is Category
                                  ? (state.entity as Category).id
                                  : state.entity is Source
                                  ? (state.entity as Source).id
                                  : null,
                            );
                        }
                        return tile;
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              if (state.headlinesStatus == EntityHeadlinesStatus.failure &&
                  state.feedItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.paddingMedium),
                    child: Text(
                      state.errorMessage ?? l10n.failedToLoadMoreHeadlines,
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
