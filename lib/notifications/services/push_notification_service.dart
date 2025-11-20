import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

/// {@template push_notification_service}
/// An abstract class defining the contract for a push notification service.
///
/// This service is responsible for initializing the notification provider,
/// handling permissions, managing device tokens, and processing incoming
/// notification messages. It extends [Equatable] to allow for easy comparison
/// in testing environments.
/// {@endtemplate}
abstract class PushNotificationService extends Equatable {
  /// Initializes the push notification service.
  ///
  /// This method should be called once during application startup to configure
  /// the underlying provider (e.g., Firebase, OneSignal) and set up message
  /// listeners.
  Future<void> initialize();

  /// Requests permission from the user to display notifications.
  ///
  /// Returns `true` if permission is granted, `false` otherwise.
  Future<bool> requestPermission();

  /// Checks if the application currently has permission to display
  /// notifications.
  ///
  /// Returns `true` if permission has been granted, `false` otherwise.
  Future<bool> hasPermission();

  /// Registers the device with the backend for a specific user.
  ///
  /// This method retrieves the device token from the provider and sends it
  /// to the application's backend to associate it with the given [userId]. The
  /// concrete implementation is responsible for obtaining the token.
  Future<void> registerDevice({required String userId});

  /// A stream of notifications received while the app is in the foreground.
  ///
  /// The payload contains the notification's content and any associated data.
  Stream<PushNotificationPayload> get onMessage;

  /// A stream of notifications that are tapped by the user, opening the app.
  ///
  /// This handles notifications tapped when the app is in the background or
  /// terminated.
  Stream<PushNotificationPayload> get onMessageOpenedApp;

  /// A stream that emits a new device token when it is refreshed by the
  /// underlying push notification provider.
  ///
  /// This is used by the AppBloc to trigger device re-registration.
  Stream<String> get onTokenRefreshed;

  /// Gets the initial notification that caused the app to open from a
  /// terminated state.
  ///
  /// Returns the [PushNotificationPayload] if the app was opened by a
  /// notification, otherwise returns `null`.
  Future<PushNotificationPayload?> get initialMessage;

  /// Closes any open resources, such as stream controllers.
  ///
  /// This should be called when the service is no longer needed to prevent
  /// memory leaks.
  Future<void> close();
}
