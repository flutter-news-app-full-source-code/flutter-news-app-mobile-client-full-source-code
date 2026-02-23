import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
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
    on<InAppNotificationCenterSubscriptionRequested>(
      _onSubscriptionRequested,
      transformer: droppable(),
    );
    on<InAppNotificationCenterMarkedAsRead>(_onMarkedAsRead);
    on<InAppNotificationCenterMarkAllAsRead>(_onMarkAllAsRead);
    on<InAppNotificationCenterMarkOneAsRead>(_onMarkOneAsRead);
    on<InAppNotificationCenterFetchMoreRequested>(
      _onFetchMoreRequested,
      transformer: droppable(),
    );
    on<InAppNotificationCenterReadItemsDeleted>(_onReadItemsDeleted);
  }

  /// The number of notifications to fetch per page.
  static const _notificationsFetchLimit = 10;

  final DataRepository<InAppNotification> _inAppNotificationRepository;
  final AppBloc _appBloc;
  final Logger _logger;

  /// Handles the initial subscription request to fetch notifications for both
  /// tabs concurrently.
  Future<void> _onSubscriptionRequested(
    InAppNotificationCenterSubscriptionRequested event,
    Emitter<InAppNotificationCenterState> emit,
  ) async {
    emit(state.copyWith(status: InAppNotificationCenterStatus.loading));
    final userId = _appBloc.state.user?.id;
    if (userId == null) {
      _logger.warning(
        'Cannot fetch more notifications: user is not logged in.',
      );
      emit(state.copyWith(status: InAppNotificationCenterStatus.failure));
      return;
    }

    try {
      final response = await _fetchNotifications(userId: userId);
      emit(
        state.copyWith(
          status: InAppNotificationCenterStatus.success,
          notifications: response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
        ),
      );
    } catch (error, stackTrace) {
      _handleFetchError(emit, error, stackTrace);
    }
  }

  /// Handles fetching the next page of notifications for the current tab.
  Future<void> _onFetchMoreRequested(
    InAppNotificationCenterFetchMoreRequested event,
    Emitter<InAppNotificationCenterState> emit,
  ) async {
    if (state.status == InAppNotificationCenterStatus.loadingMore ||
        !state.hasMore) {
      return;
    }

    emit(state.copyWith(status: InAppNotificationCenterStatus.loadingMore));

    final userId = _appBloc.state.user?.id;
    if (userId == null) {
      _logger.warning(
        'Cannot fetch more notifications: user is not logged in.',
      );
      emit(state.copyWith(status: InAppNotificationCenterStatus.failure));
      return;
    }

    try {
      final response = await _fetchNotifications(
        userId: userId,
        cursor: state.cursor,
      );

      emit(
        state.copyWith(
          status: InAppNotificationCenterStatus.success,
          notifications: [...state.notifications, ...response.items],
          hasMore: response.hasMore,
          cursor: response.cursor,
        ),
      );
    } catch (error, stackTrace) {
      _handleFetchError(emit, error, stackTrace);
    }
  }

  /// Handles marking a single notification as read.
  Future<void> _onMarkedAsRead(
    InAppNotificationCenterMarkedAsRead event,
    Emitter<InAppNotificationCenterState> emit,
  ) async {
    _logger.info(
      '[InAppNotificationCenterBloc] Marking notification as read: ${event.notificationId}',
    );
    final notification = state.notifications.firstWhereOrNull(
      (n) => n.id == event.notificationId,
    );

    await _markOneAsRead(notification, emit);
  }

  /// Handles marking a single notification as read from a deep-link.
  Future<void> _onMarkOneAsRead(
    InAppNotificationCenterMarkOneAsRead event,
    Emitter<InAppNotificationCenterState> emit,
  ) async {
    _logger.info(
      '[InAppNotificationCenterBloc] Marking one notification as read from external event: ${event.notificationId}',
    );
    final notification = state.notifications.firstWhereOrNull(
      (n) => n.id == event.notificationId,
    );

    if (notification == null) {
      _logger.warning(
        'Attempted to mark a notification as read that does not exist in the '
        'current state: ${event.notificationId}',
      );
      return;
    }

    // If already read, do nothing.
    if (notification.isRead) {
      _logger.fine('Notification ${notification.id} is already read.');
      return;
    }

    await _markOneAsRead(notification, emit);
  }

  /// A shared helper method to mark a single notification as read.
  ///
  /// This is used by both [_onMarkedAsRead] (from the notification center UI)
  /// and [_onMarkOneAsRead] (from a deep-link).
  Future<void> _markOneAsRead(
    InAppNotification? notification,
    Emitter<InAppNotificationCenterState> emit,
  ) async {
    _logger.fine(
      '[InAppNotificationCenterBloc] Executing _markOneAsRead for notification: ${notification?.id}',
    );
    if (notification == null) return;
    final updatedNotification = notification.copyWith(readAt: DateTime.now());

    try {
      await _inAppNotificationRepository.update(
        id: notification.id,
        item: updatedNotification,
        userId: _appBloc.state.user?.id,
      );

      // Update the local state to reflect the change immediately.
      final updatedNotifications = state.notifications
          .map((n) => n.id == notification.id ? updatedNotification : n)
          .toList();

      emit(state.copyWith(notifications: updatedNotifications));

      // Notify the global AppBloc to re-check the unread count.
      _appBloc.add(const AppInAppNotificationMarkedAsRead());
      _logger.info(
        'Successfully marked notification ${notification.id} as read and updated state.',
      );
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
    _logger.info(
      '[InAppNotificationCenterBloc] Marking all unread notifications as read.',
    );
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
      final fullyUpdatedNotifications = state.notifications
          .map((n) => n.isRead ? n : n.copyWith(readAt: now))
          .toList();

      emit(state.copyWith(notifications: fullyUpdatedNotifications));

      // Notify the global AppBloc to clear the unread indicator.
      _appBloc.add(const AppAllInAppNotificationsMarkedAsRead());
      _logger.info(
        'Successfully marked all ${updatedNotifications.length} notifications as read.',
      );
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

  /// Handles deleting all read notifications in the current tab.
  Future<void> _onReadItemsDeleted(
    InAppNotificationCenterReadItemsDeleted event,
    Emitter<InAppNotificationCenterState> emit,
  ) async {
    final userId = _appBloc.state.user!.id;
    try {
      emit(state.copyWith(status: InAppNotificationCenterStatus.deleting));

      final readNotifications = state.notifications
          .where((n) => n.isRead)
          .toList();

      // ignore: unnecessary_null_comparison
      if (readNotifications.isEmpty) {
        _logger.info('No read notifications to delete in the current tab.');
        emit(state.copyWith(status: InAppNotificationCenterStatus.success));
        return;
      }

      final idsToDelete = readNotifications.map((n) => n.id).toList();

      _logger.info('Deleting ${idsToDelete.length} read notifications...');

      await Future.wait(
        idsToDelete.map(
          (id) => _inAppNotificationRepository.delete(id: id, userId: userId),
        ),
      );

      _logger.info('Deletion successful. Refreshing notification list.');

      // After deletion, re-fetch the current tab's data to ensure consistency.
      final response = await _fetchNotifications(userId: userId);

      // Update the state with the refreshed list.
      emit(
        state.copyWith(
          status: InAppNotificationCenterStatus.success,
          notifications: response.items,
          hasMore: response.hasMore,
          cursor: response.cursor,
        ),
      );
    } catch (error, stackTrace) {
      _handleFetchError(emit, error, stackTrace);
    }
  }

  /// A generic method to fetch notifications based on a filter.
  Future<PaginatedResponse<InAppNotification>> _fetchNotifications({
    required String userId,
    String? cursor,
  }) async {
    // This method now simply fetches and returns the data, or throws on error.
    // The responsibility of emitting state is moved to the event handlers.
    return _inAppNotificationRepository.readAll(
      userId: userId,
      pagination: PaginationOptions(
        limit: _notificationsFetchLimit,
        cursor: cursor,
      ),
      sort: [const SortOption('createdAt', SortOrder.desc)],
    );
  }

  /// Centralized error handler for fetch operations.
  void _handleFetchError(
    Emitter<InAppNotificationCenterState> emit,
    Object error,
    StackTrace stackTrace,
  ) {
    _logger.severe('Failed to fetch notifications.', error, stackTrace);
    final httpException = error is HttpException
        ? error
        : UnknownException(error.toString());
    emit(
      state.copyWith(
        status: InAppNotificationCenterStatus.failure,
        error: httpException,
      ),
    );
  }
}
