import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';

/// {@template push_notification_device_repository}
/// A repository that manages [PushNotificationDevice] data.
///
/// This repository abstracts the data source for push notification device
/// registrations, providing a clean interface for the application's business
/// logic to interact with device tokens and their associated user IDs.
/// {@endtemplate}
class PushNotificationDeviceRepository
    extends DataRepository<PushNotificationDevice> {
  /// {@macro push_notification_device_repository}
  PushNotificationDeviceRepository({
    required DataClient<PushNotificationDevice> dataClient,
  }) : super(dataClient: dataClient);

  /// Registers or updates a push notification device with the backend.
  ///
  /// This method is typically called when a user logs in or when a device
  /// token is refreshed. It ensures that the backend has the latest device
  /// token associated with the correct user.
  ///
  /// [device] The [PushNotificationDevice] object containing the user ID,
  /// platform, and provider token.
  Future<void> registerDevice(PushNotificationDevice device) async {
    // The underlying DataClient will handle whether this is a create or update.
    await dataClient.create(item: device, userId: device.userId);
  }
}
