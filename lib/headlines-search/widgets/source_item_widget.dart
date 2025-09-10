import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/interstitial_ad_manager.dart';
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
      onTap: () async {
        // Await for the ad to be shown and dismissed.
        await context.read<InterstitialAdManager>().onPotentialAdTrigger();

        // Check if the widget is still in the tree before navigating.
        if (!context.mounted) return;

        // Proceed with navigation after the ad is closed.
        await context.pushNamed(
          Routes.entityDetailsName,
          pathParameters: {'type': ContentType.source.name, 'id': source.id},
        );
      },
    );
  }
}
