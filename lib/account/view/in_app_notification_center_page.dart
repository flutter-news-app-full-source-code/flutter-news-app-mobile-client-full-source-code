import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/in_app_notification_center_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/widgets/in_app_notification_list_item.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/constants/app_layout.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/feed_core/headline_tap_handler.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template in_app_notification_center_page}
/// A page that displays a chronological list of all in-app notifications.
///
/// This page allows users to view their notification history, mark individual
/// notifications as read, and mark all notifications as read.
/// {@endtemplate}
class InAppNotificationCenterPage extends StatefulWidget {
  /// {@macro in_app_notification_center_page}
  const InAppNotificationCenterPage({super.key});

  @override
  State<InAppNotificationCenterPage> createState() =>
      _InAppNotificationCenterPageState();
}

class _InAppNotificationCenterPageState
    extends State<InAppNotificationCenterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          context.read<InAppNotificationCenterBloc>().add(
            InAppNotificationCenterTabChanged(_tabController.index),
          );
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    return BlocBuilder<
      InAppNotificationCenterBloc,
      InAppNotificationCenterState
    >(
      builder: (context, state) {
        final isDeleting =
            state.status == InAppNotificationCenterStatus.deleting;

        return WillPopScope(
          onWillPop: () async => !isDeleting,
          child: Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: Text(l10n.notificationCenterPageTitle),
                  actions: [
                    IconButton(
                      onPressed:
                          !isDeleting &&
                              state.notifications.any((n) => !n.isRead)
                          ? () {
                              context.read<InAppNotificationCenterBloc>().add(
                                const InAppNotificationCenterMarkAllAsRead(),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.done_all),
                      tooltip: l10n.notificationCenterMarkAllAsReadButton,
                    ),
                    IconButton(
                      tooltip: l10n.deleteReadNotificationsButtonTooltip,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      onPressed: !isDeleting && state.hasReadItemsInCurrentTab
                          ? () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    l10n.deleteConfirmationDialogTitle,
                                  ),
                                  content: Text(
                                    l10n.deleteReadNotificationsDialogContent,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(l10n.cancelButtonLabel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(l10n.deleteButtonLabel),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true && context.mounted) {
                                context.read<InAppNotificationCenterBloc>().add(
                                  const InAppNotificationCenterReadItemsDeleted(),
                                );
                              }
                            }
                          : null,
                    ),
                  ],
                  bottom: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: l10n.notificationCenterTabBreakingNews),
                      Tab(text: l10n.notificationCenterTabDigests),
                    ],
                  ),
                ),
                body: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.maxDialogContentWidth,
                    ),
                    child:
                        BlocConsumer<
                          InAppNotificationCenterBloc,
                          InAppNotificationCenterState
                        >(
                          listener: (context, state) {
                            if (state.status ==
                                    InAppNotificationCenterStatus.failure &&
                                state.error != null) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(state.error!.message),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                  ),
                                );
                            }
                          },
                          builder: (context, state) {
                            if (state.status ==
                                    InAppNotificationCenterStatus.loading &&
                                state.breakingNewsNotifications.isEmpty &&
                                state.digestNotifications.isEmpty) {
                              return LoadingStateWidget(
                                icon: Icons.notifications_none_outlined,
                                headline:
                                    l10n.notificationCenterLoadingHeadline,
                                subheadline:
                                    l10n.notificationCenterLoadingSubheadline,
                              );
                            }

                            if (state.status ==
                                    InAppNotificationCenterStatus.failure &&
                                state.breakingNewsNotifications.isEmpty &&
                                state.digestNotifications.isEmpty) {
                              return FailureStateWidget(
                                exception:
                                    state.error ??
                                    OperationFailedException(
                                      l10n.notificationCenterFailureHeadline,
                                    ),
                                onRetry: () {
                                  context.read<InAppNotificationCenterBloc>().add(
                                    const InAppNotificationCenterSubscriptionRequested(),
                                  );
                                },
                              );
                            }

                            return TabBarView(
                              controller: _tabController,
                              children: [
                                _NotificationList(
                                  status: state.status,
                                  notifications:
                                      state.breakingNewsNotifications,
                                  hasMore: state.breakingNewsHasMore,
                                ),
                                _NotificationList(
                                  status: state.status,
                                  notifications: state.digestNotifications,
                                  hasMore: state.digestHasMore,
                                ),
                              ],
                            );
                          },
                        ),
                  ),
                ),
              ),
              if (isDeleting)
                ColoredBox(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationList extends StatefulWidget {
  const _NotificationList({
    required this.notifications,
    required this.hasMore,
    required this.status,
  });

  final InAppNotificationCenterStatus status;
  final List<InAppNotification> notifications;
  final bool hasMore;

  @override
  State<_NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<_NotificationList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final bloc = context.read<InAppNotificationCenterBloc>();
    if (_isBottom &&
        widget.hasMore &&
        bloc.state.status != InAppNotificationCenterStatus.loadingMore) {
      bloc.add(const InAppNotificationCenterFetchMoreRequested());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.98);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    // Show empty state only if not in the middle of an initial load.
    if (widget.notifications.isEmpty &&
        widget.status != InAppNotificationCenterStatus.loading) {
      return InitialStateWidget(
        icon: Icons.notifications_off_outlined,
        headline: l10n.notificationCenterEmptyHeadline,
        subheadline: l10n.notificationCenterEmptySubheadline,
      );
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: widget.hasMore
          ? widget.notifications.length + 1
          : widget.notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= widget.notifications.length) {
          return widget.status == InAppNotificationCenterStatus.loadingMore
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
        }
        final notification = widget.notifications[index];
        return InAppNotificationListItem(
          notification: notification,
          onTap: () async {
            context.read<InAppNotificationCenterBloc>().add(
              InAppNotificationCenterMarkedAsRead(notification.id),
            );

            final payload = notification.payload;
            final contentType = payload.contentType;
            final contentId = payload.contentId;

            if (contentType == ContentType.headline && contentId.isNotEmpty) {
              // Use the handler to fetch the headline by ID and open it.
              await HeadlineTapHandler.handleHeadlineTapById(
                context,
                contentId,
              );
            }
          },
        );
      },
    );
  }
}
