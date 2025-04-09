//
// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_headlines_client/ht_headlines_client.dart';
import 'package:ht_main/headline-details/bloc/headline_details_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/shared.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HeadlineDetailsPage extends StatelessWidget {
  const HeadlineDetailsPage({required this.headlineId, super.key});

  final String headlineId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Scaffold(
        // Body contains the BlocBuilder which returns either state widgets
        // or the scroll view
        body: BlocBuilder<HeadlineDetailsBloc, HeadlineDetailsState>(
          builder: (context, state) {
            // Handle Loading/Initial/Failure states outside the scroll view
            // for better user experience.
            return switch (state) {
              HeadlineDetailsInitial _ => InitialStateWidget(
                icon: Icons.article,
                headline: l10n.headlineDetailsInitialHeadline,
                subheadline: l10n.headlineDetailsInitialSubheadline,
              ),
              HeadlineDetailsLoading _ => LoadingStateWidget(
                icon: Icons.downloading,
                headline: l10n.headlineDetailsLoadingHeadline,
                subheadline: l10n.headlineDetailsLoadingSubheadline,
              ),
              final HeadlineDetailsFailure state => FailureStateWidget(
                message: state.message,
                onRetry: () {
                  context.read<HeadlineDetailsBloc>().add(
                    HeadlineDetailsRequested(headlineId: headlineId),
                  );
                },
              ),
              final HeadlineDetailsLoaded state => _buildLoadedContent(
                context,
                state.headline,
              ),
              _ => const SizedBox.shrink(), // Should not happen in practice
            };
          },
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
    return CustomScrollView(
      slivers: [
        // --- App Bar ---
        SliverAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              onPressed: () {
                // TODO(fulleni): Implement bookmark functionality
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // TODO(fulleni): Implement share functionality
              },
            ),
          ],
          // Pinned=false, floating=true, snap=true is common for news apps
          pinned: false,
          floating: true,
          snap: true,
          // Transparent background to let content scroll behind if needed
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Ensure icons use appropriate theme color
          foregroundColor: theme.colorScheme.onSurface,
        ),

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

    // Country Chip
    if (headline.eventCountry != null) {
      // Use country.flagUrl for the avatar
      chips.add(
        Chip(
          avatar: CircleAvatar(
            // Use CircleAvatar for better image display
            radius: chipAvatarSize / 2, // Adjust radius as needed
            backgroundColor: Colors.transparent, // Avoid background color clash
            backgroundImage: NetworkImage(headline.eventCountry!.flagUrl),
            onBackgroundImageError: (exception, stackTrace) {
              // Optional: Handle image loading errors, e.g., show placeholder
            },
          ),
          // Use eventCountry.name
          label: Text(headline.eventCountry!.name),
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
