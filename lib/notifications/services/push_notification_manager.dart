import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/providers/push_notification_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/services/push_notification_service.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// {@template push_notification_manager}
/// The concrete implementation of [PushNotificationService].
///
/// This manager handles the business logic for push notifications, including:
/// - Checking [PushNotificationConfig] to enable/disable the feature.
/// - Selecting the active [PushNotificationProvider] (Firebase vs OneSignal).
/// - Managing device registration with the [DataRepository].
/// - Forwarding notification streams from the provider to the app.
/// {@endtemplate}
class PushNotificationManager implements PushNotificationService {
  /// {@macro push_notification_manager}
  PushNotificationManager({
    required PushNotificationConfig? initialConfig,
    required Map<PushNotificationProviders, PushNotificationProvider> providers,
    required PushNotificationProvider noOpProvider,
    required DataRepository<PushNotificationDevice>
    pushNotificationDeviceRepository,
    required Logger logger,
  }) : _config = initialConfig,
       _providers = providers,
       _noOpProvider = noOpProvider,
       _pushNotificationDeviceRepository = pushNotificationDeviceRepository,
       _logger = logger;

  final PushNotificationConfig? _config;
  final Map<PushNotificationProviders, PushNotificationProvider> _providers;
  final PushNotificationProvider _noOpProvider;
  final DataRepository<PushNotificationDevice>
  _pushNotificationDeviceRepository;
  final Logger _logger;

  // Broadcast streams to forward events from the active provider to the app.
  final _onMessageController =
      StreamController<PushNotificationPayload>.broadcast();
  final _onMessageOpenedAppController =
      StreamController<PushNotificationPayload>.broadcast();
  final _onTokenRefreshedController = StreamController<String>.broadcast();

  StreamSubscription<PushNotificationPayload>? _providerMessageSub;
  StreamSubscription<PushNotificationPayload>? _providerOpenedAppSub;
  StreamSubscription<String>? _providerTokenRefreshSub;

  @override
  Stream<PushNotificationPayload> get onMessage => _onMessageController.stream;

  @override
  Stream<PushNotificationPayload> get onMessageOpenedApp =>
      _onMessageOpenedAppController.stream;

  @override
  Stream<String> get onTokenRefreshed => _onTokenRefreshedController.stream;

  /// The currently active provider based on configuration.
  /// Returns [_noOpProvider] if the feature is disabled or provider is missing.
  PushNotificationProvider get _activeProvider {
    if (_config == null || !_config.enabled) return _noOpProvider;
    return _providers[_config.primaryProvider] ?? _noOpProvider;
  }

  @override
  Future<void> initialize() async {
    _logger.info('PushNotificationManager: Initializing...');
    await _activeProvider.initialize();
    _subscribeToProviderStreams(_activeProvider);
    _logger.info(
      'PushNotificationManager: Initialized with ${_config?.primaryProvider}.',
    );
  }

  void _subscribeToProviderStreams(PushNotificationProvider provider) {
    _providerMessageSub?.cancel();
    _providerOpenedAppSub?.cancel();
    _providerTokenRefreshSub?.cancel();

    _providerMessageSub = provider.onMessage.listen(_onMessageController.add);
    _providerOpenedAppSub = provider.onMessageOpenedApp.listen(
      _onMessageOpenedAppController.add,
    );
    _providerTokenRefreshSub = provider.onTokenRefreshed.listen(
      _onTokenRefreshedController.add,
    );
  }

  @override
  Future<bool> requestPermission() async {
    return _activeProvider.requestPermission();
  }

  @override
  Future<bool> hasPermission() async {
    return _activeProvider.hasPermission();
  }

  @override
  Future<void> registerDevice({required String userId}) async {
    _logger.info('Registering device for user: $userId');

    try {
      final token = await _activeProvider.getToken();
      if (token == null) {
        _logger.fine(
          'No token returned from provider (likely NoOp). Skipping registration.',
        );
        return;
      }

      // Proactive cleanup of old devices for this user
      try {
        final existingDevices = await _pushNotificationDeviceRepository.readAll(
          userId: userId,
        );
        if (existingDevices.items.isNotEmpty) {
          await Future.wait(
            existingDevices.items.map(
              (device) => _pushNotificationDeviceRepository.delete(
                id: device.id,
                userId: userId,
              ),
            ),
          );
        }
      } catch (e, s) {
        _logger.warning('Device cleanup failed, proceeding.', e, s);
      }

      final newDevice = PushNotificationDevice(
        id: const Uuid().v4(),
        userId: userId,
        platform: Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android,
        providerTokens: {_config!.primaryProvider: token},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _pushNotificationDeviceRepository.create(item: newDevice);
      _logger.info('Device successfully registered.');
    } catch (e, s) {
      _logger.severe('Failed to register device.', e, s);
      rethrow;
    }
  }

  @override
  Future<PushNotificationPayload?> get initialMessage async {
    return _activeProvider.initialMessage;
  }

  @override
  Future<void> close() async {
    await _providerMessageSub?.cancel();
    await _providerOpenedAppSub?.cancel();
    await _providerTokenRefreshSub?.cancel();
    await _onMessageController.close();
    await _onMessageOpenedAppController.close();
    await _onTokenRefreshedController.close();
    for (final provider in _providers.values) {
      await provider.close();
    }
  }
}
