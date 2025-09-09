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
      onTap: () {
        context.read<InterstitialAdManager>().onPotentialAdTrigger(
          context: context,
        );
        context.pushNamed(
          Routes.entityDetailsName,
          pathParameters: {'type': ContentType.country.name, 'id': country.id},
        );
      },
    );
  }
}
