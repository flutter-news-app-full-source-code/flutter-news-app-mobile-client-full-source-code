import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/in_app_notification_center_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/in_app_notification_center_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';

class MockInAppNotificationCenterBloc
    extends MockBloc<InAppNotificationCenterEvent, InAppNotificationCenterState>
    implements InAppNotificationCenterBloc {}

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockDataRepository<T> extends Mock implements DataRepository<T> {}

void main() {
  group('InAppNotificationCenterPage', () {
    late InAppNotificationCenterBloc mockBloc;
    late AppBloc mockAppBloc;

    final testNotification = InAppNotification(
      id: '1',
      userId: 'user1',
      payload: const PushNotificationPayload(
        title: 'Test Notification',
        notificationId: '1',
        notificationType: PushNotificationSubscriptionDeliveryType.breakingOnly,
        contentType: ContentType.headline,
        contentId: 'headline-1',
      ),
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockBloc = MockInAppNotificationCenterBloc();
      mockAppBloc = MockAppBloc();

      // Mock the AppBloc to provide a valid user
      when(() => mockAppBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.authenticated,
          user: User(
            id: 'user1',
            email: 'test@test.com',
            role: UserRole.user,
            tier: AccessTier.standard,
            createdAt: DateTime.now(),
          ),
        ),
      );
    });

    Widget buildWidget() {
      return MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...UiKitLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: mockBloc),
            BlocProvider.value(value: mockAppBloc),
            // Provide necessary repositories for HeadlineTapHandler
            RepositoryProvider<DataRepository<Headline>>(
              create: (_) => MockDataRepository<Headline>(),
            ),
            RepositoryProvider<Logger>(create: (_) => Logger('test')),
          ],
          child: const InAppNotificationCenterPage(),
        ),
      );
    }

    testWidgets('renders loading state correctly', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const InAppNotificationCenterState(
          status: InAppNotificationCenterStatus.loading,
        ),
      );

      await tester.pumpWidget(buildWidget());

      expect(find.byType(LoadingStateWidget), findsOneWidget);
    });

    testWidgets('renders empty state correctly', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const InAppNotificationCenterState(
          status: InAppNotificationCenterStatus.success,
          notifications: [],
        ),
      );

      await tester.pumpWidget(buildWidget());

      // The page has two tabs, so we expect two InitialStateWidgets
      // TabBarView only renders the active tab, so we expect one.
      expect(find.byType(InitialStateWidget), findsOneWidget);
    });

    testWidgets('renders list of notifications correctly', (tester) async {
      when(() => mockBloc.state).thenReturn(
        InAppNotificationCenterState(
          status: InAppNotificationCenterStatus.success,
          notifications: [testNotification],
        ),
      );

      await tester.pumpWidget(buildWidget());

      expect(find.text('Test Notification'), findsOneWidget);
    });

    testWidgets('tapping "Mark all as read" adds correct event', (
      tester,
    ) async {
      final unreadNotification = testNotification.copyWith(readAt: null);
      when(() => mockBloc.state).thenReturn(
        InAppNotificationCenterState(
          status: InAppNotificationCenterStatus.success,
          notifications: [unreadNotification],
        ),
      );

      await tester.pumpWidget(buildWidget());

      // Find the "Mark all as read" button by its tooltip
      final markAllReadButton = find.byTooltip('Mark all as read');
      expect(markAllReadButton, findsOneWidget);

      // Tap the button
      await tester.tap(markAllReadButton);
      await tester.pump();

      // Verify that the correct event was added to the BLoC
      verify(
        () => mockBloc.add(const InAppNotificationCenterMarkAllAsRead()),
      ).called(1);
    });

    testWidgets(
      'tapping delete button shows dialog and adds event on confirm',
      (tester) async {
        final readNotification = testNotification.copyWith(
          readAt: DateTime.now(),
        );
        when(() => mockBloc.state).thenReturn(
          InAppNotificationCenterState(
            status: InAppNotificationCenterStatus.success,
            notifications: [readNotification],
          ),
        );

        await tester.pumpWidget(buildWidget());

        // Find the delete button
        final deleteButton = find.byIcon(Icons.delete_sweep_outlined);
        expect(deleteButton, findsOneWidget);

        // Tap delete
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        // Verify dialog appears
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);

        // Tap confirm
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        verify(
          () => mockBloc.add(const InAppNotificationCenterReadItemsDeleted()),
        ).called(1);
      },
    );

    testWidgets('scrolling to bottom triggers fetch more event', (
      tester,
    ) async {
      // Create enough notifications to ensure scrolling is possible
      final notifications = List.generate(
        15,
        (index) => testNotification.copyWith(id: '$index'),
      );

      when(() => mockBloc.state).thenReturn(
        InAppNotificationCenterState(
          status: InAppNotificationCenterStatus.success,
          notifications: notifications,
          hasMore: true,
        ),
      );

      await tester.pumpWidget(buildWidget());

      // Find the list view
      final listFinder = find.byType(ListView);
      expect(listFinder, findsOneWidget);

      // Fling scroll to bottom
      await tester.fling(
        listFinder,
        const Offset(0, -500), // Scroll up (content moves down)
        1000,
      );
      await tester.pump();

      // We might need to settle or pump frames to trigger the listener
      await tester.pump(const Duration(milliseconds: 500));

      verify(
        () => mockBloc.add(const InAppNotificationCenterFetchMoreRequested()),
      ).called(1);
    });
  });
}
