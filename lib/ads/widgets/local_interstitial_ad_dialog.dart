import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// {@template local_interstitial_ad_dialog}
/// A dialog widget that displays a local interstitial ad.
///
/// This dialog mimics a full-screen interstitial ad and includes a countdown
/// before the close button is enabled.
/// {@endtemplate}
class LocalInterstitialAdDialog extends StatefulWidget {
  /// {@macro local_interstitial_ad_dialog}
  const LocalInterstitialAdDialog({
    required this.localInterstitialAd,
    super.key,
  });

  /// The local interstitial ad data to display.
  final LocalInterstitialAd localInterstitialAd;

  @override
  State<LocalInterstitialAdDialog> createState() =>
      _LocalInterstitialAdDialogState();
}

class _LocalInterstitialAdDialogState extends State<LocalInterstitialAdDialog> {
  static const int _countdownDuration = 5;
  int _countdown = _countdownDuration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _launchUrl() async {
    final url = Uri.parse(widget.localInterstitialAd.targetUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canClose = _countdown == 0;

    return Dialog.fullscreen(
      backgroundColor: theme.colorScheme.surface,
      child: Stack(
        children: [
          Center(
            child: GestureDetector(
              onTap: _launchUrl,
              child: Image.network(
                widget.localInterstitialAd.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: AppSpacing.xxl,
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.lg,
            child: canClose
                ? IconButton(
                    icon:
                        Icon(Icons.close, color: theme.colorScheme.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.lg),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_countdown',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.close,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
