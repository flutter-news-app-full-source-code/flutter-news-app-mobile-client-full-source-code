import 'package:core/core.dart';

/// {@template push_notification_provider}
/// Defines the contract for a specific push notification SDK adapter
/// (e.g., Firebase, OneSignal).
///
/// The [PushNotificationManager] uses implementations of this interface to
/// interact with the underlying SDKs.
/// {@endtemplate}
abstract class PushNotificationProvider {
  /// {@macro push_notification_provider}
  const PushNotificationProvider();

  /// Initializes the underlying push notification SDK.
  Future<void> initialize();

  /// Requests permission from the user to display notifications.
  Future<bool> requestPermission();

  /// Checks if the application currently has permission to display notifications.
  Future<bool> hasPermission();

  /// Retrieves the device token (or player ID) from the provider.
  ///
  /// This token is used to register the device with the backend.
  Future<String?> getToken();

  /// A stream of notifications received while the app is in the foreground.
  Stream<PushNotificationPayload> get onMessage;

  /// A stream of notifications that are tapped by the user, opening the app.
  Stream<PushNotificationPayload> get onMessageOpenedApp;

  /// A stream that emits a new device token when it is refreshed by the provider.
  Stream<String> get onTokenRefreshed;

  /// Gets the initial notification that caused the app to open from a
  /// terminated state.
  Future<PushNotificationPayload?> get initialMessage;

  /// Closes any open resources.
  Future<void> close();
}
