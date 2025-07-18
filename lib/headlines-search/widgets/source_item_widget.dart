import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/entity_details/view/entity_details_page.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_shared/ht_shared.dart';

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
              source.description,
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
