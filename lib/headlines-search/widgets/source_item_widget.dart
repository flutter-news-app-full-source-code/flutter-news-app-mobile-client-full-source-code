import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/entity_details/view/entity_details_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';

/// A simple widget to display a Source search result.
class SourceItemWidget extends StatelessWidget {
  const SourceItemWidget({required this.source, super.key});

  final Source source;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(source.name),
      subtitle: source.description.isNotEmpty
          ? Text(
              source.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: () {
        context.push(
          Routes.sourceDetails,
          extra: EntityDetailsPageArguments(
            entityId: source.id,
            contentType: ContentType.source,
          ),
        );
      },
    );
  }
}
