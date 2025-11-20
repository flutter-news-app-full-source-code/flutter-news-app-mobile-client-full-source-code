part of 'in_app_notification_center_bloc.dart';

/// The status of the [InAppNotificationCenterBloc].
enum InAppNotificationCenterStatus {
  /// The initial state.
  initial,

  /// The state when notifications are being loaded.
  loading,

  /// The state when notifications have been successfully loaded.
  success,

  /// The state when an error has occurred.
  failure,
}

/// {@template in_app_notification_center_state}
/// The state of the in-app notification center.
/// {@endtemplate}
class InAppNotificationCenterState extends Equatable {
  /// {@macro in_app_notification_center_state}
  const InAppNotificationCenterState({
    this.status = InAppNotificationCenterStatus.initial,
    this.currentTabIndex = 0,
    this.notifications = const [],
    this.breakingNewsNotifications = const [],
    this.error,
    this.digestNotifications = const [],
  });

  /// The currently selected tab index.
  /// 0: All, 1: Breaking News, 2: Digests.
  final int currentTabIndex;

  /// The list of breaking news notifications.
  final List<InAppNotification> breakingNewsNotifications;

  /// The list of digest notifications (daily and weekly roundups).
  final List<InAppNotification> digestNotifications;

  /// Returns the list of notifications filtered by the current tab.
  List<InAppNotification> get filteredNotifications {
    return switch (currentTabIndex) {
      1 => breakingNewsNotifications,
      2 => digestNotifications,
      _ => notifications, // Default to 'All' tab
    };
  }

  /// The current status of the notification center.
  final InAppNotificationCenterStatus status;

  /// The list of notifications.
  final List<InAppNotification> notifications;

  /// An error that occurred during notification loading or processing.
  final HttpException? error;

  @override
  List<Object> get props => [
    status,
    notifications,
    currentTabIndex,
    breakingNewsNotifications,
    digestNotifications,
    error ?? Object(), // Include error in props, handle nullability
  ];

  /// Creates a copy of this state with the given fields replaced with the new
  /// values.
  InAppNotificationCenterState copyWith({
    InAppNotificationCenterStatus? status,
    List<InAppNotification>? notifications,
    HttpException? error,
    int? currentTabIndex,
    List<InAppNotification>? breakingNewsNotifications,
    List<InAppNotification>? digestNotifications,
  }) {
    return InAppNotificationCenterState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      error: error ?? this.error,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      breakingNewsNotifications:
          breakingNewsNotifications ?? this.breakingNewsNotifications,
      digestNotifications: digestNotifications ?? this.digestNotifications,
    );
  }
}
