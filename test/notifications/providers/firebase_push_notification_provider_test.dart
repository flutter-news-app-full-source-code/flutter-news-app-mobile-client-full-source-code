import 'dart:async';

import 'package:core/core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart'
    as firebase_core_test;
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/providers/firebase_push_notification_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mocks for dependencies
class MockFirebaseMessagingPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FirebaseMessagingPlatform {}

class MockLogger extends Mock implements Logger {}

class MockFirebaseApp extends Mock implements FirebaseApp {}

class FakeFirebaseApp extends Fake implements FirebaseApp {}

// Helper function to mock Firebase.initializeApp()
void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  firebase_core_test.setupFirebaseCoreMocks();
}

void main() {
  group('FirebasePushNotificationService', () {
    late FirebasePushNotificationService provider;
    late MockFirebaseMessagingPlatform mockFirebaseMessaging;
    late MockLogger mockLogger;

    // This setup runs once for the entire group, ensuring the Firebase mock
    // is in place before any tests run.
    setUpAll(() async {
      registerFallbackValue(FakeFirebaseApp());
      setupFirebaseCoreMocks();
      // Initialize the mock platform once to handle Singleton caching in FirebaseMessaging
      mockFirebaseMessaging = MockFirebaseMessagingPlatform();
      FirebaseMessagingPlatform.instance = mockFirebaseMessaging;
      await Firebase.initializeApp();
    });

    setUp(() {
      reset(mockFirebaseMessaging);
      mockLogger = MockLogger();

      provider = FirebasePushNotificationService(logger: mockLogger);

      // Mock default behaviors for all methods used by the provider.
      // This ensures that no test fails due to a missing stub.
      when(() => mockFirebaseMessaging.requestPermission()).thenAnswer(
        (_) async => const NotificationSettings(
          authorizationStatus: AuthorizationStatus.authorized,
          alert: AppleNotificationSetting.enabled,
          announcement: AppleNotificationSetting.disabled,
          badge: AppleNotificationSetting.enabled,
          carPlay: AppleNotificationSetting.disabled,
          lockScreen: AppleNotificationSetting.enabled,
          notificationCenter: AppleNotificationSetting.enabled,
          showPreviews: AppleShowPreviewSetting.always,
          sound: AppleNotificationSetting.enabled,
          timeSensitive: AppleNotificationSetting.disabled,
          criticalAlert: AppleNotificationSetting.disabled,
          providesAppNotificationSettings: AppleNotificationSetting.disabled,
        ),
      );
      when(() => mockFirebaseMessaging.getNotificationSettings()).thenAnswer(
        (_) async => const NotificationSettings(
          authorizationStatus: AuthorizationStatus.authorized,
          alert: AppleNotificationSetting.enabled,
          announcement: AppleNotificationSetting.disabled,
          badge: AppleNotificationSetting.enabled,
          carPlay: AppleNotificationSetting.disabled,
          lockScreen: AppleNotificationSetting.enabled,
          notificationCenter: AppleNotificationSetting.enabled,
          showPreviews: AppleShowPreviewSetting.always,
          sound: AppleNotificationSetting.enabled,
          timeSensitive: AppleNotificationSetting.disabled,
          criticalAlert: AppleNotificationSetting.disabled,
          providesAppNotificationSettings: AppleNotificationSetting.disabled,
        ),
      );
      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'test_token');
      when(
        () => mockFirebaseMessaging.getInitialMessage(),
      ).thenAnswer((_) async => null);
      when(
        () => mockFirebaseMessaging.onTokenRefresh,
      ).thenAnswer((_) => const Stream<String>.empty());

      when(
        // ignore: invalid_use_of_protected_member
        () => mockFirebaseMessaging.delegateFor(app: any(named: 'app')),
      ).thenReturn(mockFirebaseMessaging);
      // ignore: invalid_use_of_protected_member
      when(
        // ignore: invalid_use_of_protected_member
        () => mockFirebaseMessaging.setInitialValues(
          isAutoInitEnabled: any(named: 'isAutoInitEnabled'),
        ),
      ).thenReturn(mockFirebaseMessaging);
      when(() => mockFirebaseMessaging.isAutoInitEnabled).thenReturn(false);
    });

    test('initialize sets up listeners correctly', () async {
      // Arrange: Create stream controllers to simulate events from the platform.
      final onTokenRefreshController = StreamController<String>.broadcast();

      // Arrange: Point the mock's streams to our controllers.
      when(
        () => mockFirebaseMessaging.onTokenRefresh,
      ).thenAnswer((_) => onTokenRefreshController.stream);

      // Act: Initialize the provider.
      await provider.initialize();

      // Assert: Verify that our provider has subscribed to the platform streams.
      expect(
        onTokenRefreshController.hasListener,
        isTrue,
        reason: 'onTokenRefresh should have a listener',
      );

      // Clean up controllers.
      await onTokenRefreshController.close();
    });

    test('initialize handles initial message if present', () async {
      // Arrange
      const remoteMessage = RemoteMessage(data: {'notificationId': 'init-1'});
      when(
        () => mockFirebaseMessaging.getInitialMessage(),
      ).thenAnswer((_) async => remoteMessage);

      // Act & Assert
      final expectation = expectLater(
        provider.onMessageOpenedApp,
        emits(
          isA<PushNotificationPayload>().having(
            (p) => p.notificationId,
            'notificationId',
            'init-1',
          ),
        ),
      );

      await provider.initialize();
      await expectation;
    });

    test('requestPermission returns true when authorized', () async {
      // Act
      final result = await provider.requestPermission();

      // Assert
      verify(() => mockFirebaseMessaging.requestPermission()).called(1);
      expect(result, isTrue);
    });

    test('requestPermission returns false when denied', () async {
      // Arrange: Override the default mock for this specific test case.
      when(() => mockFirebaseMessaging.requestPermission()).thenAnswer(
        (_) async => const NotificationSettings(
          authorizationStatus: AuthorizationStatus.denied,
          alert: AppleNotificationSetting.disabled,
          announcement: AppleNotificationSetting.disabled,
          badge: AppleNotificationSetting.disabled,
          carPlay: AppleNotificationSetting.disabled,
          lockScreen: AppleNotificationSetting.disabled,
          notificationCenter: AppleNotificationSetting.disabled,
          showPreviews: AppleShowPreviewSetting.never,
          sound: AppleNotificationSetting.disabled,
          timeSensitive: AppleNotificationSetting.disabled,
          criticalAlert: AppleNotificationSetting.disabled,
          providesAppNotificationSettings: AppleNotificationSetting.disabled,
        ),
      );

      // Act
      final result = await provider.requestPermission();

      // Assert
      verify(() => mockFirebaseMessaging.requestPermission()).called(1);
      expect(result, isFalse);
    });

    test('hasPermission returns true when authorized', () async {
      // Arrange
      when(() => mockFirebaseMessaging.getNotificationSettings()).thenAnswer(
        (_) async => const NotificationSettings(
          authorizationStatus: AuthorizationStatus.authorized,
          alert: AppleNotificationSetting.enabled,
          announcement: AppleNotificationSetting.disabled,
          badge: AppleNotificationSetting.enabled,
          carPlay: AppleNotificationSetting.disabled,
          lockScreen: AppleNotificationSetting.enabled,
          notificationCenter: AppleNotificationSetting.enabled,
          showPreviews: AppleShowPreviewSetting.always,
          sound: AppleNotificationSetting.enabled,
          timeSensitive: AppleNotificationSetting.disabled,
          criticalAlert: AppleNotificationSetting.disabled,
          providesAppNotificationSettings: AppleNotificationSetting.disabled,
        ),
      );

      // Act
      final result = await provider.hasPermission();

      // Assert
      verify(() => mockFirebaseMessaging.getNotificationSettings()).called(1);
      expect(result, isTrue);
    });

    test('getToken returns the token from FirebaseMessaging', () async {
      // Act
      final token = await provider.getToken();

      // Assert
      verify(() => mockFirebaseMessaging.getToken()).called(1);
      expect(token, 'test_token');
    });

    test(
      'initialMessage returns a converted payload when one exists',
      () async {
        // Arrange
        const remoteMessage = RemoteMessage(data: {'notificationId': '123'});
        when(
          () => mockFirebaseMessaging.getInitialMessage(),
        ).thenAnswer((_) async => remoteMessage);

        // Act
        final payload = await provider.initialMessage;

        // Assert
        verify(() => mockFirebaseMessaging.getInitialMessage()).called(1);
        expect(payload, isA<PushNotificationPayload>());
        expect(payload?.notificationId, '123');
      },
    );

    test(
      'initialMessage returns null when no initial message exists',
      () async {
        // Arrange (already done in setUp, but explicit for clarity)
        when(
          () => mockFirebaseMessaging.getInitialMessage(),
        ).thenAnswer((_) async => null);

        // Act
        final payload = await provider.initialMessage;

        // Assert
        verify(() => mockFirebaseMessaging.getInitialMessage()).called(1);
        expect(payload, isNull);
      },
    );

    test('close completes without error', () async {
      // This test ensures the close method runs without throwing exceptions.
      await expectLater(provider.close(), completes);
    });
  });
}
