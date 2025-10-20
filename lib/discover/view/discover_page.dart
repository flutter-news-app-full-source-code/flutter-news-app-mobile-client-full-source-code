import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/discover/bloc/discover_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/discover/widgets/discover_sliver_app_bar.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template discover_page}
/// A page that allows users to discover and browse news sources by category.
/// {@endtemplate}
class DiscoverPage extends StatelessWidget {
  /// {@macro discover_page}
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the DiscoverBloc to the widget tree.
    return BlocProvider(
      create: (context) => DiscoverBloc(
        sourcesRepository: context.read<DataRepository<Source>>(),
        logger: context.read<Logger>(),
      ),
      child: const _DiscoverView(),
    );
  }
}

/// The main view for the DiscoverPage.
class _DiscoverView extends StatefulWidget {
  const _DiscoverView();

  @override
  State<_DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<_DiscoverView> {
  @override
  void initState() {
    super.initState();
    // Trigger the initial data fetch when the widget is first created.
    context.read<DiscoverBloc>().add(DiscoverStarted());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // The consistent, searchable app bar.
          const DiscoverSliverAppBar(),
          // The main content area, built based on the DiscoverBloc's state.
          BlocBuilder<DiscoverBloc, DiscoverState>(
            builder: (context, state) {
              if (state.status == DiscoverStatus.loading) {
                return SliverFillRemaining(
                  child: LoadingStateWidget(
                    icon: Icons.explore_outlined,
                    headline: l10n.discoverPageTitle,
                    subheadline: l10n.pleaseWait,
                  ),
                );
              }

              if (state.status == DiscoverStatus.failure) {
                return SliverFillRemaining(
                  child: FailureStateWidget(
                    exception: state.error! as HttpException,
                    onRetry: () =>
                        context.read<DiscoverBloc>().add(DiscoverStarted()),
                  ),
                );
              }

              if (state.status == DiscoverStatus.success &&
                  state.groupedSources.isEmpty) {
                return SliverFillRemaining(
                  child: InitialStateWidget(
                    icon: Icons.explore_off_outlined,
                    headline: l10n.sourceFilterEmptyHeadline,
                    subheadline: l10n.sourceFilterEmptySubheadline,
                  ),
                );
              }

              // Build a list of category rows from the grouped sources.
              return SliverList.builder(
                itemCount: state.groupedSources.length,
                itemBuilder: (context, index) {
                  final sourceType = state.groupedSources.keys.elementAt(index);
                  final sources = state.groupedSources[sourceType]!;
                  return _SourceCategoryRow(
                    sourceType: sourceType,
                    sources: sources,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A widget that displays a single category of sources as a horizontal row.
class _SourceCategoryRow extends StatelessWidget {
  const _SourceCategoryRow({required this.sourceType, required this.sources});

  final SourceType sourceType;
  final List<Source> sources;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category title and "See all" button.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sourceType.name.toTitleCase(),
                  style: theme.textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    context.pushNamed(
                      Routes.sourceListName,
                      pathParameters: {'sourceType': sourceType.name},
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.seeAllButtonLabel),
                      const Icon(Icons.chevron_right, size: AppSpacing.lg),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Horizontally scrolling list of source cards.
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sources.length,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemBuilder: (context, index) {
                return _SourceCard(source: sources[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays a single source as a tappable card.
class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source});

  final Source source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 120,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.pushNamed(
            Routes.entityDetailsName,
            pathParameters: {'type': ContentType.source.name, 'id': source.id},
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.source_outlined, size: AppSpacing.xxl),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  source.name,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
