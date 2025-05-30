import 'package:flutter/material.dart';
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
      // TODO(you): Implement onTap navigation if needed for categories
      onTap: () {
        // Example: Navigate to a filtered feed for this category
        // context.goNamed('someCategoryFeedRoute', params: {'id': category.id});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tapped on category: ${category.name}')),
        );
      },
    );
  }
}
