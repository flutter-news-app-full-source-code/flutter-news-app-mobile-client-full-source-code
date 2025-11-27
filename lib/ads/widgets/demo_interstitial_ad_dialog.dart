import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template demo_interstitial_ad_dialog}
/// A dialog widget that displays a placeholder for an interstitial ad in demo mode.
///
/// This dialog mimics a full-screen interstitial ad but contains only static
/// text to indicate it's a demo. It includes a countdown before the close
/// button is enabled.
/// {@endtemplate}
class DemoInterstitialAdDialog extends StatefulWidget {
  /// {@macro demo_interstitial_ad_dialog}
  const DemoInterstitialAdDialog({super.key});

  @override
  State<DemoInterstitialAdDialog> createState() =>
      _DemoInterstitialAdDialogState();
}

class _DemoInterstitialAdDialogState extends State<DemoInterstitialAdDialog> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizationsX(context).l10n;
    final canClose = _countdown == 0;

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
                    l10n.demoInterstitialAdText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.demoInterstitialAdDescription,
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
            bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: FilledButton(
              onPressed: canClose ? () => Navigator.of(context).pop() : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: canClose
                  ? Text(l10n.continueToArticleButtonLabel)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${l10n.continueToArticleButtonLabel} ($_countdown)'),
                      ],
                    ),
            ),
          ),
          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.lg,
            child: canClose
                ? IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
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
