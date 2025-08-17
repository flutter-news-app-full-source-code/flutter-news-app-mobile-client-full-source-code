import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template placeholder_ad_widget}
/// A widget that displays a generic placeholder for an advertisement.
///
/// This is used on platforms (like web) where actual native ad SDKs are not
/// supported, but a visual representation of an ad slot is desired for UI
/// consistency or demo purposes.
/// {@endtemplate}
class PlaceholderAdWidget extends StatelessWidget {
  /// {@macro placeholder_ad_widget}
  const PlaceholderAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.ad_units,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ad Placeholder',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Native ads are not supported on this platform.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
