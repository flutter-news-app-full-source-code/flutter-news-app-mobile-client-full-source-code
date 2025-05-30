import 'package:flutter/material.dart';
import 'package:ht_shared/ht_shared.dart'; // Import Source model

/// A simple widget to display a Source search result.
class SourceItemWidget extends StatelessWidget {
  const SourceItemWidget({required this.source, super.key});

  final Source source;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(source.name),
      subtitle: source.description != null
          ? Text(
              source.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      // TODO(you): Implement onTap navigation if needed for sources
      onTap: () {
        // Example: Navigate to a page showing headlines from this source
        // context.goNamed('someSourceFeedRoute', params: {'id': source.id});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tapped on source: ${source.name}')),
        );
      },
    );
  }
}
