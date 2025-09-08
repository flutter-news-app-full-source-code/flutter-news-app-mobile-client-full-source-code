import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

/// {@template local_interstitial_ad_dialog}
/// A dialog widget that displays a [LocalInterstitialAd].
///
/// This dialog is designed to be shown as a full-screen overlay,
/// presenting the ad's image and providing a way to dismiss it or
/// navigate to the ad's target URL.
/// {@endtemplate}
class LocalInterstitialAdDialog extends StatelessWidget {
  /// {@macro local_interstitial_ad_dialog}
  const LocalInterstitialAdDialog({
    required this.localInterstitialAd,
    super.key,
  });

  /// The [LocalInterstitialAd] to display.
  final LocalInterstitialAd localInterstitialAd;

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
                  if (localInterstitialAd.imageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: InkWell(
                        onTap: () async {
                          // Launch the target URL in an external browser.
                          final uri = Uri.parse(localInterstitialAd.targetUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            // Log an error or show a user-friendly message
                            // if the URL cannot be launched.
                            // For now, we'll just print to debug console.
                            debugPrint(
                              'Could not launch ${localInterstitialAd.targetUrl}',
                            );
                          }
                        },
                        child: Image.network(
                          localInterstitialAd.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Local Interstitial Ad',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'This is a full-screen advertisement.',
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
