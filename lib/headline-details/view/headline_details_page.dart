//
// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/app/bloc/app_bloc.dart'; // Added AppBloc
import 'package:ht_main/headline-details/bloc/headline_details_bloc.dart';
import 'package:ht_main/headline-details/bloc/similar_headlines_bloc.dart';
// HeadlineItemWidget import removed
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/shared.dart';
import 'package:ht_shared/ht_shared.dart'
    show Headline, HeadlineImageStyle; // Added HeadlineImageStyle
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart'; // Import share_plus
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
      // Also trigger fetching similar headlines if the main one is already provided
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
    final l10n = context.l10n;

    return BlocListener<HeadlineDetailsBloc, HeadlineDetailsState>(
      listener: (context, headlineState) {
        if (headlineState is HeadlineDetailsLoaded) {
          // Once the main headline is loaded (if fetched by ID),
          // fetch similar ones.
          // This check ensures it's not re-triggered if already loaded via initialHeadline.
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

                // Condition 1: Actual change in saved status for this headline
                if (wasPreviouslySaved != isCurrentlySaved) {
                  // Only trigger if the status is success (to show confirmation)
                  // or failure (to show error). Avoid triggering if status is just loading.
                  return current.status == AccountStatus.success ||
                      current.status == AccountStatus.failure;
                }

                // Condition 2: A specific save/unsave operation just failed
                // This triggers if an operation was attempted (loading) and then failed.
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
                    accountState.errorMessage != null) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          accountState.errorMessage ??
                              l10n.headlineSaveErrorSnackbar,
                        ),
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
                    icon: Icons.downloading,
                    headline: l10n.headlineDetailsLoadingHeadline,
                    subheadline: l10n.headlineDetailsLoadingSubheadline,
                  ),
                  final HeadlineDetailsFailure failureState =>
                    FailureStateWidget(
                      message: failureState.message,
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
                  _ => const Center(child: Text('Unknown state')),
                };
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, Headline headline) {
    final l10n = context.l10n;
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
      icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
      tooltip:
          isSaved
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
          icon: const Icon(Icons.share),
          tooltip: l10n.shareActionTooltip,
          onPressed: () async {
            final box = buttonContext.findRenderObject() as RenderBox?;
            Rect? sharePositionOrigin;
            if (box != null) {
              sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
            }

            ShareParams params;
            if (kIsWeb && headline.url != null && headline.url!.isNotEmpty) {
              params = ShareParams(
                uri: Uri.parse(headline.url!),
                title: headline.title,
                sharePositionOrigin: sharePositionOrigin,
              );
            } else if (headline.url != null && headline.url!.isNotEmpty) {
              params = ShareParams(
                text: '${headline.title}\n\n${headline.url!}',
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
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [bookmarkButton, shareButtonWidget],
          pinned: false,
          floating: true,
          snap: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: theme.colorScheme.onSurface,
        ),
        SliverPadding(
          padding: horizontalPadding.copyWith(top: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Text(headline.title, style: textTheme.headlineMedium),
          ),
        ),
        // Image or Placeholder Section
        SliverPadding(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            left: AppSpacing.paddingLarge,
            right: AppSpacing.paddingLarge,
          ),
          sliver: SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child:
                  headline.imageUrl != null
                      ? Image.network(
                        headline.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: double.infinity,
                            height: 200,
                            color: colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              width: double.infinity,
                              height: 200,
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: colorScheme.onSurfaceVariant,
                                size: AppSpacing.xxl,
                              ),
                            ),
                      )
                      : Container(
                        width: double.infinity,
                        height: 200,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: AppSpacing.xxl,
                        ),
                      ),
            ),
          ),
        ),
        SliverPadding(
          padding: horizontalPadding.copyWith(top: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _buildMetadataChips(context, headline),
            ),
          ),
        ),
        if (headline.description != null)
          SliverPadding(
            padding: horizontalPadding.copyWith(top: AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Text(headline.description!, style: textTheme.bodyLarge),
            ),
          ),
        if (headline.url != null)
          SliverPadding(
            padding: horizontalPadding.copyWith(
              top: AppSpacing.xl,
              bottom: AppSpacing.paddingLarge,
            ),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await launchUrlString(headline.url!);
                  },
                  child: Text(l10n.headlineDetailsContinueReadingButton),
                ),
              ),
            ),
          ),
        if (headline.url == null)
          const SliverPadding(
            padding: EdgeInsets.only(bottom: AppSpacing.paddingLarge),
            sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: horizontalPadding.copyWith(top: AppSpacing.xl),
            child: Text(
              l10n.similarHeadlinesSectionTitle,
              style: textTheme.titleLarge,
            ),
          ),
        ),
        _buildSimilarHeadlinesSection(context),
      ],
    );
  }

  List<Widget> _buildMetadataChips(BuildContext context, Headline headline) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final chipLabelStyle = textTheme.labelSmall;
    final chipBackgroundColor = theme.colorScheme.surfaceContainerHighest;
    final chipAvatarColor = theme.colorScheme.onSurfaceVariant;
    const chipAvatarSize = 14.0;
    const chipPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.xs / 2,
    );
    const chipVisualDensity = VisualDensity.compact;
    const chipMaterialTapTargetSize = MaterialTapTargetSize.shrinkWrap;

    final chips = <Widget>[];

    if (headline.source != null) {
      chips.add(
        Chip(
          avatar: Icon(
            Icons.source,
            size: chipAvatarSize,
            color: chipAvatarColor,
          ),
          label: Text(headline.source!.name),
          labelStyle: chipLabelStyle,
          backgroundColor: chipBackgroundColor,
          padding: chipPadding,
          visualDensity: chipVisualDensity,
          materialTapTargetSize: chipMaterialTapTargetSize,
        ),
      );
    }

    if (headline.publishedAt != null) {
      final formattedDate = DateFormat(
        'MMM d, yyyy',
      ).format(headline.publishedAt!);
      chips.add(
        Chip(
          avatar: Icon(
            Icons.date_range,
            size: chipAvatarSize,
            color: chipAvatarColor,
          ),
          label: Text(formattedDate),
          labelStyle: chipLabelStyle,
          backgroundColor: chipBackgroundColor,
          padding: chipPadding,
          visualDensity: chipVisualDensity,
          materialTapTargetSize: chipMaterialTapTargetSize,
        ),
      );
    }

    if (headline.source?.headquarters != null) {
      final country = headline.source!.headquarters!;
      chips.add(
        Chip(
          avatar: CircleAvatar(
            radius: chipAvatarSize / 2,
            backgroundColor: Colors.transparent,
            backgroundImage: NetworkImage(country.flagUrl),
            onBackgroundImageError: (exception, stackTrace) {},
          ),
          label: Text(country.name),
          labelStyle: chipLabelStyle,
          backgroundColor: chipBackgroundColor,
          padding: chipPadding,
          visualDensity: chipVisualDensity,
          materialTapTargetSize: chipMaterialTapTargetSize,
        ),
      );
    }

    if (headline.category != null) {
      chips.add(
        Chip(
          label: Text(headline.category!.name),
          labelStyle: chipLabelStyle,
          backgroundColor: chipBackgroundColor,
          padding: chipPadding,
          visualDensity: chipVisualDensity,
          materialTapTargetSize: chipMaterialTapTargetSize,
        ),
      );
    }
    return chips;
  }

  Widget _buildSimilarHeadlinesSection(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<SimilarHeadlinesBloc, SimilarHeadlinesState>(
      builder: (context, state) {
        return switch (state) {
          SimilarHeadlinesInitial() ||
          SimilarHeadlinesLoading() => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          final SimilarHeadlinesError errorState => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                errorState.message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
          SimilarHeadlinesEmpty() => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.similarHeadlinesEmpty,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          final SimilarHeadlinesLoaded loadedState => SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final similarHeadline = loadedState.similarHeadlines[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.paddingMedium,
                  vertical: AppSpacing.sm,
                ),
                child: Builder(
                  // Use Builder to get a new context that can watch AppBloc
                  builder: (context) {
                    final imageStyle =
                        context
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
                          onHeadlineTap:
                              () => context.pushNamed(
                                Routes.articleDetailsName,
                                pathParameters: {'id': similarHeadline.id},
                                extra: similarHeadline,
                              ),
                        );
                        break;
                      case HeadlineImageStyle.smallThumbnail:
                        tile = HeadlineTileImageStart(
                          headline: similarHeadline,
                          onHeadlineTap:
                              () => context.pushNamed(
                                Routes.articleDetailsName,
                                pathParameters: {'id': similarHeadline.id},
                                extra: similarHeadline,
                              ),
                        );
                        break;
                      case HeadlineImageStyle.largeThumbnail:
                        tile = HeadlineTileImageTop(
                          headline: similarHeadline,
                          onHeadlineTap:
                              () => context.pushNamed(
                                Routes.articleDetailsName,
                                pathParameters: {'id': similarHeadline.id},
                                extra: similarHeadline,
                              ),
                        );
                        break;
                    }
                    return tile;
                  },
                ),
              );
            }, childCount: loadedState.similarHeadlines.length),
          ),
          _ => const SliverToBoxAdapter(child: SizedBox.shrink()),
        };
      },
    );
  }
}
