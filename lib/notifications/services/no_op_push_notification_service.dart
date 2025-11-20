import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
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
  final ValueNotifier<bool> _permissionState = ValueNotifier(false);

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
  Future<void> registerDevice({required String userId}) async {}

  @override
  Stream<PushNotificationPayload> get onMessage => const Stream.empty();

  @override
  Stream<PushNotificationPayload> get onMessageOpenedApp =>
      const Stream.empty();

  @override
  Stream<String> get onTokenRefreshed => const Stream.empty();

  @override
  Future<PushNotificationPayload?> get initialMessage async => null;

  @override
  Future<void> close() async {}

  @override
  List<Object?> get props => [];
}
