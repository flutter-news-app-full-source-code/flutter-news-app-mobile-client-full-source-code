import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';

/// A simple widget to display a Country search result.
class CountryItemWidget extends StatelessWidget {
  /// Creates a [CountryItemWidget].
  const CountryItemWidget({required this.country, super.key});

  /// The country to display.
  final Country country;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(country.flagUrl)),
      title: Text(country.name),
      subtitle: country.isoCode.isNotEmpty
          ? Text(country.isoCode, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      onTap: () async {
        // Await for the ad to be shown and dismissed.
        await context.read<InterstitialAdManager>().onPotentialAdTrigger();

        // Check if the widget is still in the tree before navigating.
        if (!context.mounted) return;

        // Proceed with navigation after the ad is closed.
        await context.pushNamed(
          Routes.entityDetailsName,
          pathParameters: {'type': ContentType.country.name, 'id': country.id},
        );
      },
    );
  }
}
