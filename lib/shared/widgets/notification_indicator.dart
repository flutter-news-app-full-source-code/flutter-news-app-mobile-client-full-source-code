import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template notification_indicator}
/// A widget that displays a small dot over its child to indicate a notification.
///
/// This is typically used to wrap a user avatar or an icon button.
/// {@endtemplate}
class NotificationIndicator extends StatelessWidget {
  /// {@macro notification_indicator}
  const NotificationIndicator({
    required this.child,
    required this.showIndicator,
    super.key,
  });

  /// The widget to display below the indicator.
  final Widget child;

  /// Whether to show the notification dot.
  final bool showIndicator;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (showIndicator)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: AppSpacing.sm,
              height: AppSpacing.sm,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
