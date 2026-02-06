import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/push_notification/providers/push_notification_provider.dart';
import 'package:logging/logging.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// A wrapper around [OneSignal] static methods to facilitate testing.
///
/// This class isolates the static API calls to the OneSignal SDK, allowing
/// them to be mocked in unit tests.
@visibleForTesting
class OneSignalWrapper {
  /// Wraps [OneSignal.Debug.setLogLevel].
  Future<void> setLogLevel(OSLogLevel level) async =>
      OneSignal.Debug.setLogLevel(level);

  /// Wraps [OneSignal.initialize].
  void initialize(String appId) => OneSignal.initialize(appId);

  /// Wraps [OneSignal.User.pushSubscription.addObserver].
  void addPushSubscriptionObserver(
    void Function(OSPushSubscriptionChangedState) listener,
  ) => OneSignal.User.pushSubscription.addObserver(listener);

  /// Wraps [OneSignal.User.pushSubscription.removeObserver].
  void removePushSubscriptionObserver(
    void Function(OSPushSubscriptionChangedState) listener,
  ) => OneSignal.User.pushSubscription.removeObserver(listener);

  /// Wraps [OneSignal.Notifications.addForegroundWillDisplayListener].
  void addForegroundWillDisplayListener(
    void Function(OSNotificationWillDisplayEvent) listener,
  ) => OneSignal.Notifications.addForegroundWillDisplayListener(listener);

  /// Wraps [OneSignal.Notifications.addClickListener].
  void addClickListener(void Function(OSNotificationClickEvent) listener) =>
      OneSignal.Notifications.addClickListener(listener);

  /// Wraps [OneSignal.Notifications.removeForegroundWillDisplayListener].
  void removeForegroundWillDisplayListener(
    void Function(OSNotificationWillDisplayEvent) listener,
  ) => OneSignal.Notifications.removeForegroundWillDisplayListener(listener);

  /// Wraps [OneSignal.Notifications.removeClickListener].
  void removeClickListener(void Function(OSNotificationClickEvent) listener) =>
      OneSignal.Notifications.removeClickListener(listener);

  /// Wraps [OneSignal.Notifications.requestPermission].
  // ignore: avoid_positional_boolean_parameters
  Future<bool> requestPermission(bool fallbackToSettings) =>
      OneSignal.Notifications.requestPermission(fallbackToSettings);

  /// Wraps [OneSignal.Notifications.permission].
  bool get permission => OneSignal.Notifications.permission;

  /// Wraps [OneSignal.User.pushSubscription.id].
  String? get pushSubscriptionId => OneSignal.User.pushSubscription.id;
}

/// A concrete implementation of [PushNotificationProvider] for OneSignal.
class OneSignalPushNotificationService implements PushNotificationProvider {
  /// Creates an instance of [OneSignalPushNotificationService].
  OneSignalPushNotificationService({
    required String appId,
    required Logger logger,
    @visibleForTesting OneSignalWrapper? oneSignalWrapper,
  }) : _appId = appId,
       _logger = logger,
       _oneSignal = oneSignalWrapper ?? OneSignalWrapper();

  final String _appId;
  final Logger _logger;
  final OneSignalWrapper _oneSignal;

  final _onMessageController =
      StreamController<PushNotificationPayload>.broadcast();
  final _onMessageOpenedAppController =
      StreamController<PushNotificationPayload>.broadcast();
  final _onTokenRefreshedController = StreamController<String>.broadcast();

  // Completer to capture the notification that launched the app.
  final Completer<OSNotification?> _initialNotificationCompleter = Completer();

  // Store listener callbacks to remove them on close.
  void Function(OSNotificationWillDisplayEvent)? _foregroundListener;
  void Function(OSNotificationClickEvent)? _clickListener;

