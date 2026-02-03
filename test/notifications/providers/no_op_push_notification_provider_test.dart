import 'package:flutter_news_app_mobile_client_full_source_code/notifications/providers/no_op_push_notification_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('NoOpPushNotificationProvider', () {
    late NoOpPushNotificationProvider provider;
    late MockLogger mockLogger;

    setUp(() {
      mockLogger = MockLogger();
      provider = NoOpPushNotificationProvider(logger: mockLogger);
    });

    test('initialize logs an info message', () async {
      await provider.initialize();
      verify(
        () => mockLogger.info(
          'Initializing NoOpPushNotificationProvider (Notifications disabled).',
        ),
      ).called(1);
    });

    test('requestPermission returns false', () async {
      expect(await provider.requestPermission(), isFalse);
    });

    test('hasPermission returns false', () async {
      expect(await provider.hasPermission(), isFalse);
    });

    test('getToken returns null', () async {
      expect(await provider.getToken(), isNull);
    });

    test('initialMessage returns null', () async {
      expect(await provider.initialMessage, isNull);
    });

    test('streams are empty', () {
      expect(provider.onMessage, emitsDone);
      expect(provider.onMessageOpenedApp, emitsDone);
      expect(provider.onTokenRefreshed, emitsDone);
    });
  });
}
