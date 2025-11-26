import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ui_kit/ui_kit.dart';

/// {@template in_app_notification_list_item}
/// A widget that displays a single in-app notification in a list.
///
/// It shows the notification's title and the time it was received.
/// Unread notifications are visually distinguished with a leading dot and
/// a bolder title.
/// {@endtemplate}
class InAppNotificationListItem extends StatelessWidget {
  /// {@macro in_app_notification_list_item}
  const InAppNotificationListItem({
    required this.notification,
    required this.onTap,
    super.key,
  });

  /// The notification to display.
  final InAppNotification notification;

  /// The callback that is executed when the list item is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isUnread = !notification.isRead;

    return ListTile(
      leading: isUnread
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Container(
                width: AppSpacing.sm,
                height: AppSpacing.sm,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : const SizedBox(width: AppSpacing.sm),
      title: Text(
        notification.payload.title,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        timeago.format(notification.createdAt),
        style: textTheme.bodySmall,
      ),
      onTap: onTap,
    );
  }
}
