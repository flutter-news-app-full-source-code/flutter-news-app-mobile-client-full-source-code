import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Added
import 'package:ht_main/entity_details/view/entity_details_page.dart'; // Added
import 'package:ht_main/router/routes.dart'; // Added
import 'package:ht_shared/ht_shared.dart'; // Import Source model

/// A simple widget to display a Source search result.
class SourceItemWidget extends StatelessWidget {
  const SourceItemWidget({required this.source, super.key});

  final Source source;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(source.name),
      subtitle:
          source.description != null
              ? Text(
                source.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
              : null,
      onTap: () {
        context.push(
          Routes.sourceDetails,
          extra: EntityDetailsPageArguments(entity: source),
        );
      },
    );
  }
}
