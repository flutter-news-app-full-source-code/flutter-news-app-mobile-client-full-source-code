import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/services/push_notification_service.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// A concrete implementation of [PushNotificationService] for Firebase Cloud
/// Messaging (FCM).
class FirebasePushNotificationService implements PushNotificationService {
  /// Creates an instance of [FirebasePushNotificationService].
  FirebasePushNotificationService({
    required DataRepository<PushNotificationDevice>
    pushNotificationDeviceRepository,
    required Logger logger,
  }) : _pushNotificationDeviceRepository = pushNotificationDeviceRepository,
       _logger = logger;

  final DataRepository<PushNotificationDevice>
  _pushNotificationDeviceRepository;
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
  Future<void> registerDevice({required String userId}) async {
    _logger.info('Registering device for user: $userId');

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        _logger.warning('Failed to get FCM token. Cannot register device.');
        return;
      }

      _logger.fine('FCM token received for registration: $token');

      // To ensure a user only receives notifications on their most recently
      // used device, we proactively clear all of their previous device
      // registrations before creating a new one. This prevents "ghost"
      // notifications from being sent to old, unused installations (e.g.,
      // after a user gets a new phone or reinstalls the app).
      try {
        final existingDevices = await _pushNotificationDeviceRepository.readAll(
          userId: userId,
        );

        if (existingDevices.items.isNotEmpty) {
          _logger.info(
            'Found ${existingDevices.items.length} existing device(s) for user $userId. Deleting...',
          );
          await Future.wait(
            existingDevices.items.map(
              (device) => _pushNotificationDeviceRepository.delete(
                id: device.id,
                userId: userId,
              ),
            ),
          );
          _logger.info('All existing devices for user $userId deleted.');
        }
      } catch (e, s) {
        // If the proactive cleanup fails (e.g., due to a temporary network
        // issue), we log the error but do not halt the registration process.
        // The backend's passive, self-healing mechanism (which prunes invalid
        // tokens upon send failure) will eventually clean up any orphaned
        // device records. This ensures that a failure in cleanup does not
        // prevent the user from receiving notifications on their new device.
        _logger.warning(
          'Could not clean up existing devices for user $userId, proceeding with registration. Error: $e',
          e,
          s,
        );
      }

      final newDevice = PushNotificationDevice(
        id: const Uuid().v4(),
        userId: userId,
        platform: Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android,
        providerTokens: {PushNotificationProvider.firebase: token},
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
  }

  @override
  List<Object?> get props => [_pushNotificationDeviceRepository, _logger];

  @override
  bool? get stringify => true;
}
