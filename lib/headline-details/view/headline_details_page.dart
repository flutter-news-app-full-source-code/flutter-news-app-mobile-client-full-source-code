import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_headlines_client/ht_headlines_client.dart'; // Import for Headline
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/headline-details/bloc/headline_details_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/widgets/failure_state_widget.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/shared.dart'; // Import shared barrel file
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HeadlineDetailsPage extends StatelessWidget {
  const HeadlineDetailsPage({required this.headlineId, super.key});

  final String headlineId;

  static Route<void> route({required String headlineId}) {
    return MaterialPageRoute<void>(
      builder: (_) => HeadlineDetailsPage(headlineId: headlineId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => HeadlineDetailsBloc(
            headlinesRepository: context.read<HtHeadlinesRepository>(),
          )..add(HeadlineDetailsRequested(headlineId: headlineId)),
      child: const _HeadlineDetailsView(),
    );
  }
}

class _HeadlineDetailsView extends StatelessWidget {
  const _HeadlineDetailsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<HeadlineDetailsBloc, HeadlineDetailsState>(
        builder: (context, state) {
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
                  HeadlineDetailsRequested(headlineId: '1'),
                );
              },
            ),
            final HeadlineDetailsLoaded state => _buildLoaded(
              context,
              state.headline,
            ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, Headline headline) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      // Use shared padding constant
      padding: const EdgeInsets.all(AppSpacing.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Image ---
          if (headline.imageUrl != null) ...[
            ClipRRect( // Add rounded corners to the image
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child: Image.network(
                headline.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 200,
                    // Use theme color for placeholder
                    color: colorScheme.surfaceVariant,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 200,
                  color: colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.broken_image,
                    color: colorScheme.onSurfaceVariant,
                    size: AppSpacing.xxl,
                  ),
                ),
              ),
            ),
            // Use shared spacing constant
            const SizedBox(height: AppSpacing.lg),
          ],

          // --- Title ---
          Text(headline.title, style: textTheme.titleLarge),
          // Use shared spacing constant
          const SizedBox(height: AppSpacing.md), // Increased spacing before metadata

          // --- Metadata Section ---
          _buildMetadataSection(context, headline),
          // Use shared spacing constant
          const SizedBox(height: AppSpacing.lg),

          // --- Description ---
          if (headline.description != null) ...[
            Text(
              headline.description!,
              style: textTheme.bodyLarge,
            ),
            // Use shared spacing constant
            const SizedBox(height: AppSpacing.xl), // Increased spacing before button
          ],

          // --- Continue Reading Button ---
          if (headline.url != null)
            SizedBox( // Make button full width
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await launchUrlString(headline.url!);
                },
                // Style is often handled by ElevatedButtonThemeData in AppTheme
                // but explicitly setting background for clarity if needed.
                // style: ElevatedButton.styleFrom(
                //   backgroundColor: colorScheme.primary,
                //   foregroundColor: colorScheme.onPrimary,
                // ),
                child: Text(
                  l10n.headlineDetailsContinueReadingButton,
                  // Ensure labelLarge has contrast if theme doesn't handle it
                  // style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the metadata section (Source, Date, Categories, Country).
  Widget _buildMetadataSection(BuildContext context, Headline headline) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final metadataStyle = textTheme.bodyMedium; // Or textTheme.caption

    // Helper to create consistent metadata rows
    Widget buildMetadataRow(IconData icon, String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(text, style: metadataStyle)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headline.source != null)
          buildMetadataRow(Icons.source, headline.source!),
        if (headline.publishedAt != null)
          buildMetadataRow(
            Icons.date_range,
            DateFormat('MMMM dd, yyyy').format(headline.publishedAt!),
          ),
        if (headline.eventCountry != null)
          buildMetadataRow(Icons.location_on, headline.eventCountry!),
        if (headline.categories != null && headline.categories!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align icon top
              children: [
                Icon(Icons.category, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.xs, // Horizontal spacing between chips
                    runSpacing: AppSpacing.xs, // Vertical spacing if wraps
                    children: headline.categories!
                        .map((category) => Chip(
                              label: Text(category),
                              labelStyle: textTheme.labelSmall,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: theme.colorScheme.secondaryContainer,
                              labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
