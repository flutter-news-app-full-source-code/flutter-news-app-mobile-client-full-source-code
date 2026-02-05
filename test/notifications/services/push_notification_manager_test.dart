import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/providers/push_notification_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/services/push_notification_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kv_storage_service/kv_storage_service.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockPushNotificationConfig extends Mock
    implements PushNotificationConfig {}

class MockPushNotificationProvider extends Mock
    implements PushNotificationProvider {}

class MockDataRepository<T> extends Mock implements DataRepository<T> {}

class MockKVStorageService extends Mock implements KVStorageService {}

class MockLogger extends Mock implements Logger {}

class MockPushNotificationDevice extends Mock
    implements PushNotificationDevice {}

class FakePushNotificationDevice extends Fake
    implements PushNotificationDevice {}

void main() {
  group('PushNotificationManager', () {
    setUpAll(() {
      registerFallbackValue(FakePushNotificationDevice());
    });

    late PushNotificationManager pushNotificationManager;
    late PushNotificationConfig mockConfig;
    late PushNotificationProvider mockProvider;
    late DataRepository<PushNotificationDevice> mockRepository;
    late KVStorageService mockStorageService;
    late Logger mockLogger;

    late StreamController<PushNotificationPayload> onMessageController;
    late StreamController<PushNotificationPayload> onMessageOpenedAppController;
    late StreamController<String> onTokenRefreshedController;

    const userId = 'user-123';
    const deviceToken = 'test-token';
    final storageKey = Platform.isIOS
        ? StorageKey.oneSignalPlayerId
        : StorageKey.fcmToken;

    setUp(() {
      mockConfig = MockPushNotificationConfig();
      mockProvider = MockPushNotificationProvider();
      mockRepository = MockDataRepository<PushNotificationDevice>();
      mockStorageService = MockKVStorageService();
      mockLogger = MockLogger();

      onMessageController =
          StreamController<PushNotificationPayload>.broadcast();
      onMessageOpenedAppController =
          StreamController<PushNotificationPayload>.broadcast();
      onTokenRefreshedController = StreamController<String>.broadcast();

      // Mock default behaviors
      when(() => mockConfig.enabled).thenReturn(true);
      when(
        () => mockConfig.primaryProvider,
      ).thenReturn(PushNotificationProviders.firebase);
      when(() => mockProvider.getToken()).thenAnswer((_) async => deviceToken);
      when(() => mockProvider.initialize()).thenAnswer((_) async {});
      when(
        () => mockProvider.onMessage,
      ).thenAnswer((_) => onMessageController.stream);
      when(
        () => mockProvider.onMessageOpenedApp,
      ).thenAnswer((_) => onMessageOpenedAppController.stream);
      when(
        () => mockProvider.onTokenRefreshed,
      ).thenAnswer((_) => onTokenRefreshedController.stream);
      when(() => mockProvider.close()).thenAnswer((_) async {});

      when(
        () => mockStorageService.readString(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorageService.writeString(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockRepository.create(
          item: any(named: 'item'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => MockPushNotificationDevice());
      when(
        () => mockRepository.readAll(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer(
        (_) async =>
            const PaginatedResponse(items: [], cursor: null, hasMore: false),
      );

      pushNotificationManager = PushNotificationManager(
        initialConfig: mockConfig,
        providers: {PushNotificationProviders.firebase: mockProvider},
        noOpProvider: MockPushNotificationProvider(),
        pushNotificationDeviceRepository: mockRepository,
        storageService: mockStorageService,
        logger: mockLogger,
      );
    });

    tearDown(() {
      onMessageController.close();
      onMessageOpenedAppController.close();
      onTokenRefreshedController.close();
      pushNotificationManager.close();
    });

    test(
      'registerDevice skips registration if token and userId have not changed',
      () async {
        // Arrange
        final lastRegistration = {'token': deviceToken, 'userId': userId};
        when(
          () => mockStorageService.readString(key: storageKey.stringValue),
        ).thenAnswer((_) async => jsonEncode(lastRegistration));

        // Act
        await pushNotificationManager.registerDevice(userId: userId);

        // Assert
        verify(
          () => mockLogger.info(
            any(
              that: contains(
                'Push token and user ID have not changed. Skipping registration.',
              ),
            ),
          ),
        ).called(1);
        verifyNever(
          () => mockRepository.create(
            item: any(named: 'item'),
            userId: any(named: 'userId'),
          ),
        );
      },
    );

    test('registerDevice proceeds if token is new', () async {
      // Arrange
      final lastRegistration = {'token': 'old-token', 'userId': userId};
      when(
        () => mockStorageService.readString(key: storageKey.stringValue),
      ).thenAnswer((_) async => jsonEncode(lastRegistration));

      // Act
      await pushNotificationManager.registerDevice(userId: userId);

      // Assert
      verify(
        () => mockRepository.create(
          item: any(named: 'item'),
          userId: userId,
        ),
      ).called(1);
      verify(
        () => mockStorageService.writeString(
          key: storageKey.stringValue,
          value: jsonEncode({'token': deviceToken, 'userId': userId}),
        ),
      ).called(1);
    });

    test('registerDevice proceeds if userId is new (account switch)', () async {
      // Arrange
      const newUserId = 'user-456';
      final lastRegistration = {'token': deviceToken, 'userId': userId};
      when(
        () => mockStorageService.readString(key: storageKey.stringValue),
      ).thenAnswer((_) async => jsonEncode(lastRegistration));

      // Act
      await pushNotificationManager.registerDevice(userId: newUserId);

      // Assert
      verify(
        () => mockRepository.create(
          item: any(named: 'item'),
          userId: newUserId,
        ),
      ).called(1);
      verify(
        () => mockStorageService.writeString(
          key: storageKey.stringValue,
          value: jsonEncode({'token': deviceToken, 'userId': newUserId}),
        ),
      ).called(1);
    });

    test(
      'registerDevice proceeds for a new user with no previous registration',
      () async {
        // Arrange
        when(
          () => mockStorageService.readString(key: storageKey.stringValue),
        ).thenAnswer((_) async => null);

        // Act
        await pushNotificationManager.registerDevice(userId: userId);

        // Assert
        verify(
          () => mockRepository.create(
            item: any(named: 'item'),
            userId: userId,
          ),
        ).called(1);
        verify(
          () => mockStorageService.writeString(
            key: storageKey.stringValue,
            value: jsonEncode({'token': deviceToken, 'userId': userId}),
          ),
        ).called(1);
      },
    );

    test(
      'registerDevice deletes existing device before creating a new one',
      () async {
        // Arrange
        final existingDevice = PushNotificationDevice(
          id: 'existing-device-id',
          userId: userId,
          platform: DevicePlatform.android,
          providerTokens: const {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        when(
          () => mockRepository.readAll(
            userId: userId,
            filter: any(named: 'filter'),
          ),
        ).thenAnswer(
          (_) async => PaginatedResponse(
            items: [existingDevice],
            cursor: null,
            hasMore: false,
          ),
        );
        when(
          () => mockRepository.delete(id: existingDevice.id, userId: userId),
        ).thenAnswer((_) async {});

        // Act
        await pushNotificationManager.registerDevice(userId: userId);

        // Assert
        verify(
          () => mockRepository.delete(id: existingDevice.id, userId: userId),
        ).called(1);
        verify(
          () => mockRepository.create(
            item: any(named: 'item'),
            userId: userId,
          ),
        ).called(1);
      },
    );

    test(
      'registerDevice does not update local storage if creation fails',
      () async {
        // Arrange
        final exception = Exception('API creation failed');
        when(
          () => mockRepository.create(
            item: any(named: 'item'),
            userId: any(named: 'userId'),
          ),
        ).thenThrow(exception);

        // Act
        await pushNotificationManager.registerDevice(userId: userId);

        // Assert
        verify(
          () => mockLogger.severe(
            any(that: contains('Failed to register device.')),
            exception,
            any(),
          ),
        ).called(1);
        verifyNever(
          () => mockStorageService.writeString(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        );
      },
    );

    test('registerDevice aborts if provider returns null token', () async {
      // Arrange
      when(() => mockProvider.getToken()).thenAnswer((_) async => null);

      // Act
      await pushNotificationManager.registerDevice(userId: userId);

      // Assert
      verify(
        () => mockLogger.fine(
          any(that: contains('No token returned from provider')),
        ),
      ).called(1);
      verifyNever(
        () => mockRepository.create(
          item: any(named: 'item'),
          userId: any(named: 'userId'),
        ),
      );
    });

    group('Initialization & Streams', () {
      test(
        'initialize initializes provider and subscribes to streams',
        () async {
          // Act
          await pushNotificationManager.initialize();

          // Assert
          verify(() => mockProvider.initialize()).called(1);
          verify(() => mockProvider.onMessage).called(1);
          verify(() => mockProvider.onMessageOpenedApp).called(1);
          verify(() => mockProvider.onTokenRefreshed).called(1);
        },
      );

      test('forwards onMessage events from provider', () async {
        // Arrange
        await pushNotificationManager.initialize();
        const payload = PushNotificationPayload(
          title: 'Test',
          notificationId: '1',
          notificationType:
              PushNotificationSubscriptionDeliveryType.breakingOnly,
          contentType: ContentType.headline,
          contentId: '123',
        );

        // Act & Assert
        unawaited(
          expectLater(pushNotificationManager.onMessage, emits(payload)),
        );
        onMessageController.add(payload);
      });

      test('forwards onTokenRefreshed events from provider', () async {
        // Arrange
        await pushNotificationManager.initialize();
        const newToken = 'new-token-123';

        // Act & Assert
        unawaited(
          expectLater(
            pushNotificationManager.onTokenRefreshed,
            emits(newToken),
          ),
        );
        onTokenRefreshedController.add(newToken);
      });
    });

    group('Delegation', () {
      test('requestPermission delegates to provider', () async {
        // Arrange
        when(
          () => mockProvider.requestPermission(),
        ).thenAnswer((_) async => true);

        // Act
        final result = await pushNotificationManager.requestPermission();

        // Assert
        verify(() => mockProvider.requestPermission()).called(1);
        expect(result, isTrue);
      });

      test('hasPermission delegates to provider', () async {
        // Arrange
        when(() => mockProvider.hasPermission()).thenAnswer((_) async => false);

        // Act
        final result = await pushNotificationManager.hasPermission();

        // Assert
        verify(() => mockProvider.hasPermission()).called(1);
        expect(result, isFalse);
      });

      test('initialMessage delegates to provider', () async {
        // Arrange
        const payload = PushNotificationPayload(
          title: 'Init',
          notificationId: '1',
          notificationType:
              PushNotificationSubscriptionDeliveryType.breakingOnly,
          contentType: ContentType.headline,
          contentId: '123',
        );
        when(
          () => mockProvider.initialMessage,
        ).thenAnswer((_) async => payload);

        // Act
        final result = await pushNotificationManager.initialMessage;

        // Assert
        verify(() => mockProvider.initialMessage).called(1);
        expect(result, payload);
      });
    });

    test('close closes provider', () async {
      // Act
      await pushNotificationManager.close();

      // Assert
      verify(() => mockProvider.close()).called(1);
    });
  });
}
