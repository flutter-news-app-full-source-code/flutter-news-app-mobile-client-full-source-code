import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:logging/logging.dart';

part 'in_app_notification_center_event.dart';
part 'in_app_notification_center_state.dart';

/// {@template in_app_notification_center_bloc}
/// Manages the state for the in-app notification center.
///
/// This BLoC is responsible for fetching the user's notifications,
/// handling actions to mark them as read individually or in bulk, and
/// coordinating with the global [AppBloc] to update the unread status
/// indicator across the app.
/// {@endtemplate}
class InAppNotificationCenterBloc
    extends Bloc<InAppNotificationCenterEvent, InAppNotificationCenterState> {
  /// {@macro in_app_notification_center_bloc}
  InAppNotificationCenterBloc({
    required DataRepository<InAppNotification> inAppNotificationRepository,
    required AppBloc appBloc,
    required Logger logger,
  }) : _inAppNotificationRepository = inAppNotificationRepository,
       _appBloc = appBloc,
       _logger = logger,
       super(const InAppNotificationCenterState()) {
    on<InAppNotificationCenterSubscriptionRequested>(_onSubscriptionRequested);
    on<InAppNotificationCenterMarkedAsRead>(_onMarkedAsRead);
    on<InAppNotificationCenterMarkAllAsRead>(_onMarkAllAsRead);
    on<InAppNotificationCenterTabChanged>(_onTabChanged);
  }

  final DataRepository<InAppNotification> _inAppNotificationRepository;
  final AppBloc _appBloc;
  final Logger _logger;

  /// Handles the request to load all notifications for the current user.
  Future<void> _onSubscriptionRequested(
    InAppNotificationCenterSubscriptionRequested event,
    Emitter<InAppNotificationCenterState> emit,
  ) async {
    emit(state.copyWith(status: InAppNotificationCenterStatus.loading));

    final userId = _appBloc.state.user?.id;
    if (userId == null) {
      _logger.warning('Cannot fetch notifications: user is not logged in.');
      emit(state.copyWith(status: InAppNotificationCenterStatus.failure));
      return;
    }

    try {
      final response = await _inAppNotificationRepository.readAll(
        userId: userId,
        sort: [const SortOption('createdAt', SortOrder.desc)],
      );

      final allNotifications = response.items;

      final breakingNews = <InAppNotification>[];
      final digests = <InAppNotification>[];

      // Filter notifications into their respective categories based on the
      // contentType specified in the payload's data map.
      for (final n in allNotifications) {
        final contentType = n.payload.data['contentType'] as String?;
        if (contentType == 'digest') {
          digests.add(n);
        } else {
          // Treat 'headline' and any other unknown types as breaking news
          // to ensure all notifications are visible to the user.
          breakingNews.add(n);
        }
      }

      emit(
        state.copyWith(
          status: InAppNotificationCenterStatus.success,
          breakingNewsNotifications: breakingNews,
          digestNotifications: digests,
        ),
      );
    } on HttpException catch (e, s) {
      _logger.severe('Failed to fetch in-app notifications.', e, s);
      emit(
        state.copyWith(status: InAppNotificationCenterStatus.failure, error: e),
      );
    } catch (e, s) {
      _logger.severe(
        'An unexpected error occurred while fetching in-app notifications.',
        e,
        s,
      );
      emit(
        state.copyWith(
          status: InAppNotificationCenterStatus.failure,
          error: UnknownException(e.toString()),
        ),
      );
    }
  }

  /// Handles the event to change the active tab.
  Future<void> _onTabChanged(
    InAppNotificationCenterTabChanged event,
    Emitter<InAppNotificationCenterState> emit,
  ) async {
    emit(state.copyWith(currentTabIndex: event.tabIndex));
  }

  /// Handles marking a single notification as read.
  Future<void> _onMarkedAsRead(
    InAppNotificationCenterMarkedAsRead event,
    Emitter<InAppNotificationCenterState> emit,
  ) async {
    final notification = state.notifications.firstWhere(
      (n) => n.id == event.notificationId,
      orElse: () => throw Exception('Notification not found in state'),
    );

    // If already read, do nothing.
    if (notification.isRead) return;

    final updatedNotification = notification.copyWith(readAt: DateTime.now());

    try {
      await _inAppNotificationRepository.update(
        id: notification.id,
        item: updatedNotification,
        userId: _appBloc.state.user?.id,
      );

      // Update the local state to reflect the change immediately.
      final updatedBreakingNewsList = state.breakingNewsNotifications
          .map((n) => n.id == notification.id ? updatedNotification : n)
          .toList();

      final updatedDigestList = state.digestNotifications
          .map((n) => n.id == notification.id ? updatedNotification : n)
          .toList();

      emit(
        state.copyWith(
          breakingNewsNotifications: updatedBreakingNewsList,
          digestNotifications: updatedDigestList,
        ),
      );

      // Notify the global AppBloc to re-check the unread count.
      _appBloc.add(const AppInAppNotificationMarkedAsRead());
    } on HttpException catch (e, s) {
      _logger.severe(
        'Failed to mark notification ${notification.id} as read.',
        e,
        s,
      );
      emit(
        state.copyWith(status: InAppNotificationCenterStatus.failure, error: e),
      );
      // Do not revert state to avoid UI flicker. The error is logged.
    } catch (e, s) {
      _logger.severe(
        'An unexpected error occurred while marking notification as read.',
        e,
        s,
      );
      emit(
        state.copyWith(
          status: InAppNotificationCenterStatus.failure,
          error: UnknownException(e.toString()),
        ),
      );
    }
  }

  /// Handles marking all unread notifications as read.
  Future<void> _onMarkAllAsRead(
    InAppNotificationCenterMarkAllAsRead event,
    Emitter<InAppNotificationCenterState> emit,
  ) async {
    final unreadNotifications = state.notifications
        .where((n) => !n.isRead)
        .toList();

    if (unreadNotifications.isEmpty) return;

    final now = DateTime.now();
    final updatedNotifications = unreadNotifications
        .map((n) => n.copyWith(readAt: now))
        .toList();

    try {
      // Perform all updates in parallel.
      await Future.wait(
        updatedNotifications.map(
          (n) => _inAppNotificationRepository.update(
            id: n.id,
            item: n,
            userId: _appBloc.state.user?.id,
          ),
        ),
      );

      // Update local state with all notifications marked as read.
      final fullyUpdatedBreakingNewsList = state.breakingNewsNotifications
          .map((n) => n.isRead ? n : n.copyWith(readAt: now))
          .toList();

      final fullyUpdatedDigestList = state.digestNotifications
          .map((n) => n.isRead ? n : n.copyWith(readAt: now))
          .toList();
      emit(
        state.copyWith(
          breakingNewsNotifications: fullyUpdatedBreakingNewsList,
          digestNotifications: fullyUpdatedDigestList,
        ),
      );

      // Notify the global AppBloc to clear the unread indicator.
      _appBloc.add(const AppAllInAppNotificationsMarkedAsRead());
    } on HttpException catch (e, s) {
      _logger.severe('Failed to mark all notifications as read.', e, s);
      emit(
        state.copyWith(status: InAppNotificationCenterStatus.failure, error: e),
      );
    } catch (e, s) {
      _logger.severe(
        'An unexpected error occurred while marking all notifications as read.',
        e,
        s,
      );
      emit(
        state.copyWith(
          status: InAppNotificationCenterStatus.failure,
          error: UnknownException(e.toString()),
        ),
      );
    }
  }
}
