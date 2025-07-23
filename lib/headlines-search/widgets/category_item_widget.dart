import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/entity_details/view/entity_details_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';

/// A simple widget to display a Topic search result.
class TopicItemWidget extends StatelessWidget {
  const TopicItemWidget({required this.topic, super.key});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(topic.name),
      subtitle: topic.description.isNotEmpty
          ? Text(
              topic.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: () {
        context.push(
          Routes.topicDetails,
          extra: EntityDetailsPageArguments(entity: topic),
        );
      },
    );
  }
}
