import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template local_native_ad_widget}
/// A widget that renders a [LocalNativeAd].
/// {@endtemplate}
class LocalNativeAdWidget extends StatelessWidget {
  /// {@macro local_native_ad_widget}
  const LocalNativeAdWidget({
    required this.localNativeAd,
    this.headlineImageStyle,
    super.key,
  });

  /// The [LocalNativeAd] to display.
  final LocalNativeAd localNativeAd;

  /// The user's preference for feed layout, used to determine the ad's visual size.
  final HeadlineImageStyle? headlineImageStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine the height based on the headlineImageStyle.
    // If largeThumbnail, use a square aspect ratio, otherwise a standard native ad height.
    final double imageHeight =
        headlineImageStyle == HeadlineImageStyle.largeThumbnail ? 250 : 180;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMedium,
        vertical: AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (localNativeAd.imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Image.network(
                  localNativeAd.imageUrl,
                  fit: BoxFit.cover,
                  height: imageHeight,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            Text(
              localNativeAd.title,
              style: theme.textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              localNativeAd.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  // TODO(fulleni): Implement navigation to localNativeAd.targetUrl
                  // For now, just log the action.
                  debugPrint('Local Native Ad clicked: ${localNativeAd.targetUrl}');
                },
                child: const Text('Learn More'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
