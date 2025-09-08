import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template demo_native_ad_widget}
/// A widget that displays a placeholder for a native ad in demo mode.
///
/// This widget mimics the visual dimensions of a real native ad but
/// contains only static text to indicate it's a demo.
/// {@endtemplate}
class DemoNativeAdWidget extends StatelessWidget {
  /// {@macro demo_native_ad_widget}
  const DemoNativeAdWidget({this.headlineImageStyle, super.key});

  /// The user's preference for feed layout, used to determine the ad's visual size.
  final HeadlineImageStyle? headlineImageStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Determine the height based on the headlineImageStyle, mimicking real ad widgets.
    final adHeight = headlineImageStyle == HeadlineImageStyle.largeThumbnail
        ? 250 // Height for medium native ad template
        : 120; // Height for small native ad template

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
            l10n.demoNativeAdText,
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
