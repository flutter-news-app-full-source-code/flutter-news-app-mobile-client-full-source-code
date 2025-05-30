import 'package:flutter/material.dart';
import 'package:ht_shared/ht_shared.dart'; // Import Country model

/// A simple widget to display a Country search result.
class CountryItemWidget extends StatelessWidget {
  const CountryItemWidget({required this.country, super.key});

  final Country country;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(country.flagUrl),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('Error loading country flag: $exception');
        },
        child:
            country.flagUrl.isEmpty
                ? const Icon(
                  Icons.public_off_outlined,
                ) // Placeholder if no flag
                : null,
      ),
      title: Text(country.name),
      // TODO(you): Implement onTap navigation if needed for countries
      onTap: () {
        // Example: Navigate to a page showing headlines from this country
        // context.goNamed('someCountryFeedRoute', params: {'isoCode': country.isoCode});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tapped on country: ${country.name}')),
        );
      },
    );
  }
}
