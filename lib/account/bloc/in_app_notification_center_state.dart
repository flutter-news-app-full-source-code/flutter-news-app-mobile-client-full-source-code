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
    this.breakingNewsNotifications = const [],
    this.digestNotifications = const [],
    this.currentTabIndex = 0,
    this.error,
  });

  /// The currently selected tab index.
  /// 0: Breaking News, 1: Digests.
  final int currentTabIndex;

  /// The list of breaking news notifications.
  final List<InAppNotification> breakingNewsNotifications;

  /// The list of digest notifications (daily and weekly roundups).
  final List<InAppNotification> digestNotifications;

  /// The current status of the notification center.
  final InAppNotificationCenterStatus status;

  /// The combined list of all notifications.
  List<InAppNotification> get notifications => [
    ...breakingNewsNotifications,
    ...digestNotifications,
  ];

  /// An error that occurred during notification loading or processing.
  final HttpException? error;

  @override
  List<Object> get props => [
    status,
    currentTabIndex,
    breakingNewsNotifications,
    digestNotifications,
    error ?? Object(), // Include error in props, handle nullability
  ];

  /// Creates a copy of this state with the given fields replaced with the new
  /// values.
  InAppNotificationCenterState copyWith({
    InAppNotificationCenterStatus? status,
    HttpException? error,
    int? currentTabIndex,
    List<InAppNotification>? breakingNewsNotifications,
    List<InAppNotification>? digestNotifications,
  }) {
    return InAppNotificationCenterState(
      status: status ?? this.status,
      error: error ?? this.error,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      breakingNewsNotifications:
          breakingNewsNotifications ?? this.breakingNewsNotifications,
      digestNotifications: digestNotifications ?? this.digestNotifications,
    );
  }
}
