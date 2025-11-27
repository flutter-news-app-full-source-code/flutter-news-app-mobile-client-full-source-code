import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template demo_banner_ad_widget}
/// A widget that displays a placeholder for a banner ad in demo mode.
///
/// This widget mimics the visual dimensions of a real banner ad but
/// contains only static text to indicate it's a demo.
/// {@endtemplate}
class DemoBannerAdWidget extends StatelessWidget {
  /// {@macro demo_banner_ad_widget}
  const DemoBannerAdWidget({this.feedItemImageStyle, super.key});

  /// The user's preference for feed layout, used to determine the ad's visual size.
  final FeedItemImageStyle? feedItemImageStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine the height based on the feedItemImageStyle.
    final adHeight = feedItemImageStyle == FeedItemImageStyle.largeThumbnail
        ? 250
        : 50;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMedium,
        vertical: AppSpacing.xs,
      ),
      child: SizedBox(
        height: adHeight.toDouble(),
        width: double.infinity,
        child: Center(
          child: Text(
            AppLocalizations.of(context).demoBannerAdText,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
