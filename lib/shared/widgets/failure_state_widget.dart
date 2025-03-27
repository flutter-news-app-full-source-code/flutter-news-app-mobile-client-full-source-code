import 'package:flutter/material.dart';

/// A widget to display an error message and an optional retry button.
class FailureStateWidget extends StatelessWidget {
  /// Creates a [FailureStateWidget].
  ///
  /// The [message] is the error message to display.
  ///
  /// The [onRetry] is an optional callback to be called
  /// when the retry button is pressed.
  const FailureStateWidget({required this.message, super.key, this.onRetry});

  /// The error message to display.
  final String message;

  /// An optional callback to be called when the retry button is pressed.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          // Show the retry button only if onRetry is provided
          if (onRetry != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
        ],
      ),
    );
  }
}
