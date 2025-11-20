import 'dart:async';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/services/push_notification_service.dart';

/// {@template no_op_push_notification_service}
/// A no-op implementation of [PushNotificationService] used when push
/// notifications are disabled in the remote configuration.
///
/// This prevents null pointer exceptions if other parts of the app attempt
/// to access the service when it's not configured. It provides default,
/// empty implementations for all required methods.
/// {@endtemplate}
class NoOpPushNotificationService extends PushNotificationService {
  /// Creates an instance of [NoOpPushNotificationService].
  NoOpPushNotificationService({
    required DataRepository<InAppNotification> inAppNotificationRepository,
    required List<InAppNotification> inAppNotificationsFixturesData,
    required this.environment,
  }) : _inAppNotificationRepository = inAppNotificationRepository,
       _inAppNotificationsFixturesData = inAppNotificationsFixturesData;
  final ValueNotifier<bool> _permissionState = ValueNotifier(false);
  final _onMessageController =
      StreamController<PushNotificationPayload>.broadcast();

  final DataRepository<InAppNotification> _inAppNotificationRepository;
  final List<InAppNotification> _inAppNotificationsFixturesData;

  /// The current application environment.
  final AppEnvironment environment;

  @override
  Stream<PushNotificationPayload> get onMessage => _onMessageController.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    // Simulate the user granting permission.
    _permissionState.value = true;
    return Future.value(true);
  }

  @override
  Future<bool> hasPermission() async {
    // In the demo environment, this simulates the permission state.
    // It starts as `false` and becomes `true` after `requestPermission` is
    // called, allowing the UI to show a pre-permission dialog on the first
    // attempt.
    return Future.value(_permissionState.value);
  }

  @override
  Future<void> registerDevice({required String userId}) async {
    // In demo mode, simulate receiving a push notification a few seconds
    // after the user "registers" their device (i.e., logs in).
    if (environment != AppEnvironment.demo) {
      return;
    }
    Future.delayed(const Duration(seconds: 10), () {
      if (_inAppNotificationsFixturesData.isEmpty) return;

      // Use the first notification from the fixtures as the simulated push.
      final notificationToSimulate = _inAppNotificationsFixturesData.first;

      // The AppBloc listens to the `onMessage` stream. When a payload is
      // emitted, the BLoC will create a new InAppNotification, save it,
      // and update the UI to show the unread indicator.
      _onMessageController.add(notificationToSimulate.payload);
    });
  }

  @override
  Future<void> close() async {
    await _onMessageController.close();
  }

  @override
  Stream<PushNotificationPayload> get onMessageOpenedApp =>
      const Stream.empty();

  @override
  Stream<String> get onTokenRefreshed => const Stream.empty();

  @override
  Future<PushNotificationPayload?> get initialMessage async => null;

  @override
  List<Object?> get props => [
    _inAppNotificationRepository,
    _inAppNotificationsFixturesData,
    environment,
  ];
}
