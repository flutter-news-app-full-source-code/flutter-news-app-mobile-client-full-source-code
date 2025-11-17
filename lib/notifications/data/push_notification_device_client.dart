import 'package:core/core.dart';
import 'package:data_client/data_client.dart';
import 'package:http_client/http_client.dart';
import 'package:logging/logging.dart';

/// {@template push_notification_device_client}
/// A [DataClient] implementation for [PushNotificationDevice] models
/// that interacts with a remote API.
///
/// This client is responsible for sending and receiving [PushNotificationDevice]
/// data to and from the backend API. It uses the provided [HttpClient]
/// to make network requests.
/// {@endtemplate}
class PushNotificationDeviceClient extends DataApi<PushNotificationDevice> {
  /// {@macro push_notification_device_client}
  PushNotificationDeviceClient({
    required HttpClient httpClient,
    required Logger logger,
  }) : super(
         httpClient: httpClient,
         modelName: 'push_notification_device',
         fromJson: PushNotificationDevice.fromJson,
         toJson: (device) => device.toJson(),
         logger: logger,
       );

  /// Overrides the default `create` method to handle device registration.
  ///
  /// This method is designed to be idempotent. If a device with the same
  /// `userId` and `platform` already exists, it should be updated.
  /// The backend is expected to handle the upsert logic.
  @override
  Future<PushNotificationDevice> create({
    required PushNotificationDevice item,
    String? userId,
  }) async {
    // For device registration, we typically use a PUT or POST to an endpoint
    // that handles upserting based on device identifiers.
    return httpClient.put<PushNotificationDevice>(
      '${modelName}s/${item.id}',
      body: item.toJson(),
      fromJson: PushNotificationDevice.fromJson,
    );
  }
}
