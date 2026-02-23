import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';

/// {@template entity_list_tile}
/// A reusable list tile for displaying a [FeedItem] entity (Topic, Source,
/// or Country).
///
/// Displays the entity's icon/logo, name, and a trailing chevron. Tapping the
/// tile navigates to the entity's detail page.
/// {@endtemplate}
class EntityListTile extends StatelessWidget {
  /// {@macro entity_list_tile}
  const EntityListTile({required this.item, super.key});

  /// The feed item to display.
  final FeedItem item;

  /// A static method to build the leading widget for a given [FeedItem].
  /// This allows reusing the leading widget logic in other parts of the app,
  /// such as the [MultiSelectSearchPage].
  static Widget buildLeading(FeedItem item) {
    switch (item) {
      case final Topic topic:
        return CircleAvatar(
          backgroundImage: topic.iconUrl != null
              ? NetworkImage(topic.iconUrl!)
              : null,
          child: topic.iconUrl == null ? const Icon(Icons.tag) : null,
        );
      case final Source source:
        return CircleAvatar(
          backgroundImage: source.logoUrl != null
              ? NetworkImage(source.logoUrl!)
              : null,
          child: source.logoUrl == null ? const Icon(Icons.public) : null,
        );
      case final Country country:
        return CircleAvatar(backgroundImage: NetworkImage(country.flagUrl));
      default:
        return const Icon(Icons.question_mark);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;

    switch (item) {
      case final Topic topic:
        title = topic.name;
      case final Source source:
        title = source.name;
      case final Country country:
        title = country.name;
      default:
        title = 'Unknown Item';
    }

    return ListTile(
      leading: buildLeading(item),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        final String entityId;
        final ContentType contentType;
        switch (item) {
          case final Topic topic:
            entityId = topic.id;
            contentType = ContentType.topic;
          case final Source source:
            entityId = source.id;
            contentType = ContentType.source;
          case final Country country:
            entityId = country.id;
            contentType = ContentType.country;
          default:
            return;
        }
        context.pushNamed(
          Routes.entityDetailsName,
          pathParameters: {'type': contentType.name, 'id': entityId},
        );
      },
    );
  }
}
