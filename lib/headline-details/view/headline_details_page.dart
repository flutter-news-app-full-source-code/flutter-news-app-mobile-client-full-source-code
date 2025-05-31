//
// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/account/bloc/account_bloc.dart'; // Import AccountBloc
import 'package:ht_main/headline-details/bloc/headline_details_bloc.dart'; // Import BLoC
import 'package:ht_main/headline-details/bloc/similar_headlines_bloc.dart'; // Import SimilarHeadlinesBloc
import 'package:ht_main/headlines-feed/widgets/headline_item_widget.dart'; // Import HeadlineItemWidget
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart'; // Import Routes
import 'package:ht_main/shared/shared.dart';
import 'package:ht_shared/ht_shared.dart'
    show Headline; // Import Headline model
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart'; // Import share_plus
import 'package:url_launcher/url_launcher_string.dart';

class HeadlineDetailsPage extends StatefulWidget {
  const HeadlineDetailsPage({
    super.key,
    this.headlineId,
    this.initialHeadline,
  }) : assert(headlineId != null || initialHeadline != null);

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
      context
          .read<HeadlineDetailsBloc>()
          .add(HeadlineProvided(widget.initialHeadline!));
    } else if (widget.headlineId != null) {
      context
          .read<HeadlineDetailsBloc>()
          .add(FetchHeadlineById(widget.headlineId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: Scaffold(
        body: BlocListener<AccountBloc, AccountState>(
          listenWhen: (previous, current) {
            final detailsState = context.read<HeadlineDetailsBloc>().state;
            if (detailsState is HeadlineDetailsLoaded) {
              if (current.status == AccountStatus.failure &&
                  previous.status != AccountStatus.failure) {
                return true;
              }
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
              return (wasPreviouslySaved != isCurrentlySaved) ||
                  (current.status == AccountStatus.success &&
                      previous.status != AccountStatus.success);
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
                HeadlineDetailsLoading() =>
                  LoadingStateWidget(
                    icon: Icons.downloading,
                    headline: l10n.headlineDetailsLoadingHeadline,
                    subheadline: l10n.headlineDetailsLoadingSubheadline,
                  ),
                final HeadlineDetailsFailure failureState => FailureStateWidget(
                    message: failureState.message,
                    onRetry: () {
                      if (widget.headlineId != null) {
                        context
                            .read<HeadlineDetailsBloc>()
                            .add(FetchHeadlineById(widget.headlineId!));
                      }
                      // If only initialHeadline was provided and it failed to load
                      // (which shouldn't happen with HeadlineProvided),
                      // there's no ID to refetch. Consider a different UI.
                    },
                  ),
                final HeadlineDetailsLoaded loadedState =>
                  _buildLoadedContent(context, loadedState.headline),
                // Add a default case to satisfy exhaustiveness
                _ => const Center(child: Text('Unknown state')),
              };
            },
          ),
        ),
      ),
    );
  }

  /// Builds the main content area using CustomScrollView and Slivers.
  Widget _buildLoadedContent(BuildContext context, Headline headline) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // Define horizontal padding once
    const horizontalPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.paddingLarge,
    );

    // Return CustomScrollView instead of SingleChildScrollView
    // Watch AccountBloc state for saved status
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

    // Use a Builder to get the correct context for sharePositionOrigin
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

            String shareText = headline.title;
            if (headline.url != null && headline.url!.isNotEmpty) {
              shareText += '\n\n${headline.url}';
            }

            ShareParams params;
            if (kIsWeb && headline.url != null && headline.url!.isNotEmpty) {
              // For web, prioritize sharing the URL directly as a URI.
              // The 'title' in ShareParams might be used by some platforms or if
              // the plugin's web handling evolves to use it with navigator.share's title field.
              params = ShareParams(
                uri: Uri.parse(headline.url!),
                title: headline.title, // Title hint for the shared content
                sharePositionOrigin: sharePositionOrigin,
              );
            } else if (headline.url != null && headline.url!.isNotEmpty) {
              // For native platforms with a URL, combine title and URL in text.
              // Subject can be used by email clients.
              params = ShareParams(
                text: '${headline.title}\n\n${headline.url!}',
                subject: headline.title,
                sharePositionOrigin: sharePositionOrigin,
              );
            } else {
              // No URL, share only the title as text (works for all platforms).
              params = ShareParams(
                text: headline.title,
                subject: headline.title, // Subject for email clients
                sharePositionOrigin: sharePositionOrigin,
              );
            }

            final shareResult = await SharePlus.instance.share(params);

            // Optional: Handle ShareResult for user feedback
            if (buttonContext.mounted) { // Check if context is still valid
              if (shareResult.status == ShareResultStatus.unavailable) {
                ScaffoldMessenger.of(buttonContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.sharingUnavailableSnackbar, // Add this l10n key
                    ),
                  ),
                );
              }
              // You can add more feedback for success/dismissed if desired
              // e.g., print('Share result: ${shareResult.status}, raw: ${shareResult.raw}');
            }
          },
        );
      },
    );

    return CustomScrollView(
      slivers: [
        // --- App Bar ---
        SliverAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [bookmarkButton, shareButtonWidget], // Use the new widget
          // Pinned=false, floating=true, snap=true is common for news apps
          pinned: false,
          floating: true, // Trailing comma
          snap: true, // Trailing comma
          // Transparent background to let content scroll behind if needed
          backgroundColor: Colors.transparent, // Trailing comma
          elevation: 0, // Trailing comma
          // Ensure icons use appropriate theme color
          foregroundColor:
              theme.colorScheme.onSurface, // Trailing comma (optional if last)
        ), // SliverAppBar
        // --- Title ---
        SliverPadding(
          padding: horizontalPadding.copyWith(top: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Text(headline.title, style: textTheme.headlineMedium),
          ),
        ),

        // --- Image ---
        if (headline.imageUrl != null)
          SliverPadding(
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              left: AppSpacing.paddingLarge,
              right: AppSpacing.paddingLarge,
            ),
            sliver: SliverToBoxAdapter(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.md),
                child: Image.network(
                  headline.imageUrl!,
                  width: double.infinity,
                  height: 200, // Keep fixed height or make adaptive
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 200,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image,
                          color: colorScheme.onSurfaceVariant,
                          size: AppSpacing.xxl,
                        ),
                      ),
                ),
              ),
            ),
          ),

        // --- Metadata Section (Wrap based) ---
        SliverPadding(
          padding: horizontalPadding.copyWith(top: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: AppSpacing.sm, // Horizontal space between chips
              runSpacing: AppSpacing.sm, // Vertical space between lines
              children: _buildMetadataChips(context, headline),
            ),
          ),
        ),

        // --- Description ---
        if (headline.description != null)
          SliverPadding(
            padding: horizontalPadding.copyWith(top: AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Text(headline.description!, style: textTheme.bodyLarge),
            ),
          ),

        // --- Continue Reading Button ---
        if (headline.url != null)
          SliverPadding(
            // Add extra space before the button and bottom padding
            padding: horizontalPadding.copyWith(
              top: AppSpacing.xl,
              bottom: AppSpacing.paddingLarge,
            ),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Consider adding error handling for launchUrlString
                    await launchUrlString(headline.url!);
                  },
                  child: Text(l10n.headlineDetailsContinueReadingButton),
                ),
              ),
            ),
          ),

        // Add some bottom space if no button exists
        if (headline.url == null)
          const SliverPadding(
            padding: EdgeInsets.only(bottom: AppSpacing.paddingLarge),
            sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        // --- Similar Headlines Section ---
        SliverToBoxAdapter(
          child: Padding(
            padding: horizontalPadding.copyWith(top: AppSpacing.xl),
            child: Text(
              l10n.similarHeadlinesSectionTitle, // Add this l10n key
              style: textTheme.titleLarge,
            ),
          ),
        ),
        _buildSimilarHeadlinesSection(context),
      ],
    );
  }

  /// Helper function to generate the list of metadata Chips for the Wrap.
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

    // Source Chip
    if (headline.source != null) {
      // Source model doesn't have a logoUrl, using a generic icon.
      chips.add(
        Chip(
          avatar: Icon(
            Icons.source, // Generic source icon
            size: chipAvatarSize,
            color: chipAvatarColor,
          ),
          // Use source.name
          label: Text(headline.source!.name),
          labelStyle: chipLabelStyle,
          backgroundColor: chipBackgroundColor,
          padding: chipPadding,
          visualDensity: chipVisualDensity,
          materialTapTargetSize: chipMaterialTapTargetSize,
        ),
      );
    }

    // Date Chip
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

    // Country Chip (from Source Headquarters)
    if (headline.source?.headquarters != null) {
      final country = headline.source!.headquarters!;
      chips.add(
        Chip(
          avatar: CircleAvatar(
            radius: chipAvatarSize / 2,
            backgroundColor: Colors.transparent,
            backgroundImage: NetworkImage(country.flagUrl),
            onBackgroundImageError: (exception, stackTrace) {
              // Optional: Handle image loading errors, e.g., show placeholder
            },
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

    // Category Chip (No avatar for individual category)
    if (headline.category != null) {
      chips.add(
        Chip(
          // Use category.name
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
          SimilarHeadlinesLoading() =>
            const SliverToBoxAdapter(
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
                  l10n.similarHeadlinesEmpty, // Add this l10n key
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          final SimilarHeadlinesLoaded loadedState => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final similarHeadline = loadedState.similarHeadlines[index];
                  // Use a more compact item or reuse HeadlineItemWidget
                  // For now, reusing HeadlineItemWidget for simplicity
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.paddingMedium,
                      vertical: AppSpacing.sm,
                    ),
                    // Navigate to a new HeadlineDetailsPage instance
                    // Ensure the targetRouteName is appropriate or handle navigation differently
                    child: HeadlineItemWidget(
                      headline: similarHeadline,
                      targetRouteName: Routes.articleDetailsName,
                    ),
                  );
                },
                childCount: loadedState.similarHeadlines.length,
              ),
            ),
          // Add a default case to satisfy exhaustiveness for the switch statement
          _ => const SliverToBoxAdapter(child: SizedBox.shrink()),
        };
      },
    );
  }
}
