import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:bloc/bloc.dart';
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
  /// The number of notifications to fetch per page.
  static const _notificationsFetchLimit = 10;

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
    on<InAppNotificationCenterMarkOneAsRead>(_onMarkOneAsRead);
    on<InAppNotificationCenterFetchMoreRequested>(
      _onFetchMoreRequested,
      transformer: droppable(),
    );
  }

  final DataRepository<InAppNotification> _inAppNotificationRepository;
  final AppBloc _appBloc;
  final Logger _logger;

  /// Handles the request to load all notifications for the current user.
  /// This now only fetches the first page of notifications. Subsequent pages
  /// are loaded by [_onFetchMoreRequested].
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
        // Fetch the first page with a defined limit.
        pagination: const PaginationOptions(limit: _notificationsFetchLimit),
        sort: [const SortOption('createdAt', SortOrder.desc)],
      );

      final allNotifications = response.items;

      final breakingNews = <InAppNotification>[];
      final digests = <InAppNotification>[];
      _filterAndAddNotifications(
        notifications: allNotifications,
        breakingNewsList: breakingNews,
        digestList: digests,
      );

      // Since we are fetching all notifications together and then filtering,
      // the pagination cursor and hasMore status will be the same for both lists.
      // This assumes the backend doesn't support filtering by notification type
      // in the query itself.
      final hasMore = response.hasMore;
      final cursor = response.cursor;

      emit(
        state.copyWith(
          status: InAppNotificationCenterStatus.success,
          breakingNewsNotifications: breakingNews,
          digestNotifications: digests,
          breakingNewsHasMore: hasMore,
          breakingNewsCursor: cursor,
          digestHasMore: hasMore,
          digestCursor: cursor,
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

  /// Handles fetching the next page of notifications when the user scrolls.
  Future<void> _onFetchMoreRequested(
    InAppNotificationCenterFetchMoreRequested event,
    Emitter<InAppNotificationCenterState> emit,
  ) async {
    final isBreakingNewsTab = state.currentTabIndex == 0;
    final hasMore = isBreakingNewsTab
        ? state.breakingNewsHasMore
        : state.digestHasMore;

    if (state.status == InAppNotificationCenterStatus.loadingMore || !hasMore) {
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

    final cursor = isBreakingNewsTab
        ? state.breakingNewsCursor
        : state.digestCursor;

    try {
      final response = await _inAppNotificationRepository.readAll(
        userId: userId,
        pagination: PaginationOptions(
          limit: _notificationsFetchLimit,
          cursor: cursor,
        ),
        sort: [const SortOption('createdAt', SortOrder.desc)],
      );

      final newNotifications = response.items;
      final newBreakingNews = <InAppNotification>[];
      final newDigests = <InAppNotification>[];

      _filterAndAddNotifications(
        notifications: newNotifications,
        breakingNewsList: newBreakingNews,
        digestList: newDigests,
      );

      final nextCursor = response.cursor;
      final nextHasMore = response.hasMore;

      emit(
        state.copyWith(
          status: InAppNotificationCenterStatus.success,
          breakingNewsNotifications: [
            ...state.breakingNewsNotifications,
            ...newBreakingNews,
          ],
          digestNotifications: [...state.digestNotifications, ...newDigests],
          breakingNewsHasMore: nextHasMore,
          breakingNewsCursor: nextCursor,
          digestHasMore: nextHasMore,
          digestCursor: nextCursor,
        ),
      );
    } on HttpException catch (e, s) {
      _logger.severe('Failed to fetch more in-app notifications.', e, s);
      emit(
        state.copyWith(status: InAppNotificationCenterStatus.failure, error: e),
      );
    } catch (e, s) {
      _logger.severe(
        'An unexpected error occurred while fetching more in-app notifications.',
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
    if (notification.isRead) return;

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
    if (notification == null) return;
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

  /// A helper method to filter a list of notifications into "Breaking News"
  /// and "Digests" categories and add them to the provided lists.
  void _filterAndAddNotifications({
    required List<InAppNotification> notifications,
    required List<InAppNotification> breakingNewsList,
    required List<InAppNotification> digestList,
  }) {
    for (final n in notifications) {
      final notificationType = n.payload.data['notificationType'] as String?;
      final contentType = n.payload.data['contentType'] as String?;

      if (notificationType ==
              PushNotificationSubscriptionDeliveryType.dailyDigest.name ||
          notificationType ==
              PushNotificationSubscriptionDeliveryType.weeklyRoundup.name ||
          contentType == 'digest') {
        digestList.add(n);
      } else {
        // All other types go to breaking news.
        breakingNewsList.add(n);
      }
    }
  }
}
