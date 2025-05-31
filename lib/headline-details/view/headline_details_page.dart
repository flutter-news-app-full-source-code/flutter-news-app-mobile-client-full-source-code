//
// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/account/bloc/account_bloc.dart'; // Import AccountBloc
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/shared.dart';
import 'package:ht_shared/ht_shared.dart'
    show Headline; // Import Headline model
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart'; // Import share_plus
import 'package:url_launcher/url_launcher_string.dart';

class HeadlineDetailsPage extends StatelessWidget {
  const HeadlineDetailsPage({required this.headline, super.key});

  final Headline headline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Headline is now a direct member: this.headline
    // No longer need to watch HeadlineDetailsBloc or its state here.

    return SafeArea(
      child: Scaffold(
        body: BlocListener<AccountBloc, AccountState>(
          listenWhen: (previous, current) {
            if (current.status == AccountStatus.failure &&
                previous.status != AccountStatus.failure) {
              return true;
            }
            final currentHeadlineId = headline.id;
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
          },
          listener: (context, accountState) {
            final nowIsSaved =
                accountState.preferences?.savedHeadlines.any(
                  (h) => h.id == headline.id,
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
          }, // Corrected: Removed extra closing brace from here
          child: _buildLoadedContent(context, headline),
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

    final shareButton = IconButton(
      icon: const Icon(Icons.share),
      tooltip: l10n.shareActionTooltip, // Added tooltip
      onPressed: () {
        // Construct the share text
        // Use headline.url if available, otherwise just the title
        final shareText = headline.url != null
            ? '${headline.title}\n\n${headline.url}'
            : headline.title;
        Share.share(shareText);
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
          actions: [bookmarkButton, shareButton],
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
}
