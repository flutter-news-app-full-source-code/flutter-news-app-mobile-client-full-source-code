import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/headline-details/view/bloc/headline_details_bloc.dart';
import 'package:ht_main/shared/widgets/failure_state_widget.dart';
import 'package:ht_main/shared/widgets/initial_state_widget.dart';
import 'package:ht_main/shared/widgets/loading_state_widget.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:intl/intl.dart';

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
      create: (context) => HeadlineDetailsBloc(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Headline Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {}, // Placeholder
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {}, // Placeholder
          ),
        ],
      ),
      body: BlocBuilder<HeadlineDetailsBloc, HeadlineDetailsState>(
        builder: (context, state) {
          return switch (state) {
            HeadlineDetailsInitial _ => const InitialStateWidget(
                icon: Icons.article,
                headline: 'Waiting for Headline',
                subheadline: 'Please wait...',
              ),
            HeadlineDetailsLoading _ => const LoadingStateWidget(
                icon: Icons.downloading,
                headline: 'Loading Headline',
                subheadline: 'Fetching data...',
              ),
            final HeadlineDetailsFailure state => FailureStateWidget(
                message: state.message,
                onRetry: () {
                  context
                      .read<HeadlineDetailsBloc>()
                      .add(HeadlineDetailsRequested(headlineId: '1'));
                },
              ),
            final HeadlineDetailsLoaded state =>
              _buildLoaded(context, state.headline),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, Headline headline) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (headline.imageUrl != null)
              Image.network(
                headline.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error),
              ),
            const SizedBox(height: 16), // Keep this
            Text(
              headline.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                if (headline.source != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.source),
                      const SizedBox(width: 4),
                      Text(
                        headline.source!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(
                      height: 8), // Add spacing between metadata items
                ],
                if (headline.categories != null &&
                    headline.categories!.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.category),
                      const SizedBox(width: 4),
                      Text(
                        headline.categories!.join(', '),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (headline.eventCountry != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on),
                      const SizedBox(width: 4),
                      Text(
                        headline.eventCountry!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (headline.publishedAt != null)
                  Row(
                    children: [
                      const Icon(Icons.date_range),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMMM dd, yyyy')
                            .format(headline.publishedAt!),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (headline.description != null)
              Text(
                headline.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (headline.url != null) {
                  await launchUrlString(headline.url!);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                // Removed custom padding
              ),
              child: Text(
                'Continue Reading',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
