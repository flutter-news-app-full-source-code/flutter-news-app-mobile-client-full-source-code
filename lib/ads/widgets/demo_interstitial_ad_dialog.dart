import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template demo_interstitial_ad_dialog}
/// A dialog widget that displays a placeholder for an interstitial ad in demo mode.
///
/// This dialog mimics a full-screen interstitial ad but contains only static
/// text to indicate it's a demo.
/// {@endtemplate}
class DemoInterstitialAdDialog extends StatelessWidget {
  /// {@macro demo_interstitial_ad_dialog}
  const DemoInterstitialAdDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog.fullscreen(
      backgroundColor: theme.colorScheme.surface,
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context).demoInterstitialAdText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppLocalizations.of(context).demoInterstitialAdDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.lg,
            child: IconButton(
              icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
              onPressed: () {
                // Dismiss the dialog.
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
