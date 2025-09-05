import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template local_banner_ad_widget}
/// A widget that renders a [LocalBannerAd].
/// {@endtemplate}
class LocalBannerAdWidget extends StatelessWidget {
  /// {@macro local_banner_ad_widget}
  const LocalBannerAdWidget({required this.localBannerAd, super.key});

  /// The [LocalBannerAd] to display.
  final LocalBannerAd localBannerAd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingMedium,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: () {
          // TODO(fulleni): Implement navigation to localBannerAd.targetUrl
          // For now, just log the action.
          debugPrint('Local Banner Ad clicked: ${localBannerAd.targetUrl}');
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (localBannerAd.imageUrl.isNotEmpty)
                Image.network(
                  localBannerAd.imageUrl,
                  fit: BoxFit.cover,
                  height: 90, // Standard banner height
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Local Banner Ad',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
