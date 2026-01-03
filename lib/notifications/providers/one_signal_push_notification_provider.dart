import 'dart:async';

import 'package:core/core.dart' hide PushNotificationProvider;
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/providers/push_notification_provider.dart';
import 'package:logging/logging.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// A concrete implementation of [PushNotificationProvider] for OneSignal.
class OneSignalPushNotificationService implements PushNotificationProvider {
  /// Creates an instance of [OneSignalPushNotificationService].
  OneSignalPushNotificationService({
    required String appId,
    required Logger logger,
  }) : _appId = appId,
       _logger = logger;

  final String _appId;
  final Logger _logger;

  final _onMessageController =
      StreamController<PushNotificationPayload>.broadcast();
  final _onMessageOpenedAppController =
      StreamController<PushNotificationPayload>.broadcast();
  final _onTokenRefreshedController = StreamController<String>.broadcast();

  // OneSignal doesn't have a direct equivalent of `getInitialMessage`.
  // We rely on the `setNotificationOpenedHandler`.
  @override
  Future<PushNotificationPayload?> get initialMessage async => null;

  @override
  Stream<PushNotificationPayload> get onMessage => _onMessageController.stream;

  @override
  Stream<PushNotificationPayload> get onMessageOpenedApp =>
      _onMessageOpenedAppController.stream;

  @override
  Stream<String> get onTokenRefreshed => _onTokenRefreshedController.stream;

  @override
  Future<void> initialize() async {
    _logger.info('Initializing OneSignalPushNotificationService...');
    await OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(_appId);

    // Listen for changes to the push subscription state. If the token (player
    // ID) changes, re-register the device with the new token to ensure
    // continued notification delivery.
    OneSignal.User.pushSubscription.addObserver((state) async {
      if (state.current.id != state.previous.id && state.current.id != null) {
        _logger.info(
          'OneSignal push subscription ID changed. Emitting new token.',
        );
        _onTokenRefreshedController.add(state.current.id!);
      }
    });

    // Handles notifications received while the app is in the foreground.
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      _logger.fine(
        'OneSignal foreground message received: ${event.notification.jsonRepresentation()}',
      );
      // Prevent OneSignal from displaying the notification automatically.
      event.preventDefault();
      // We handle it by adding to our stream.
      _handleMessage(event.notification, isOpenedApp: false);
    });

    // Handles notifications that are tapped by the user.
    OneSignal.Notifications.addClickListener((event) {
      _logger.fine(
        'OneSignal notification clicked: ${event.notification.jsonRepresentation()}',
      );
      _handleMessage(event.notification, isOpenedApp: true);
    });

    _logger.info('OneSignalPushNotificationService initialized.');
  }

  @override
  Future<bool> requestPermission() async {
    _logger.info('Requesting push notification permission from user...');
    final accepted = await OneSignal.Notifications.requestPermission(true);
    _logger.info('Permission request result: $accepted');
    return accepted;
  }

  @override
  Future<bool> hasPermission() async {
    return OneSignal.Notifications.permission;
  }

  @override
  Future<String?> getToken() async => OneSignal.User.pushSubscription.id;

  void _handleMessage(
    OSNotification notification, {
    required bool isOpenedApp,
  }) {
    final payload = _toPushNotificationPayload(notification);

    (isOpenedApp ? _onMessageOpenedAppController : _onMessageController).add(
      payload,
    );
  }

  /// Converts a OneSignal [OSNotification] to a generic [PushNotificationPayload].
  PushNotificationPayload _toPushNotificationPayload(
    OSNotification osNotification,
  ) {
    // OneSignal's additionalData is where custom payloads are stored.
    final data = osNotification.additionalData?.map(MapEntry.new) ?? {};

    return PushNotificationPayload(
      title: osNotification.title ?? data['title'] as String? ?? '',
      notificationId: data['notificationId'] as String? ?? '',
      notificationType: PushNotificationSubscriptionDeliveryType.values.byName(
        data['notificationType'] as String? ?? 'breakingOnly',
      ),
      contentType: ContentType.values.byName(
        data['contentType'] as String? ?? 'headline',
      ),
      contentId: data['contentId'] as String? ?? '',
      imageUrl: osNotification.bigPicture,
    );
  }

  @override
  Future<void> close() async {
    await _onMessageController.close();
    await _onMessageOpenedAppController.close();
    await _onTokenRefreshedController.close();
  }
}
