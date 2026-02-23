part of 'in_app_notification_center_bloc.dart';

/// The status of the [InAppNotificationCenterBloc].
enum InAppNotificationCenterStatus {
  /// The initial state.
  initial,

  /// The state when notifications are being loaded.
  loading,

  /// The state when more notifications are being loaded for pagination.
  loadingMore,

  /// The state when notifications have been successfully loaded.
  success,

  /// The state when an error has occurred.
  failure,

  /// The state when read notifications are being deleted.
  deleting,
}

/// {@template in_app_notification_center_state}
/// The state of the in-app notification center.
/// {@endtemplate}
class InAppNotificationCenterState extends Equatable {
  /// {@macro in_app_notification_center_state}
  const InAppNotificationCenterState({
    this.status = InAppNotificationCenterStatus.initial,
    this.notifications = const [],
    this.hasMore = true,
    this.cursor,
    this.error,
  });

  /// The list of all notifications.
  final List<InAppNotification> notifications;

  /// The current status of the notification center.
  final InAppNotificationCenterStatus status;

  /// An error that occurred during notification loading or processing.
  final HttpException? error;

  /// A flag indicating if there are more notifications to fetch.
  final bool hasMore;

  /// The cursor for fetching the next page of notifications.
  final String? cursor;

  /// A convenience getter to determine if the current tab has any read items.
  bool get hasReadItems => notifications.any((n) => n.isRead);

  @override
  List<Object?> get props => [status, notifications, hasMore, cursor, error];

  /// Creates a copy of this state with the given fields replaced with the new
  /// values.
  InAppNotificationCenterState copyWith({
    InAppNotificationCenterStatus? status,
    HttpException? error,
    List<InAppNotification>? notifications,
    bool? hasMore,
    String? cursor,
    bool clearCursor = false,
  }) {
    return InAppNotificationCenterState(
      status: status ?? this.status,
      // Allow explicitly setting the error to null.
      // ignore: avoid_redundant_argument_values
      error: error,
      notifications: notifications ?? this.notifications,
      hasMore: hasMore ?? this.hasMore,
      cursor: clearCursor ? null : cursor ?? this.cursor,
    );
  }
}
