import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/constants/app_layout.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template critical_error_page}
/// A page displayed to the user when a critical application error occurs
/// during startup, such as a failure to fetch remote configuration or
/// user settings.
///
/// This page provides a clear error message and a retry option, allowing
/// the user to attempt to recover from transient issues.
/// {@endtemplate}
class CriticalErrorPage extends StatelessWidget {
  /// {@macro critical_error_page}
  const CriticalErrorPage({required this.onRetry, this.exception, super.key});

  /// The exception that caused the critical error.
  final HttpException? exception;

  /// A callback function to be executed when the user taps the retry button.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxDialogContentWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FailureStateWidget(
              exception:
                  exception ??
                  const UnknownException('An unknown critical error occurred.'),
              retryButtonText: l10n.retryButtonText,
              onRetry: onRetry,
            ),
          ),
        ),
      ),
    );
  }
}
