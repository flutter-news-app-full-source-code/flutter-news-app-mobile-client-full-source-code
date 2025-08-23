//
// ignore_for_file: avoid_redundant_argument_values

import 'package:core/core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/account_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/entity_details/view/entity_details_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headline-details/bloc/headline_details_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headline-details/bloc/similar_headlines_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_core/feed_core.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HeadlineDetailsPage extends StatefulWidget {
  const HeadlineDetailsPage({super.key, this.headlineId, this.initialHeadline})
    : assert(headlineId != null || initialHeadline != null);

  final String? headlineId;
  final Headline? initialHeadline;

  @override
  State<HeadlineDetailsPage> createState() => _HeadlineDetailsPageState();
}

class _HeadlineDetailsPageState extends State<HeadlineDetailsPage> {
  @override
  void initState() {
    super.initState();
    if (widget.initialHeadline != null) {
      context.read<HeadlineDetailsBloc>().add(
        HeadlineProvided(widget.initialHeadline!),
      );
      context.read<SimilarHeadlinesBloc>().add(
        FetchSimilarHeadlines(currentHeadline: widget.initialHeadline!),
      );
    } else if (widget.headlineId != null) {
      context.read<HeadlineDetailsBloc>().add(
        FetchHeadlineById(widget.headlineId!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    return BlocListener<HeadlineDetailsBloc, HeadlineDetailsState>(
      listener: (context, headlineState) {
        if (headlineState is HeadlineDetailsLoaded) {
          if (widget.initialHeadline == null) {
            context.read<SimilarHeadlinesBloc>().add(
              FetchSimilarHeadlines(currentHeadline: headlineState.headline),
            );
          }
        }
      },
      child: SafeArea(
        child: Scaffold(
          body: BlocListener<AccountBloc, AccountState>(
            listenWhen: (previous, current) {
              final detailsState = context.read<HeadlineDetailsBloc>().state;
              if (detailsState is HeadlineDetailsLoaded) {
                final currentHeadlineId = detailsState.headline.id;
                final wasPreviouslySaved =
                    previous.preferences?.savedHeadlines.any(
                      (h) => h.id == currentHeadlineId,
                    ) ??
                    false;
                final isCurrentlySaved =
                    current.preferences?.savedHeadlines.any(
                      (h) => h.id == currentHeadlineId,
                    ) ??
                    false;
                if (wasPreviouslySaved != isCurrentlySaved) {
                  return current.status == AccountStatus.success ||
                      current.status == AccountStatus.failure;
                }
                if (current.status == AccountStatus.failure &&
                    previous.status == AccountStatus.loading) {
                  return true;
                }
              }
              return false;
            },
            listener: (context, accountState) {
              final detailsState = context.read<HeadlineDetailsBloc>().state;
              if (detailsState is HeadlineDetailsLoaded) {
                final nowIsSaved =
                    accountState.preferences?.savedHeadlines.any(
                      (h) => h.id == detailsState.headline.id,
                    ) ??
                    false;
                if (accountState.status == AccountStatus.failure &&
                    accountState.error != null) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(l10n.headlineSaveErrorSnackbar),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                } else {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          nowIsSaved
                              ? l10n.headlineSavedSuccessSnackbar
                              : l10n.headlineUnsavedSuccessSnackbar,
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                }
              }
            },
            child: BlocBuilder<HeadlineDetailsBloc, HeadlineDetailsState>(
              builder: (context, state) {
                return switch (state) {
                  HeadlineDetailsInitial() ||
                  HeadlineDetailsLoading() => LoadingStateWidget(
                    icon: Icons.article_outlined,
                    headline: l10n.headlineDetailsLoadingHeadline,
                    subheadline: l10n.headlineDetailsLoadingSubheadline,
                  ),
                  final HeadlineDetailsFailure failureState =>
                    FailureStateWidget(
                      exception: failureState.exception,
                      onRetry: () {
                        if (widget.headlineId != null) {
                          context.read<HeadlineDetailsBloc>().add(
                            FetchHeadlineById(widget.headlineId!),
                          );
                        }
                      },
                    ),
                  final HeadlineDetailsLoaded loadedState =>
                    _buildLoadedContent(context, loadedState.headline),
                  _ => Center(
                    child: Text(
                      l10n.unknownError,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                };
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, Headline headline) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    const horizontalPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.paddingLarge,
    );

    final accountState = context.watch<AccountBloc>().state;
    final isSaved =
        accountState.preferences?.savedHeadlines.any(
          (h) => h.id == headline.id,
        ) ??
        false;

    final bookmarkButton = IconButton(
      icon: Icon(
        isSaved ? Icons.bookmark : Icons.bookmark_border_outlined,
        color: colorScheme.primary,
      ),
      tooltip: isSaved
          ? l10n.headlineDetailsRemoveFromSavedTooltip
          : l10n.headlineDetailsSaveTooltip,
      onPressed: () {
        context.read<AccountBloc>().add(
          AccountSaveHeadlineToggled(headline: headline),
        );
      },
    );

    final Widget shareButtonWidget = Builder(
      builder: (BuildContext buttonContext) {
        return IconButton(
          icon: Icon(Icons.share_outlined, color: colorScheme.primary),
          tooltip: l10n.shareActionTooltip,
          onPressed: () async {
            final box = buttonContext.findRenderObject() as RenderBox?;
            Rect? sharePositionOrigin;
            if (box != null) {
              sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
            }
            ShareParams params;
            if (kIsWeb && headline.url.isNotEmpty) {
              params = ShareParams(
                uri: Uri.parse(headline.url),
                title: headline.title,
                sharePositionOrigin: sharePositionOrigin,
              );
            } else if (headline.url.isNotEmpty) {
              params = ShareParams(
                text: '${headline.title}\n\n${headline.url}',
                subject: headline.title,
                sharePositionOrigin: sharePositionOrigin,
              );
            } else {
              params = ShareParams(
                text: headline.title,
                subject: headline.title,
                sharePositionOrigin: sharePositionOrigin,
              );
            }
            final shareResult = await SharePlus.instance.share(params);
            if (buttonContext.mounted) {
              if (shareResult.status == ShareResultStatus.unavailable) {
                ScaffoldMessenger.of(buttonContext).showSnackBar(
                  SnackBar(content: Text(l10n.sharingUnavailableSnackbar)),
                );
              }
            }
          },
        );
      },
    );

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => context.pop(),
            color: colorScheme.onSurface,
          ),
          actions: [
            bookmarkButton,
            shareButtonWidget,
            const SizedBox(width: AppSpacing.sm),
          ],
          pinned: false,
          floating: true,
          snap: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: colorScheme.onSurface,
        ),
        SliverPadding(
          padding: horizontalPadding.copyWith(top: AppSpacing.sm),
          sliver: SliverToBoxAdapter(
            child: Text(
              headline.title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            top: AppSpacing.md,
            left: horizontalPadding.left,
            right: horizontalPadding.right,
          ),
          sliver: SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  headline.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return ColoredBox(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: AppSpacing.xxl * 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: horizontalPadding.copyWith(top: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: _buildMetadataChips(context, headline),
            ),
          ),
        ),
        if (headline.excerpt.isNotEmpty)
          SliverPadding(
            padding: horizontalPadding.copyWith(top: AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Text(
                headline.excerpt,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ),
          ),
        if (headline.url.isNotEmpty)
          SliverPadding(
            padding: horizontalPadding.copyWith(
              top: AppSpacing.xl,
              bottom: AppSpacing.xl,
            ),
            sliver: SliverToBoxAdapter(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new_outlined),
                onPressed: () async {
                  await launchUrlString(headline.url);
                },
                label: Text(l10n.headlineDetailsContinueReadingButton),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  textStyle: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        if (headline.url.isEmpty) // Ensure bottom padding
          const SliverPadding(
            padding: EdgeInsets.only(bottom: AppSpacing.xl),
            sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        SliverPadding(
          padding: horizontalPadding,
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: (headline.url.isNotEmpty) ? AppSpacing.sm : AppSpacing.xl,
                bottom: AppSpacing.md,
              ),
              child: Text(
                l10n.similarHeadlinesSectionTitle,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        _buildSimilarHeadlinesSection(context, horizontalPadding),
      ],
    );
  }

  List<Widget> _buildMetadataChips(BuildContext context, Headline headline) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final chipLabelStyle = textTheme.labelMedium?.copyWith(
      color: colorScheme.onSecondaryContainer,
    );
    final chipBackgroundColor = colorScheme.secondaryContainer;
    final chipAvatarColor = colorScheme.onSecondaryContainer;
    const chipAvatarSize = AppSpacing.md;
    const chipPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    );
    final chipShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
    );

    final chips = <Widget>[];

    final formattedDate = DateFormat('MMM d, yyyy').format(headline.createdAt);
    chips
      ..add(
        Chip(
          avatar: Icon(
            Icons.calendar_today_outlined,
            size: chipAvatarSize,
            color: chipAvatarColor,
          ),
          label: Text(formattedDate),
          labelStyle: chipLabelStyle,
          backgroundColor: chipBackgroundColor,
          padding: chipPadding,
          shape: chipShape,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      )
      ..add(
        InkWell(
          onTap: () {
            context.push(
              Routes.sourceDetails,
              extra: EntityDetailsPageArguments(
                entityId: headline.id,
                contentType: ContentType.headline,
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Chip(
            avatar: Icon(
              Icons.source_outlined,
              size: chipAvatarSize,
              color: chipAvatarColor,
            ),
            label: Text(headline.source.name),
            labelStyle: chipLabelStyle,
            backgroundColor: chipBackgroundColor,
            padding: chipPadding,
            shape: chipShape,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      )
      ..add(
        InkWell(
          onTap: () {
            context.push(
              Routes.topicDetails,
              extra: EntityDetailsPageArguments(
                entityId: headline.topic.id,
                contentType: ContentType.topic,
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Chip(
            avatar: Icon(
              Icons.category_outlined,
              size: chipAvatarSize,
              color: chipAvatarColor,
            ),
            label: Text(headline.topic.name),
            labelStyle: chipLabelStyle,
            backgroundColor: chipBackgroundColor,
            padding: chipPadding,
            shape: chipShape,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );

    return chips;
  }

  Widget _buildSimilarHeadlinesSection(
    BuildContext context,
    EdgeInsets hPadding,
  ) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return BlocBuilder<SimilarHeadlinesBloc, SimilarHeadlinesState>(
      builder: (context, state) {
        return switch (state) {
          SimilarHeadlinesInitial() ||
          SimilarHeadlinesLoading() => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          final SimilarHeadlinesError errorState => SliverToBoxAdapter(
            child: Padding(
              padding: hPadding.copyWith(
                top: AppSpacing.md,
                bottom: AppSpacing.xl,
              ),
              child: Text(
                errorState.message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
              ),
            ),
          ),
          SimilarHeadlinesEmpty() => SliverToBoxAdapter(
            child: Padding(
              padding: hPadding.copyWith(
                top: AppSpacing.md,
                bottom: AppSpacing.xl,
              ),
              child: Text(
                l10n.similarHeadlinesEmpty,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          final SimilarHeadlinesLoaded loadedState => SliverPadding(
            padding: hPadding.copyWith(bottom: AppSpacing.xxl),
            sliver: SliverList.separated(
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemCount: loadedState.similarHeadlines.length,
              itemBuilder: (context, index) {
                // Corrected: SliverList.separated uses itemBuilder
                final similarHeadline = loadedState.similarHeadlines[index];
                return Builder(
                  builder: (context) {
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
                          headline: similarHeadline,
                          onHeadlineTap: () => context.pushNamed(
                            Routes.globalArticleDetailsName,
                            pathParameters: {'id': similarHeadline.id},
                            extra: similarHeadline,
                          ),
                        );
                      case HeadlineImageStyle.smallThumbnail:
                        tile = HeadlineTileImageStart(
                          headline: similarHeadline,
                          onHeadlineTap: () => context.pushNamed(
                            Routes.globalArticleDetailsName,
                            pathParameters: {'id': similarHeadline.id},
                            extra: similarHeadline,
                          ),
                        );
                      case HeadlineImageStyle.largeThumbnail:
                        tile = HeadlineTileImageTop(
                          headline: similarHeadline,
                          onHeadlineTap: () => context.pushNamed(
                            Routes.globalArticleDetailsName,
                            pathParameters: {'id': similarHeadline.id},
                            extra: similarHeadline,
                          ),
                        );
                    }
                    return tile;
                  },
                );
              },
            ),
          ),
          _ => const SliverToBoxAdapter(child: SizedBox.shrink()),
        };
      },
    );
  }
}
