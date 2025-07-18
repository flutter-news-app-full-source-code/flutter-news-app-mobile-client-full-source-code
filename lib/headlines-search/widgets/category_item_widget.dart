import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/entity_details/view/entity_details_page.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_shared/ht_shared.dart';

/// A simple widget to display a Topic search result.
class TopicItemWidget extends StatelessWidget {
  const TopicItemWidget({required this.topic, super.key});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(topic.name),
      subtitle: topic.description != null
          ? Text(
              topic.description!,
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
