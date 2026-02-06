import 'dart:async';

import 'package:core/core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/push_notification/providers/push_notification_provider.dart';
import 'package:logging/logging.dart';

/// A concrete implementation of [PushNotificationProvider] for Firebase Cloud
/// Messaging (FCM).
class FirebasePushNotificationService implements PushNotificationProvider {
  /// Creates an instance of [FirebasePushNotificationService].
  FirebasePushNotificationService({required Logger logger}) : _logger = logger;
  final Logger _logger;

  final _onMessageController =
      StreamController<PushNotificationPayload>.broadcast();
  final _onMessageOpenedAppController =
      StreamController<PushNotificationPayload>.broadcast();
  final _onTokenRefreshedController = StreamController<String>.broadcast();

  @override
  Stream<PushNotificationPayload> get onMessage => _onMessageController.stream;

  @override
  Stream<PushNotificationPayload> get onMessageOpenedApp =>
      _onMessageOpenedAppController.stream;

  @override
  Stream<String> get onTokenRefreshed => _onTokenRefreshedController.stream;

  @override
  Future<void> initialize() async {
    _logger.info('Initializing FirebasePushNotificationService...');

    // Listen for token refresh events from FCM. If the token changes while
    // the app is running, re-register the device with the new token to
    // ensure continued notification delivery.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      _logger.info('FCM token refreshed. Emitting new token.');
      _onTokenRefreshedController.add(newToken);
    });

    // Handle messages that are tapped and open the app from a terminated state.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage, isOpenedApp: true);
    }

    // Handle messages received while the app is in the foreground.
    FirebaseMessaging.onMessage.listen(
      (message) => _handleMessage(message, isOpenedApp: false),
    );

    // Handle messages that are tapped and open the app from a background state.
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _handleMessage(message, isOpenedApp: true),
    );

    _logger.info('FirebasePushNotificationService initialized.');
  }

  void _handleMessage(RemoteMessage message, {required bool isOpenedApp}) {
    _logger.fine(
      'Received Firebase message (isOpenedApp: $isOpenedApp): '
      '${message.toMap()}',
    );
    final payload = _toPushNotificationPayload(message);

    (isOpenedApp ? _onMessageOpenedAppController : _onMessageController).add(
      payload,
    );
  }

  @override
  Future<PushNotificationPayload?> get initialMessage async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return message != null ? _toPushNotificationPayload(message) : null;
  }

  @override
  Future<bool> requestPermission() async {
    _logger.info('Requesting push notification permission from user...');
    final settings = await FirebaseMessaging.instance.requestPermission();
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized;
    _logger.info('Permission request result: ${settings.authorizationStatus}');
    return granted;
  }

  @override
  Future<bool> hasPermission() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  @override
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  /// Converts a Firebase [RemoteMessage] to a generic [PushNotificationPayload].
  PushNotificationPayload _toPushNotificationPayload(RemoteMessage message) {
    final data = message.data;
    return PushNotificationPayload(
      title: message.notification?.title ?? '',
      notificationId: data['notificationId'] as String? ?? '',
      notificationType: PushNotificationSubscriptionDeliveryType.values.byName(
        data['notificationType'] as String? ?? 'breakingOnly',
      ),
      contentType: ContentType.values.byName(
        data['contentType'] as String? ?? 'headline',
      ),
      contentId: data['contentId'] as String? ?? '',
      imageUrl:
          message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl,
    );
  }

  @override
  Future<void> close() async {
    await _onMessageController.close();
    await _onMessageOpenedAppController.close();
    await _onTokenRefreshedController.close();
  }
}
