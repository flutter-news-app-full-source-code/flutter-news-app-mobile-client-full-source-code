import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/in_app_notification_center_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/widgets/in_app_notification_list_item.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
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
    _tabController = TabController(length: 3, vsync: this)
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

    return BlocProvider(
      create: (context) => InAppNotificationCenterBloc(
        inAppNotificationRepository: context
            .read<DataRepository<InAppNotification>>(),
        appBloc: context.read<AppBloc>(),
        logger: context.read<Logger>(),
      )..add(const InAppNotificationCenterSubscriptionRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.notificationCenterPageTitle),
          actions: [
            BlocBuilder<
              InAppNotificationCenterBloc,
              InAppNotificationCenterState
            >(
              builder: (context, state) {
                final hasUnread = state.notifications.any((n) => !n.isRead);
                return TextButton(
                  onPressed: hasUnread
                      ? () {
                          context.read<InAppNotificationCenterBloc>().add(
                            const InAppNotificationCenterMarkAllAsRead(),
                          );
                        }
                      : null,
                  child: Text(l10n.notificationCenterMarkAllAsReadButton),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.notificationCenterTabAll),
              Tab(text: l10n.notificationCenterTabBreakingNews),
              Tab(text: l10n.notificationCenterTabDigests),
            ],
          ),
        ),
        body:
            BlocConsumer<
              InAppNotificationCenterBloc,
              InAppNotificationCenterState
            >(
              listener: (context, state) {
                if (state.status == InAppNotificationCenterStatus.failure &&
                    state.error != null) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(state.error!.message),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                }
              },
              builder: (context, state) {
                if (state.status == InAppNotificationCenterStatus.loading) {
                  return LoadingStateWidget(
                    icon: Icons.notifications_none_outlined,
                    headline: l10n.notificationCenterLoadingHeadline,
                    subheadline: l10n.notificationCenterLoadingSubheadline,
                  );
                }

                if (state.status == InAppNotificationCenterStatus.failure) {
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
                    _NotificationList(notifications: state.notifications),
                    _NotificationList(
                      notifications: state.breakingNewsNotifications,
                    ),
                    _NotificationList(notifications: state.digestNotifications),
                  ],
                );
              },
            ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.notifications});

  final List<InAppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    if (notifications.isEmpty) {
      return InitialStateWidget(
        icon: Icons.notifications_off_outlined,
        headline: l10n.notificationCenterEmptyHeadline,
        subheadline: l10n.notificationCenterEmptySubheadline,
      );
    }

    return ListView.separated(
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return InAppNotificationListItem(
          notification: notification,
          onTap: () async {
            context.read<InAppNotificationCenterBloc>().add(
              InAppNotificationCenterMarkedAsRead(notification.id),
            );

            final payload = notification.payload;
            final contentType = payload.data['contentType'] as String?;
            final id = payload.data['headlineId'] as String?;

            if (contentType == 'headline' && id != null) {
              await context
                  .read<InterstitialAdManager>()
                  .onPotentialAdTrigger();

              if (!context.mounted) return;

              await context.pushNamed(
                Routes.globalArticleDetailsName,
                pathParameters: {'id': id},
              );
            }
          },
        );
      },
    );
  }
}
