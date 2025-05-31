import 'package:flutter/foundation.dart' show kIsWeb; // Added
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // Added
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/app/bloc/app_bloc.dart'; // For accessing settings
import 'package:ht_main/entity_details/bloc/entity_details_bloc.dart';
import 'package:ht_main/entity_details/models/entity_type.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart'; // Added
import 'package:ht_main/shared/constants/app_spacing.dart';
import 'package:ht_main/shared/widgets/widgets.dart';
import 'package:ht_shared/ht_shared.dart';
import 'package:ht_data_repository/ht_data_repository.dart'; // For repository provider

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
  final dynamic entity; // Category or Source
}

class EntityDetailsPage extends StatelessWidget {
  const EntityDetailsPage({super.key, required this.args});

  final EntityDetailsPageArguments args;

  static Route<void> route({required EntityDetailsPageArguments args}) {
    return MaterialPageRoute<void>(
      builder: (_) => EntityDetailsPage(args: args),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EntityDetailsBloc(
        headlinesRepository: context.read<HtDataRepository<Headline>>(),
        categoryRepository: context.read<HtDataRepository<Category>>(),
        sourceRepository: context.read<HtDataRepository<Source>>(),
        accountBloc: context.read<AccountBloc>(),
      )..add(
          EntityDetailsLoadRequested(
            entityId: args.entityId,
            entityType: args.entityType,
            entity: args.entity,
          ),
        ),
      child: EntityDetailsView(args: args), // Pass args
    );
  }
}

class EntityDetailsView extends StatefulWidget {
  const EntityDetailsView({super.key, required this.args}); // Accept args

