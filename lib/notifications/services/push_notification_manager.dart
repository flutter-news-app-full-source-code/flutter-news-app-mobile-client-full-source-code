import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/providers/push_notification_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/services/push_notification_service.dart';
import 'package:kv_storage_service/kv_storage_service.dart';
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
    required KVStorageService storageService,
    required Logger logger,
  }) : _config = initialConfig,
       _providers = providers,
       _noOpProvider = noOpProvider,
       _pushNotificationDeviceRepository = pushNotificationDeviceRepository,
       _storageService = storageService,
       _logger = logger;

  final PushNotificationConfig? _config;
  final Map<PushNotificationProviders, PushNotificationProvider> _providers;
  final PushNotificationProvider _noOpProvider;
  final DataRepository<PushNotificationDevice>
  _pushNotificationDeviceRepository;
  final KVStorageService _storageService;
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

  /// The storage key for the active provider's token.
  StorageKey? get _providerTokenStorageKey {
    if (_config == null) return null;
    switch (_config.primaryProvider) {
      case PushNotificationProviders.firebase:
        return StorageKey.fcmToken;
      case PushNotificationProviders.oneSignal:
        return StorageKey.oneSignalPlayerId;
    }
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
    _logger.info(
      '[PushNotificationManager] Attempting to register device for user: $userId',
    );
    try {
      final currentToken = await _activeProvider.getToken();
      if (currentToken == null) {
        _logger.fine(
          '[PushNotificationManager] No token returned from provider (likely NoOp). Aborting registration.',
        );
        return;
      }

      final storageKey = _providerTokenStorageKey;
      if (storageKey == null) {
        _logger.warning(
          '[PushNotificationManager] No storage key for active provider. Aborting.',
        );
        return;
      }

      final lastRegisteredToken = await _storageService.readString(
        key: storageKey.stringValue,
      );

      // STEP 1: Check if the token has changed. If not, do nothing.
      // This is a crucial optimization to prevent unnecessary API calls on every app start.
      if (currentToken == lastRegisteredToken) {
        _logger.info(
          '[PushNotificationManager] Push token has not changed. Skipping registration.',
        );
        return;
      }

      _logger.info(
        '[PushNotificationManager] New or updated push token found. Proceeding with registration.',
      );

      // --- Resilient "Delete-Then-Create" Pattern ---
      // The backend API contract forbids updating a PushNotificationDevice.
      // The correct pattern is to delete any old registration and create a new one.
      // This implementation makes that pattern resilient to failures.

      // STEP 2: Attempt to delete any existing registrations for this user and platform.
      try {
        final platform = Platform.isIOS
            ? DevicePlatform.ios
            : DevicePlatform.android;
        final existingDevices = await _pushNotificationDeviceRepository.readAll(
          userId: userId,
          filter: {'platform': platform.name},
        );

        if (existingDevices.items.isNotEmpty) {
          _logger.info(
            '[PushNotificationManager] Found ${existingDevices.items.length} existing device(s) to delete.',
          );
          await Future.wait(
            existingDevices.items.map(
              (device) => _pushNotificationDeviceRepository.delete(
                id: device.id,
                userId: userId,
              ),
            ),
          );
          _logger.info(
            '[PushNotificationManager] Successfully deleted existing device(s).',
          );
        }
      } catch (e, s) {
        // IMPORTANT: We log the deletion failure but continue.
        // It's better to have a temporary duplicate registration than to fail
        // the entire process. The backend's self-healing mechanism (purging
        // invalid tokens) will eventually clean up any duplicates.
        _logger.warning(
          '[PushNotificationManager] Failed to delete existing device(s), but proceeding with creation.',
          e,
          s,
        );
      }

      // STEP 3: Create the new device registration.
      final newDevice = PushNotificationDevice(
        id: const Uuid().v4(),
        userId: userId,
        platform: Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android,
        providerTokens: {_config!.primaryProvider: currentToken},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _pushNotificationDeviceRepository.create(
        item: newDevice,
        userId: userId,
      );
      _logger.info(
        '[PushNotificationManager] Successfully created new device registration.',
      );

      // STEP 4: ONLY on successful creation, persist the new token locally.
      // This is the key to resilience. If the create step fails, the old token
      // remains in storage, ensuring this entire process is retried on the
      // next app start or token refresh.
      await _storageService.writeString(
        key: storageKey.stringValue,
        value: currentToken,
      );
      _logger.fine(
        '[PushNotificationManager] Persisted new token to local storage.',
      );
    } catch (e, s) {
      _logger.severe(
        '[PushNotificationManager] Failed to register device.',
        e,
        s,
      );
      // IMPORTANT: Do NOT rethrow the exception.
      // Push notification registration is a non-critical background task.
      // Rethrowing here could crash the AppBloc or the entire app. The error
      // is logged, and because the local token was not updated on failure,
      // the process will be retried automatically on the next app start.
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
