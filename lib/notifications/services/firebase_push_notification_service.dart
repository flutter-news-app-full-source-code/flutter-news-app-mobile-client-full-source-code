import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/services/push_notification_service.dart';
import 'package:logging/logging.dart';

/// A concrete implementation of [PushNotificationService] for Firebase Cloud
/// Messaging (FCM).
class FirebasePushNotificationService implements PushNotificationService {
  /// Creates an instance of [FirebasePushNotificationService].
  FirebasePushNotificationService({
    required DataRepository<PushNotificationDevice>
    pushNotificationDeviceRepository,
    required DataRepository<InAppNotification> inAppNotificationRepository,
    required Logger logger,
  }) : _pushNotificationDeviceRepository = pushNotificationDeviceRepository,
       _inAppNotificationRepository = inAppNotificationRepository,
       _logger = logger;

  final DataRepository<PushNotificationDevice>
  _pushNotificationDeviceRepository;
  final DataRepository<InAppNotification> _inAppNotificationRepository;
  final Logger _logger;

  final _onMessageController =
      StreamController<PushNotificationPayload>.broadcast();
  final _onMessageOpenedAppController =
      StreamController<PushNotificationPayload>.broadcast();
  final _onTokenRefreshedController = StreamController<String>.broadcast();
  final _onInAppNotificationReceivedController =
      StreamController<InAppNotification>.broadcast();

  // Store the userId from the last successful registration.
  // This is used to associate incoming notifications with the correct user.
  String? _currentUserId;

  @override
  Stream<PushNotificationPayload> get onMessage => _onMessageController.stream;

  @override
  Stream<PushNotificationPayload> get onMessageOpenedApp =>
      _onMessageOpenedAppController.stream;

  @override
  Stream<String> get onTokenRefreshed => _onTokenRefreshedController.stream;

  @override
  Stream<InAppNotification> get onInAppNotificationReceived =>
      _onInAppNotificationReceivedController.stream;

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

  Future<void> _handleMessage(
    RemoteMessage message, {
    required bool isOpenedApp,
  }) async {
    _logger.fine(
      'Received Firebase message (isOpenedApp: $isOpenedApp): '
      '${message.toMap()}',
    );
    final payload = _toPushNotificationPayload(message);

    // Persist the notification if a user is logged in.
    if (_currentUserId != null) {
      try {
        final newNotification = InAppNotification(
          // Generate a random ID for the notification.
          id: Random().nextInt(999999).toString(),
          userId: _currentUserId!,
          payload: payload,
          createdAt: DateTime.now(),
        );

        final createdNotification = await _inAppNotificationRepository.create(
          item: newNotification,
          userId: _currentUserId,
        );
        _onInAppNotificationReceivedController.add(createdNotification);
      } catch (e, s) {
        _logger.severe('Failed to persist in-app notification.', e, s);
      }
    }

    if (isOpenedApp) {
      _onMessageOpenedAppController.add(payload);
    } else {
      _onMessageController.add(payload);
    }
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
  Future<void> registerDevice({required String userId}) async {
    _logger.info('Registering device for user: $userId');
    // Store the userId to be used for persisting incoming notifications.
    _currentUserId = userId;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        _logger.warning('Failed to get FCM token. Cannot register device.');
        return;
      }

      _logger.fine('FCM token received for registration: $token');
      // The device ID is now a composite key of userId and provider name to
      // ensure idempotency and align with the backend's delete-then-create
      // pattern.
      final deviceId = '${userId}_${PushNotificationProvider.firebase.name}';

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
        providerTokens: {PushNotificationProvider.firebase: token},
        // Timestamps are managed by the backend, but we provide initial values.
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _pushNotificationDeviceRepository.create(item: newDevice);
      _logger.info('Device successfully registered with backend.');
    } catch (e, s) {
      _logger.severe('Failed to register device.', e, s);
      // Re-throwing allows the caller (e.g., AppBloc) to know about the failure.
      rethrow;
    }
  }

  /// Converts a Firebase [RemoteMessage] to a generic [PushNotificationPayload].
  PushNotificationPayload _toPushNotificationPayload(RemoteMessage message) {
    return PushNotificationPayload(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      imageUrl:
          message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl,
      data: message.data,
    );
  }

  @override
  Future<void> close() async {
    await _onMessageController.close();
    await _onMessageOpenedAppController.close();
    await _onTokenRefreshedController.close();
    await _onInAppNotificationReceivedController.close();
  }

  @override
  List<Object?> get props => [
    _pushNotificationDeviceRepository,
    _inAppNotificationRepository,
    _logger,
  ];

  @override
  bool? get stringify => true;
}
