part of 'in_app_notification_center_bloc.dart';

/// Base class for all events in the [InAppNotificationCenterBloc].
abstract class InAppNotificationCenterEvent extends Equatable {
  const InAppNotificationCenterEvent();

  @override
  List<Object> get props => [];
}

/// Dispatched when the notification center is opened and needs to load
/// the initial list of notifications.
class InAppNotificationCenterSubscriptionRequested
    extends InAppNotificationCenterEvent {
  const InAppNotificationCenterSubscriptionRequested();
}

/// Dispatched when a single in-app notification is marked as read.
class InAppNotificationCenterMarkedAsRead extends InAppNotificationCenterEvent {
  const InAppNotificationCenterMarkedAsRead(this.notificationId);

  /// The ID of the notification to be marked as read.
  final String notificationId;

  @override
  List<Object> get props => [notificationId];
}

/// Dispatched when the user requests to mark all notifications as read.
class InAppNotificationCenterMarkAllAsRead
    extends InAppNotificationCenterEvent {
  const InAppNotificationCenterMarkAllAsRead();
}

/// Dispatched when the user changes the selected tab in the notification center.
class InAppNotificationCenterTabChanged extends InAppNotificationCenterEvent {
  const InAppNotificationCenterTabChanged(this.tabIndex);

  /// The index of the newly selected tab. 0: Breaking News, 1: Digests.
  final int tabIndex;

  @override
  List<Object> get props => [tabIndex];
}

/// Dispatched when a single in-app notification is marked as read by its ID,
/// typically from a deep-link without navigating from the notification center.
class InAppNotificationCenterMarkOneAsRead
    extends InAppNotificationCenterEvent {
  const InAppNotificationCenterMarkOneAsRead(this.notificationId);

  /// The ID of the notification to be marked as read.
  final String notificationId;

  @override
  List<Object> get props => [notificationId];
}

/// Dispatched when the user scrolls to the end of a notification list and
/// more data needs to be fetched.
class InAppNotificationCenterFetchMoreRequested
    extends InAppNotificationCenterEvent {
  const InAppNotificationCenterFetchMoreRequested();
}

/// Dispatched when the user requests to delete all read items in the
/// currently active tab.
class InAppNotificationCenterReadItemsDeleted
    extends InAppNotificationCenterEvent {
  const InAppNotificationCenterReadItemsDeleted();
}
