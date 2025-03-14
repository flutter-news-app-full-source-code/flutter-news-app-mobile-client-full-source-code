import 'package:flutter/material.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart'
    show Headline;

/// A widget that displays a single headline.
class HeadlineItemWidget extends StatelessWidget {
  /// Creates a [HeadlineItemWidget].
  const HeadlineItemWidget({required this.headline, super.key});

  /// The headline to display.
  final Headline headline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline.title ?? 'No Title',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (headline.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                headline.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
