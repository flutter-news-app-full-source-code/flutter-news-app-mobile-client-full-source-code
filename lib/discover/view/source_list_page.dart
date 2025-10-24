import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/discover/bloc/source_list_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/extensions/source_type_l10n_extensions.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template source_list_page}
/// A page that displays a full, paginated list of sources for a specific
/// [SourceType]. It supports filtering, infinite scrolling, and follow/unfollow
/// actions.
/// {@endtemplate}
class SourceListPage extends StatelessWidget {
  /// {@macro source_list_page}
  const SourceListPage({required this.sourceType, super.key});

  /// The type of source to display.
  final SourceType sourceType;

  @override
  Widget build(BuildContext context) {
    // Provide the SourceListBloc to the widget tree.
    return BlocProvider(
      create: (context) => SourceListBloc(
        sourcesRepository: context.read<DataRepository<Source>>(),
        countriesRepository: context.read<DataRepository<Country>>(),
        appBloc: context.read<AppBloc>(),
        contentLimitationService: context.read<ContentLimitationService>(),
        logger: context.read<Logger>(),
      )..add(SourceListStarted(sourceType: sourceType)),
      child: const _SourceListView(),
    );
  }
}

/// The main view for the SourceListPage.
class _SourceListView extends StatefulWidget {
  const _SourceListView();

  @override
  State<_SourceListView> createState() => _SourceListViewState();
}

class _SourceListViewState extends State<_SourceListView> {
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

  /// Handles scroll events to trigger pagination.
  void _onScroll() {
    final state = context.read<SourceListBloc>().state;
    if (_isBottom &&
        state.hasMore &&
        state.status != SourceListStatus.loadingMore) {
      context.read<SourceListBloc>().add(SourceListLoadMoreRequested());
    }
  }

  /// Checks if the user has scrolled to the bottom of the list.
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

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<SourceListBloc>().add(SourceListRefreshed());
        },
        child: BlocBuilder<SourceListBloc, SourceListState>(
          builder: (context, state) {
            if (state.status == SourceListStatus.loading &&
                state.sources.isEmpty) {
              return LoadingStateWidget(
                icon: Icons.source_outlined,
                headline: l10n.sourceFilterLoadingHeadline,
                subheadline: l10n.pleaseWait,
              );
            }

            if (state.status == SourceListStatus.failure &&
                state.sources.isEmpty) {
              return FailureStateWidget(
                exception: state.error!,
                onRetry: () => context.read<SourceListBloc>().add(
                  SourceListStarted(sourceType: state.sourceType!),
                ),
              );
            }

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  title: Text(
                    state.sourceType?.l10nPlural(l10n) ??
                        l10n.discoverPageTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  pinned: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      tooltip: l10n.sourceListFilterPageFilterButtonTooltip,
                      onPressed: () {
                        final bloc = context.read<SourceListBloc>();
                        context.pushNamed(
                          Routes.discoverSourceListFilterName,
                          pathParameters: {
                            'sourceType': bloc.state.sourceType!.name,
                          },
                          extra: bloc,
                        );
                      },
                    ),
                  ],
                ),
                if (state.sources.isEmpty)
                  SliverFillRemaining(
                    child: InitialStateWidget(
                      icon: Icons.search_off,
                      headline: l10n.sourceFilterEmptyHeadline,
                      subheadline: l10n.sourceFilterEmptySubheadline,
                    ),
                  )
                else
                  SliverList.separated(
                    itemCount: state.hasMore
                        ? state.sources.length + 1
                        : state.sources.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index >= state.sources.length) {
                        return state.status == SourceListStatus.loadingMore
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.lg),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      final source = state.sources[index];
                      return _SourceListTile(source: source);
                    },
                  ),
                if (state.status == SourceListStatus.partialFailure)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        l10n.failedToLoadMoreHeadlines,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A list tile widget for displaying a single source.
class _SourceListTile extends StatelessWidget {
  const _SourceListTile({required this.source});

  final Source source;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    // Listen to the AppBloc to get the user's followed sources.
    // This ensures the follow/unfollow button state is always in sync with
    // the single source of truth.
    final isFollowing = context.select(
      (AppBloc bloc) =>
          bloc.state.userContentPreferences?.followedSources.any(
            (s) => s.id == source.id,
          ) ??
          false,
    );

    return ListTile(
      leading: SizedBox(
        width: 40,
        height: 40,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Image.network(
            source.logoUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.source_outlined),
          ),
        ),
      ),
      title: Text(
        source.name,
        style: theme.textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: isFollowing
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : const Icon(Icons.add_circle_outline),
        tooltip: isFollowing
            ? l10n.unfollowSourceTooltip(source.name)
            : l10n.followSourceTooltip(source.name),
        onPressed: () {
          // If the user is unfollowing, always allow it.
          if (isFollowing) {
            context.read<SourceListBloc>().add(
              SourceListFollowToggled(source: source),
            );
          } else {
            // If the user is following, check the limit first.
            final limitationService = context.read<ContentLimitationService>();
            final status = limitationService.checkAction(
              ContentAction.followSource,
            );

            if (status == LimitationStatus.allowed) {
              context.read<SourceListBloc>().add(
                SourceListFollowToggled(source: source),
              );
            } else {
              // If the limit is reached, show the informative bottom sheet.
              showModalBottomSheet<void>(
                context: context,
                builder: (_) => ContentLimitationBottomSheet(status: status),
              );
            }
          }
        },
      ),
      onTap: () => context.pushNamed(
        Routes.entityDetailsName,
        pathParameters: {'type': ContentType.source.name, 'id': source.id},
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
    );
  }
}
