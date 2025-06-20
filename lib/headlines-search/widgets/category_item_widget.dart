import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Added
import 'package:ht_main/entity_details/view/entity_details_page.dart'; // Added
import 'package:ht_main/router/routes.dart'; // Added
import 'package:ht_shared/ht_shared.dart'; // Import Category model

/// A simple widget to display a Category search result.
class CategoryItemWidget extends StatelessWidget {
  const CategoryItemWidget({required this.category, super.key});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(category.name),
      subtitle: category.description != null
          ? Text(
              category.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: () {
        context.push(
          Routes.categoryDetails,
          extra: EntityDetailsPageArguments(entity: category),
        );
      },
    );
  }
}
