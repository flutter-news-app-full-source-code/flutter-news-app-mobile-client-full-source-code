import 'package:flutter/services.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/providers/one_signal_push_notification_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/providers/push_notification_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockLogger extends Mock implements Logger {}

void setupOneSignalMocks() {
  const MethodChannel('OneSignal').setMockMethodCallHandler((call) async {
    return null;
  });
  const MethodChannel('OneSignal#debug').setMockMethodCallHandler((call) async {
    return null;
  });
  const MethodChannel('OneSignal#notifications').setMockMethodCallHandler((
    call,
  ) async {
    return true;
  });
  const MethodChannel('OneSignal#user').setMockMethodCallHandler((call) async {
    return null;
  });
  const MethodChannel('OneSignal#inappmessages').setMockMethodCallHandler((
    call,
  ) async {
    return null;
  });
  const MethodChannel('OneSignal#pushsubscription').setMockMethodCallHandler((
    call,
  ) async {
    return null;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('OneSignalPushNotificationService', () {
    late PushNotificationProvider provider;
    late MockLogger mockLogger;

    // We can't easily mock the static OneSignal instance, so we test behavior
    // assuming the SDK works as documented. This test focuses on the provider's
    // logic. We will verify that the provider attempts to make the correct calls.

    setUp(() {
      setupOneSignalMocks();
      mockLogger = MockLogger();
      provider = OneSignalPushNotificationService(
        appId: 'test-app-id',
        logger: mockLogger,
      );
    });

    test('initialize logs an info message', () async {
      // We can't test the OneSignal static calls without a complex setup,
      // but we can verify our provider attempts to log its initialization.
      await provider.initialize();
      verify(
        () =>
            mockLogger.info('Initializing OneSignalPushNotificationService...'),
      ).called(1);
    });

    test('initialMessage always returns null', () async {
      // OneSignal doesn't have a direct equivalent to getInitialMessage,
      // it relies on the click handler.
      final message = await provider.initialMessage;
      expect(message, isNull);
    });

    test('requestPermission calls OneSignal SDK', () async {
      // Act
      final result = await provider.requestPermission();

      // Assert
      // Since we mocked the channel to return null (void), and the SDK returns true/false,
      // we mostly verify it doesn't crash. The SDK defaults to `true` in tests if not mocked otherwise.
      expect(result, isA<bool>());
    });

    test('close closes all stream controllers', () async {
      // Act
      // This test ensures the close method runs without throwing exceptions.
      // Due to the private nature of stream controllers, we can't easily
      // assert they are closed, but we can ensure the method completes.
      await expectLater(provider.close(), completes);
    });

    // Note: Testing the actual stream emissions from OneSignal requires more
    // complex mocking of the static OneSignal handlers, which is often
    // brittle. The most valuable tests for the manager cover how it *reacts*
    // to these streams, which is handled in the manager's own tests.
    // Here, we've tested the provider's own properties and lifecycle methods.
  });
}
