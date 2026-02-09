import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/push_notification/providers/one_signal_push_notification_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/push_notification/providers/push_notification_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class MockLogger extends Mock implements Logger {}

class MockOneSignalWrapper extends Mock implements OneSignalWrapper {}

class MockOSNotificationClickEvent extends Mock
    implements OSNotificationClickEvent {}

class MockOSNotification extends Mock implements OSNotification {}

class MockOSNotificationWillDisplayEvent extends Mock
    implements OSNotificationWillDisplayEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(OSLogLevel.verbose);
    registerFallbackValue((OSPushSubscriptionChangedState state) {});
    registerFallbackValue((OSNotificationWillDisplayEvent event) {});
    registerFallbackValue((OSNotificationClickEvent event) {});
  });

  group('OneSignalPushNotificationService', () {
    late PushNotificationProvider provider;
    late MockLogger mockLogger;
    late MockOneSignalWrapper mockOneSignal;

    setUp(() {
      mockLogger = MockLogger();
      mockOneSignal = MockOneSignalWrapper();
      provider = OneSignalPushNotificationService(
        appId: 'test-app-id',
        logger: mockLogger,
        oneSignalWrapper: mockOneSignal,
      );

      // Default stubs
      when(() => mockOneSignal.setLogLevel(any())).thenAnswer((_) async {});
      when(() => mockOneSignal.initialize(any())).thenReturn(null);
      when(
        () => mockOneSignal.addPushSubscriptionObserver(any()),
      ).thenReturn(null);
      when(
        () => mockOneSignal.addForegroundWillDisplayListener(any()),
      ).thenReturn(null);
      when(() => mockOneSignal.addClickListener(any())).thenReturn(null);
      when(
        () => mockOneSignal.removeForegroundWillDisplayListener(any()),
      ).thenReturn(null);
      when(() => mockOneSignal.removeClickListener(any())).thenReturn(null);
    });

    tearDown(() async {
      await provider.close();
    });

    test('initialize logs an info message', () async {
      await provider.initialize();
      verify(
        () =>
            mockLogger.info('Initializing OneSignalPushNotificationService...'),
      ).called(1);
    });
    test(
      'initialMessage returns payload when app is opened from notification',
      () async {
        // Arrange
        late void Function(OSNotificationClickEvent) clickListener;
        when(() => mockOneSignal.addClickListener(any())).thenAnswer((
          invocation,
        ) {
          clickListener =
              invocation.positionalArguments[0]
                  as void Function(OSNotificationClickEvent);
        });

        await provider.initialize();

        final mockEvent = MockOSNotificationClickEvent();
        final mockNotification = MockOSNotification();

        when(() => mockEvent.notification).thenReturn(mockNotification);
        when(mockNotification.jsonRepresentation).thenReturn('{}');
        when(() => mockNotification.notificationId).thenReturn('test-notif-id');
        when(() => mockNotification.title).thenReturn('Test Title');
        when(
          () => mockNotification.bigPicture,
        ).thenReturn('https://example.com/image.png');
        when(() => mockNotification.additionalData).thenReturn({
          'notificationId': 'payload-notif-id',
          'contentType': 'headline',
          'contentId': 'headline-123',
          'notificationType': 'breakingOnly',
        });

        // Act
        // Simulate the click event immediately
        clickListener(mockEvent);

        final message = await provider.initialMessage;

        // Assert
        expect(message, isNotNull);
        expect(message!.notificationId, 'payload-notif-id');
        expect(message.contentId, 'headline-123');
        expect(message.title, 'Test Title');
        expect(message.imageUrl, 'https://example.com/image.png');
      },
    );

    test('initialMessage returns null when app is opened normally', () async {
      // Arrange
      await provider.initialize();

      // Act
      // Wait for the internal timeout (500ms)
      final message = await provider.initialMessage;

      // Assert
      expect(message, isNull);
    });

    test(
      'onMessageOpenedApp receives payload for subsequent background taps',
      () async {
        // Arrange
        late void Function(OSNotificationClickEvent) clickListener;
        when(() => mockOneSignal.addClickListener(any())).thenAnswer((
          invocation,
        ) {
          clickListener =
              invocation.positionalArguments[0]
                  as void Function(OSNotificationClickEvent);
        });

        await provider.initialize();

        // 1. Let the initial message timeout
        final initial = await provider.initialMessage;
        expect(initial, isNull);

        // 2. Prepare the second click event
        final mockEvent = MockOSNotificationClickEvent();
        final mockNotification = MockOSNotification();

        when(() => mockEvent.notification).thenReturn(mockNotification);
        when(mockNotification.jsonRepresentation).thenReturn('{}');
        when(
          () => mockNotification.notificationId,
        ).thenReturn('test-notif-id-2');
        when(() => mockNotification.title).thenReturn('Second Title');
        when(() => mockNotification.bigPicture).thenReturn(null);
        when(() => mockNotification.additionalData).thenReturn({
          'notificationId': 'payload-notif-id-2',
          'contentType': 'headline',
          'contentId': 'headline-456',
          'notificationType': 'dailyDigest',
        });

        // Assert
        final future = expectLater(
          provider.onMessageOpenedApp,
          emits(
            isA<PushNotificationPayload>()
                .having(
                  (p) => p.notificationId,
                  'notificationId',
                  'payload-notif-id-2',
                )
                .having((p) => p.contentId, 'contentId', 'headline-456'),
          ),
        );

        // Act
        clickListener(mockEvent);
        await future;
      },
    );

    test('requestPermission calls OneSignal SDK', () async {
      // Arrange
      when(
        () => mockOneSignal.requestPermission(any()),
      ).thenAnswer((_) async => true);

      // Act
      final result = await provider.requestPermission();

      // Assert
      verify(() => mockOneSignal.requestPermission(true)).called(1);
      expect(result, isTrue);
    });

    test('close closes all stream controllers and removes listeners', () async {
      // Arrange
      late void Function(OSNotificationWillDisplayEvent) foregroundListener;
      late void Function(OSNotificationClickEvent) clickListener;

      when(
        () => mockOneSignal.addForegroundWillDisplayListener(any()),
      ).thenAnswer((invocation) {
        foregroundListener =
            invocation.positionalArguments[0]
                as void Function(OSNotificationWillDisplayEvent);
      });
      when(() => mockOneSignal.addClickListener(any())).thenAnswer((
        invocation,
      ) {
        clickListener =
            invocation.positionalArguments[0]
                as void Function(OSNotificationClickEvent);
      });

      await provider.initialize();

      // Act
      await provider.close();

      // Assert
      verify(
        () => mockOneSignal.removeForegroundWillDisplayListener(
          foregroundListener,
        ),
      ).called(1);
      verify(() => mockOneSignal.removeClickListener(clickListener)).called(1);
    });
  });
}
