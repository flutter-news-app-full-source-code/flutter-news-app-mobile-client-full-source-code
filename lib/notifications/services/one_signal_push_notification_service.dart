import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/services/push_notification_service.dart';
import 'package:logging/logging.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// A concrete implementation of [PushNotificationService] for OneSignal.
class OneSignalPushNotificationService extends PushNotificationService {
  /// Creates an instance of [OneSignalPushNotificationService].
  OneSignalPushNotificationService({
    required String appId,
    required PushNotificationDeviceRepository pushNotificationDeviceRepository,
    required Logger logger,
  }) : _appId = appId,
       _pushNotificationDeviceRepository = pushNotificationDeviceRepository,
       _logger = logger;

  final String _appId;
  final PushNotificationDeviceRepository _pushNotificationDeviceRepository;
  final Logger _logger;

  final _onMessageController = StreamController<PushNotificationPayload>();
  final _onMessageOpenedAppController =
      StreamController<PushNotificationPayload>();

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
  Future<void> initialize() async {
    _logger.info('Initializing OneSignalPushNotificationService...');
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(_appId);

    // Handles notifications received while the app is in the foreground.
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      _logger.fine(
        'OneSignal foreground message received: ${event.notification.jsonRepresentation()}',
      );
      // Prevent OneSignal from displaying the notification automatically.
      event.preventDefault();
      // We handle it by adding to our stream.
      _onMessageController.add(_toPushNotificationPayload(event.notification));
    });

    // Handles notifications that are tapped by the user.
    OneSignal.Notifications.addClickListener((event) {
      _logger.fine(
        'OneSignal notification clicked: ${event.notification.jsonRepresentation()}',
      );
      _onMessageOpenedAppController.add(
        _toPushNotificationPayload(event.notification),
      );
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
    final permission = await OneSignal.Notifications.getPermission();
    return permission ?? false;
  }

  @override
  Future<void> registerDevice({required String userId}) async {
    _logger.info('Registering device for user: $userId');
    try {
      // OneSignal automatically handles token retrieval and storage.
      // We just need to get the OneSignal Player ID (push subscription ID).
      final state = OneSignal.User.pushSubscription;
      final token = state.id;

      if (token == null) {
        _logger.warning(
          'Failed to get OneSignal push subscription ID. Cannot register device.',
        );
        return;
      }

      _logger.fine('OneSignal Player ID received: $token');
      final device = PushNotificationDevice(
        id: token, // Use player ID as a unique ID for the device
        userId: userId,
        platform: Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android,
        providerTokens: {PushNotificationProvider.oneSignal: token},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Use the standard `update` method from the repository for an
      // idempotent "upsert" operation. The player ID is the resource ID.
      await _pushNotificationDeviceRepository.update(id: token, item: device);
      _logger.info('Device successfully registered with backend.');
    } catch (e, s) {
      _logger.severe('Failed to register device.', e, s);
      rethrow;
    }
  }

  /// Converts a OneSignal [OSNotification] to a generic [PushNotificationPayload].
  PushNotificationPayload _toPushNotificationPayload(
    OSNotification osNotification,
  ) {
    // OneSignal's additionalData is where custom payloads are stored.
    final data =
        osNotification.additionalData?.map(
          MapEntry.new,
        ) ??
        {};

    return PushNotificationPayload(
      title: osNotification.title ?? '',
      body: osNotification.body ?? '',
      imageUrl: osNotification.bigPicture,
      data: data,
    );
  }

  @override
  Future<void> close() async {
    await _onMessageController.close();
    await _onMessageOpenedAppController.close();
  }

  @override
  List<Object?> get props => [
    _appId,
    _pushNotificationDeviceRepository,
    _logger,
  ];
}
