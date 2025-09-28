//
// ignore_for_file: avoid_redundant_argument_values

import 'package:core/core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/widgets/in_article_ad_loader_widget.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
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
          body: BlocListener<AppBloc, AppState>(
            listenWhen: (previous, current) {
              final detailsState = context.read<HeadlineDetailsBloc>().state;
              if (detailsState is HeadlineDetailsLoaded) {
                final currentHeadlineId = detailsState.headline.id;
                final wasPreviouslySaved =
                    previous.userContentPreferences?.savedHeadlines.any(
                      (h) => h.id == currentHeadlineId,
                    ) ??
                    false;
                final isCurrentlySaved =
                    current.userContentPreferences?.savedHeadlines.any(
                      (h) => h.id == currentHeadlineId,
                    ) ??
                    false;

                // Listen for changes in saved status or errors during persistence
                return (wasPreviouslySaved != isCurrentlySaved) ||
                    (current.initialUserPreferencesError != null &&
                        previous.initialUserPreferencesError == null);
              }
              return false;
            },
            listener: (context, appState) {
              final detailsState = context.read<HeadlineDetailsBloc>().state;
              if (detailsState is HeadlineDetailsLoaded) {
                if (appState.initialUserPreferencesError != null) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(l10n.headlineSaveErrorSnackbar),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                } else {
                  final nowIsSaved =
                      appState.userContentPreferences?.savedHeadlines.any(
                        (h) => h.id == detailsState.headline.id,
                      ) ??
                      false;
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

    final appBlocState = context.watch<AppBloc>().state;
    final isSaved =
        appBlocState.userContentPreferences?.savedHeadlines.any(
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
        final currentPreferences = appBlocState.userContentPreferences;
        if (currentPreferences == null) {
          // Handle case where preferences are not loaded (e.g., show error)
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(l10n.headlineSaveErrorSnackbar),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          return;
        }

        final List<Headline> updatedSavedHeadlines;
        if (isSaved) {
          updatedSavedHeadlines = currentPreferences.savedHeadlines
              .where((h) => h.id != headline.id)
              .toList();
        } else {
          updatedSavedHeadlines = List.from(currentPreferences.savedHeadlines)
            ..add(headline);
        }

        final updatedPreferences = currentPreferences.copyWith(
          savedHeadlines: updatedSavedHeadlines,
        );

        context.read<AppBloc>().add(
          AppUserContentPreferencesChanged(preferences: updatedPreferences),
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

    final adConfig = appBlocState.remoteConfig?.adConfig;
    final adThemeStyle = AdThemeStyle.fromTheme(Theme.of(context));
    final userRole = appBlocState.user?.appRole ?? AppUserRole.guestUser;

    Future<void> onEntityChipTap(ContentType type, String id) async {
      // Await for the ad to be shown and dismissed.
      await context.read<InterstitialAdManager>().onPotentialAdTrigger();

      // Check if the widget is still in the tree before navigating.
      if (!context.mounted) return;

      // Proceed with navigation after the ad is closed.
      await context.pushNamed(
        Routes.entityDetailsName,
        pathParameters: {'type': type.name, 'id': id},
      );
    }

    final slivers = <Widget>[
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
            children: _buildMetadataChips(context, headline, onEntityChipTap),
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
    ];

    // Add ad above continue reading button if configured
    final isAboveButtonAdVisible =
        adConfig != null &&
        adConfig.enabled &&
        adConfig.articleAdConfiguration.enabled &&
        (adConfig
                .articleAdConfiguration
                .visibleTo[userRole]?[InArticleAdSlotType
                .aboveArticleContinueReadingButton] ??
            false);

    if (isAboveButtonAdVisible) {
      slivers.add(
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: horizontalPadding,
                child: InArticleAdLoaderWidget(
                  slotType:
                      InArticleAdSlotType.aboveArticleContinueReadingButton,
                  adThemeStyle: adThemeStyle,
                  adConfig: adConfig,
                ),
              ),
            ],
          ),
        ),
      );
    }

    slivers.addAll([
      if (headline.url.isNotEmpty)
        SliverPadding(
          padding: horizontalPadding,
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
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
              ],
            ),
          ),
        ),
      if (headline.url.isEmpty)
        const SliverToBoxAdapter(child: SizedBox.shrink()),
    ]);

    // Add ad below continue reading button if configured
    final isBelowButtonAdVisible =
        adConfig != null &&
        adConfig.enabled &&
        adConfig.articleAdConfiguration.enabled &&
        (adConfig
                .articleAdConfiguration
                .visibleTo[userRole]?[InArticleAdSlotType
                .belowArticleContinueReadingButton] ??
            false);

    if (isBelowButtonAdVisible) {
      slivers.add(
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: horizontalPadding,
                child: InArticleAdLoaderWidget(
                  slotType:
                      InArticleAdSlotType.belowArticleContinueReadingButton,
                  adThemeStyle: adThemeStyle,
                  adConfig: adConfig,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Future<void> onSimilarHeadlineTap(Headline similarHeadline) async {
      // Await for the ad to be shown and dismissed.
      await context.read<InterstitialAdManager>().onPotentialAdTrigger();

      // Check if the widget is still in the tree before navigating.
      if (!context.mounted) return;

      // Proceed with navigation after the ad is closed.
      await context.pushNamed(
        Routes.globalArticleDetailsName,
        pathParameters: {'id': similarHeadline.id},
        extra: similarHeadline,
      );
    }

    slivers.add(
      BlocBuilder<SimilarHeadlinesBloc, SimilarHeadlinesState>(
        builder: (context, state) {
          if (state is SimilarHeadlinesLoaded &&
                  state.similarHeadlines.isEmpty ||
              state is SimilarHeadlinesEmpty) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }
          return SliverMainAxisGroup(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
              SliverPadding(
                padding: horizontalPadding,
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      l10n.similarHeadlinesSectionTitle,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              _buildSimilarHeadlinesSection(
                context,
                horizontalPadding,
                onSimilarHeadlineTap,
              ),
            ],
          );
        },
      ),
    );

    return CustomScrollView(slivers: slivers);
  }

  List<Widget> _buildMetadataChips(
    BuildContext context,
    Headline headline,
    void Function(ContentType type, String id) onEntityChipTap,
  ) {
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
          onTap: () => onEntityChipTap(ContentType.source, headline.source.id),
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
          onTap: () => onEntityChipTap(ContentType.topic, headline.topic.id),
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
      )
      ..add(
        InkWell(
          onTap: () =>
              onEntityChipTap(ContentType.country, headline.eventCountry.id),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Chip(
            avatar: Icon(
              Icons.location_city_outlined,
              size: chipAvatarSize,
              color: chipAvatarColor,
            ),
            label: Text(headline.eventCountry.name),
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
    void Function(Headline headline) onSimilarHeadlineTap,
  ) {
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
          SimilarHeadlinesEmpty() => const SliverToBoxAdapter(
            child: SizedBox.shrink(),
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
                        .headlineImageStyle;
                    Widget tile;
                    switch (imageStyle) {
                      case HeadlineImageStyle.hidden:
                        tile = HeadlineTileTextOnly(
                          headline: similarHeadline,
                          onHeadlineTap: () =>
                              onSimilarHeadlineTap(similarHeadline),
                        );
                      case HeadlineImageStyle.smallThumbnail:
                        tile = HeadlineTileImageStart(
                          headline: similarHeadline,
                          onHeadlineTap: () =>
                              onSimilarHeadlineTap(similarHeadline),
                        );
                      case HeadlineImageStyle.largeThumbnail:
                        tile = HeadlineTileImageTop(
                          headline: similarHeadline,
                          onHeadlineTap: () =>
                              onSimilarHeadlineTap(similarHeadline),
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