  final EntityDetailsPageArguments args; // Store args

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
      context
          .read<EntityDetailsBloc>()
          .add(const EntityDetailsLoadMoreHeadlinesRequested());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Trigger load a bit before reaching the absolute bottom
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<EntityDetailsBloc, EntityDetailsState>(
        builder: (context, state) {
          if (state.status == EntityDetailsStatus.initial ||
              (state.status == EntityDetailsStatus.loading &&
                  state.entity == null)) {
            return const LoadingStateWidget(
              icon: Icons.info_outline, // Or a more specific icon
              headline: 'Loading Details', // Replace with l10n
              subheadline: 'Please wait...', // Replace with l10n
            );
          }

          if (state.status == EntityDetailsStatus.failure &&
              state.entity == null) {
            return FailureStateWidget(
              message: state.errorMessage ?? 'Failed to load details.', // l10n
              onRetry: () => context.read<EntityDetailsBloc>().add(
                    EntityDetailsLoadRequested(
                      entityId: widget.args.entityId,
                      entityType: widget.args.entityType,
                      entity: widget.args.entity,
                    ),
                  ),
            );
          }

          // At this point, state.entity should not be null if success or loading more
          final String appBarTitle = state.entity is Category
              ? (state.entity as Category).name
              : state.entity is Source
                  ? (state.entity as Source).name
                  : l10n.detailsPageTitle; 

          final String? description = state.entity is Category
              ? (state.entity as Category).description
              : state.entity is Source
                  ? (state.entity as Source).description
                  : null;
          
          final String? entityIconUrl = (state.entity is Category &&
                  (state.entity as Category).iconUrl != null)
              ? (state.entity as Category).iconUrl
              : null;

          final followButton = IconButton(
            icon: Icon(
              state.isFollowing
                  ? Icons.check_circle // Filled when following
                  : Icons.add_circle_outline,
              color: theme.colorScheme.primary, // Use primary for both states for accent
            ),
            tooltip: state.isFollowing
                ? l10n.unfollowButtonLabel
                : l10n.followButtonLabel,
            onPressed: () {
              context
                  .read<EntityDetailsBloc>()
                  .add(const EntityDetailsToggleFollowRequested());
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
                      width: kToolbarHeight - 16, // AppBar height minus padding
                      height: kToolbarHeight - 16,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.category_outlined, size: kToolbarHeight - 20),
                    ),
                  ),
                )
              else if (state.entityType == EntityType.category)
                 Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Icon(Icons.category_outlined, size: kToolbarHeight - 20, color: theme.colorScheme.onSurface),
                )
              else if (state.entityType == EntityType.source)
                 Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Icon(Icons.source_outlined, size: kToolbarHeight - 20, color: theme.colorScheme.onSurface),
                ),
              Flexible(
                child: Text(
                  appBarTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Info icon removed from here
            ],
          );

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                title: appBarTitleWidget,
                pinned: true,
                actions: [followButton],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.paddingMedium), // Consistent padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (description != null && description.isNotEmpty) ...[
                        Text(
                          description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (state.headlines.isNotEmpty ||
                          state.headlinesStatus == EntityHeadlinesStatus.loadingMore) ...[
                        Text(l10n.headlinesSectionTitle, style: theme.textTheme.titleLarge),
                        const Divider(height: AppSpacing.md),
                      ]
                    ],
                  ),
                ),
              ),
              if (state.headlines.isEmpty &&
                  state.headlinesStatus != EntityHeadlinesStatus.initial &&
                  state.headlinesStatus != EntityHeadlinesStatus.loadingMore &&
                  state.status == EntityDetailsStatus.success)
                SliverFillRemaining( // Use SliverFillRemaining for empty state
                  child: Center(
                    child: Text(
                      l10n.noHeadlinesFoundMessage,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= state.headlines.length) {
                        return state.hasMoreHeadlines && state.headlinesStatus == EntityHeadlinesStatus.loadingMore
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink(); 
                      }
                      final headline = state.headlines[index];
                      final imageStyle = context.watch<AppBloc>().state.settings.feedPreferences.headlineImageStyle;
                      
                      Widget tile;
                      switch (imageStyle) {
                        case HeadlineImageStyle.hidden:
                          tile = HeadlineTileTextOnly(
                            headline: headline,
                            onHeadlineTap: () => context.pushNamed(
                              Routes.globalArticleDetailsName, // Use new global route
                              pathParameters: {'id': headline.id},
                              extra: headline,
                            ),
                            currentContextEntityType: state.entityType,
                            currentContextEntityId: state.entity is Category
                                ? (state.entity as Category).id
                                : state.entity is Source
                                    ? (state.entity as Source).id
                                    : null,
                          );
                          break;
                        case HeadlineImageStyle.smallThumbnail:
                          tile = HeadlineTileImageStart(
                            headline: headline,
                            onHeadlineTap: () => context.pushNamed(
                              Routes.globalArticleDetailsName, // Use new global route
                              pathParameters: {'id': headline.id},
                              extra: headline,
                            ),
                            currentContextEntityType: state.entityType,
                            currentContextEntityId: state.entity is Category
                                ? (state.entity as Category).id
                                : state.entity is Source
                                    ? (state.entity as Source).id
                                    : null,
                          );
                          break;
                        case HeadlineImageStyle.largeThumbnail:
                          tile = HeadlineTileImageTop(
                            headline: headline,
                            onHeadlineTap: () => context.pushNamed(
                              Routes.globalArticleDetailsName, // Use new global route
                              pathParameters: {'id': headline.id},
                              extra: headline,
                            ),
                            currentContextEntityType: state.entityType,
                            currentContextEntityId: state.entity is Category
                                ? (state.entity as Category).id
                                : state.entity is Source
                                    ? (state.entity as Source).id
                                    : null,
                          );
                          break;
                      }
                      return tile;
                    },
                    childCount: state.headlines.length + (state.hasMoreHeadlines && state.headlinesStatus == EntityHeadlinesStatus.loadingMore ? 1 : 0),
                  ),
                ),
                // Error display for headline loading specifically
                if (state.headlinesStatus == EntityHeadlinesStatus.failure && state.headlines.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        state.errorMessage ?? l10n.failedToLoadMoreHeadlines,
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
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
