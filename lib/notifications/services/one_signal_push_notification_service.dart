import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/services/push_notification_service.dart';
import 'package:logging/logging.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// A concrete implementation of [PushNotificationService] for OneSignal.
class OneSignalPushNotificationService extends PushNotificationService {
  /// Creates an instance of [OneSignalPushNotificationService].
  OneSignalPushNotificationService({
    required String appId,
    required DataRepository<PushNotificationDevice>
    pushNotificationDeviceRepository,
    required Logger logger,
  }) : _appId = appId,
       _pushNotificationDeviceRepository = pushNotificationDeviceRepository,
       _logger = logger;

  final String _appId;
  final DataRepository<PushNotificationDevice>
  _pushNotificationDeviceRepository;
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
  Future<void> registerDevice({required String userId}) async {
    _logger.info('Registering device for user: $userId');

    try {
      // OneSignal automatically handles token retrieval and storage.
      // We just need to get the OneSignal Player ID (push subscription ID).
      final token = OneSignal.User.pushSubscription.id;

      if (token == null) {
        _logger.warning(
          'Failed to get OneSignal push subscription ID. Cannot register device.',
        );
        return;
      }

      _logger.fine('OneSignal Player ID received: $token');
      // The device ID is now a composite key of userId and provider name to
      // ensure idempotency and align with the backend's delete-then-create
      // pattern.
      final deviceId = '${userId}_${PushNotificationProvider.oneSignal.name}';

      // First, attempt to delete any existing device registration for this user
      // and provider. This ensures a clean state and handles token updates
      // by effectively performing a "delete-then-create".
      try {
        await _pushNotificationDeviceRepository.delete(id: deviceId);
        _logger.info('Existing device registration deleted for $deviceId.');
      } on NotFoundException {
        _logger.info(
          'No existing device registration found for $deviceId. Proceeding with creation.',
        );
      } catch (e, s) {
        _logger.warning(
          'Failed to delete existing device registration for $deviceId. Proceeding with creation anyway. Error: $e',
          e,
          s,
        );
      }

      final newDevice = PushNotificationDevice(
        id: deviceId,
        userId: userId,
        platform: Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android,
        providerTokens: {PushNotificationProvider.oneSignal: token},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _pushNotificationDeviceRepository.create(item: newDevice);
      _logger.info('Device successfully registered with backend.');
    } catch (e, s) {
      _logger.severe('Failed to register device.', e, s);
      rethrow;
    }
  }

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
    await _onTokenRefreshedController.close();
  }

  @override
  List<Object?> get props => [
    _appId,
    _pushNotificationDeviceRepository,
    _logger,
  ];
}
