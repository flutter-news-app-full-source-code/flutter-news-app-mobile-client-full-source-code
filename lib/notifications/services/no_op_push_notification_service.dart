import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/services/push_notification_service.dart';
import 'package:logging/logging.dart';

/// A no-operation implementation of [PushNotificationService].
///
/// This service is used when push notifications are disabled in the remote
/// configuration. It satisfies the interface requirements without performing
/// any actual operations or network calls.
class NoOpPushNotificationService extends PushNotificationService {
  /// Creates an instance of [NoOpPushNotificationService].
  NoOpPushNotificationService({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  Future<void> initialize() async {
    _logger.info('Initializing NoOpPushNotificationService (Notifications disabled).');
  }

  @override
  Future<bool> requestPermission() async {
    _logger.fine('NoOpPushNotificationService: requestPermission called. Returning false.');
    return false;
  }

  @override
  Future<bool> hasPermission() async {
    return false;
  }

  @override
  Future<void> registerDevice({required String userId}) async {}

  @override
  Stream<PushNotificationPayload> get onMessage => const Stream.empty();

  @override
  Stream<PushNotificationPayload> get onMessageOpenedApp => const Stream.empty();

  @override
  Stream<String> get onTokenRefreshed => const Stream.empty();

  @override
  Future<PushNotificationPayload?> get initialMessage async => null;

  @override
  Future<void> close() async {}

  @override
  List<Object?> get props => [_logger];
}