  // OneSignal doesn't have a direct equivalent of `getInitialMessage`.
  // We rely on the `setNotificationOpenedHandler`.
  @override
  Future<PushNotificationPayload?> get initialMessage async {
    _logger.fine('Awaiting initial notification completer...');
    final notification = await _initialNotificationCompleter.future;
    if (notification == null) {
      _logger.fine('Initial notification is null.');
      return null;
    }
    _logger.info(
      'Initial notification processed: ${notification.notificationId}',
    );
    return _toPushNotificationPayload(notification);
  }

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
    await _oneSignal.setLogLevel(OSLogLevel.verbose);
    _oneSignal
      ..initialize(_appId)
      // Listen for changes to the push subscription state. If the token (player
      // ID) changes, re-register the device with the new token to ensure
      // continued notification delivery.
      ..addPushSubscriptionObserver((state) async {
        if (state.current.id != state.previous.id &&
            state.current.id != null &&
            state.current.id!.isNotEmpty) {
          _logger.info(
            'OneSignal push subscription ID changed. Emitting new token.',
          );
          _onTokenRefreshedController.add(state.current.id!);
        }
      });

    // Handles notifications received while the app is in the foreground.
    _foregroundListener = (event) {
      _logger.fine(
        'OneSignal foreground message received: ${event.notification.jsonRepresentation()}',
      );
      // Prevent OneSignal from displaying the notification automatically.
      event.preventDefault();
      // We handle it by adding to our stream.
      _handleMessage(event.notification, isOpenedApp: false);
    };
    _oneSignal.addForegroundWillDisplayListener(_foregroundListener!);

    // Handles notifications that are tapped by the user.
    _clickListener = (event) {
      _logger.fine(
        'OneSignal notification clicked: ${event.notification.jsonRepresentation()}',
      );
      // If the completer is not done, this is the initial notification that
      // launched the app. Complete the completer and do NOT forward to the
      // general stream to avoid double handling.
      if (!_initialNotificationCompleter.isCompleted) {
        _logger.fine('Received initial notification click.');
        _initialNotificationCompleter.complete(event.notification);
      } else {
        // Otherwise, it's a background tap, so handle it normally.
        _handleMessage(event.notification, isOpenedApp: true);
      }
    };
    _oneSignal.addClickListener(_clickListener!);

    // After a short delay, if no launch notification has been received,
    // complete the completer with null. This prevents the `initialMessage`
    // getter from hanging indefinitely during a normal app start.
    Future.delayed(const Duration(seconds: 5), () {
      if (!_initialNotificationCompleter.isCompleted) {
        _logger.fine(
          'No initial notification received within 5s timeout, '
          'completing with null.',
        );
        _initialNotificationCompleter.complete(null);
      }
    });

    _logger.info('OneSignalPushNotificationService initialized.');
  }

  @override
  Future<bool> requestPermission() async {
    _logger.info('Requesting push notification permission from user...');
    final accepted = await _oneSignal.requestPermission(true);
    _logger.info('Permission request result: $accepted');
    return accepted;
  }

  @override
  Future<bool> hasPermission() async {
    return _oneSignal.permission;
  }

  @override
  Future<String?> getToken() async {
    // If the token is immediately available, return it. This is the common case
    // for a warm or hot app state.
    final token = _oneSignal.pushSubscriptionId;
    if (token != null && token.isEmpty) {
      return null;
    }
    if (token != null) return token;

    // If the token is not available (e.g., on a cold start), we must wait for
    // the SDK to initialize and provide it via an observer.
    _logger.fine('OneSignal token not immediately available. Waiting...');
    final completer = Completer<String?>();

    // Define the listener that will complete our future.
    late void Function(OSPushSubscriptionChangedState) observer;
    observer = (state) {
      final newId = state.current.id;
      if (newId != null && newId.isNotEmpty && !completer.isCompleted) {
        _logger.fine('OneSignal token received via observer: $newId');
        completer.complete(newId);
        _oneSignal.removePushSubscriptionObserver(observer);
      }
    };

    // Add the listener.
    _oneSignal.addPushSubscriptionObserver(observer);

    // Add a timeout to prevent the app from hanging indefinitely if the
    // OneSignal SDK fails to provide a token.
    try {
      return await completer.future.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      _logger.warning('Timed out after 5s waiting for OneSignal token.');
      // Clean up the listener if it's still attached.
      if (!completer.isCompleted) {
        _oneSignal.removePushSubscriptionObserver(observer);
      }
      return null;
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
    if (_foregroundListener != null) {
      _oneSignal.removeForegroundWillDisplayListener(_foregroundListener!);
    }
    if (_clickListener != null) {
      _oneSignal.removeClickListener(_clickListener!);
    }
  }
}
