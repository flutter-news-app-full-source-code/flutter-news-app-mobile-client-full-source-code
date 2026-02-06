import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/push_notification/providers/push_notification_provider.dart';
import 'package:logging/logging.dart';

/// A no-operation implementation of [PushNotificationProvider].
///
/// This service is used when push notifications are disabled in the remote
/// configuration. It satisfies the interface requirements without performing
/// any actual operations or network calls.
class NoOpPushNotificationProvider implements PushNotificationProvider {
  /// Creates an instance of [NoOpPushNotificationProvider].
  NoOpPushNotificationProvider({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  Future<void> initialize() async {
    _logger.info(
      'Initializing NoOpPushNotificationProvider (Notifications disabled).',
    );
  }

  @override
  Future<bool> requestPermission() async {
    _logger.fine(
      'NoOpPushNotificationProvider: requestPermission called. Returning false.',
    );
    return false;
  }

  @override
  Future<bool> hasPermission() async {
    return false;
  }

  @override
  Future<String?> getToken() async => null;

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
}
