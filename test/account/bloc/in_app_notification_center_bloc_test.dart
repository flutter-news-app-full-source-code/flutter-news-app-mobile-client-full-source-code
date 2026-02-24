import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/in_app_notification_center_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockDataRepository extends Mock
    implements DataRepository<InAppNotification> {}

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockLogger extends Mock implements Logger {}

class FakeInAppNotification extends Fake implements InAppNotification {}

void main() {
  group('InAppNotificationCenterBloc', () {
    late DataRepository<InAppNotification> inAppNotificationRepository;
    late AppBloc appBloc;
    late Logger logger;
    late InAppNotificationCenterBloc bloc;

    final user = User(
      id: 'user-123',
      email: 'test@example.com',
      role: UserRole.user,
      tier: AccessTier.standard,
      createdAt: DateTime.now(),
    );

    final notificationBreaking = InAppNotification(
      id: 'breaking-1',
      userId: user.id,
      payload: const PushNotificationPayload(
        title: 'Breaking News',
        notificationId: 'breaking-1',
        notificationType: PushNotificationSubscriptionDeliveryType.breakingOnly,
        contentType: ContentType.headline,
        contentId: 'h1',
      ),
      createdAt: DateTime.now(),
    );

    setUpAll(() {
      registerFallbackValue(FakeInAppNotification());
    });

    setUp(() {
      inAppNotificationRepository = MockDataRepository();
      appBloc = MockAppBloc();
      logger = MockLogger();

      when(() => appBloc.state).thenReturn(
        AppState(status: AppLifeCycleStatus.authenticated, user: user),
      );

      bloc = InAppNotificationCenterBloc(
        inAppNotificationRepository: inAppNotificationRepository,
        appBloc: appBloc,
        logger: logger,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const InAppNotificationCenterState());
    });

    group('InAppNotificationCenterSubscriptionRequested', () {
      blocTest<InAppNotificationCenterBloc, InAppNotificationCenterState>(
        'emits [loading, success] with fetched notifications when successful',
        setUp: () {
          when(
            () => inAppNotificationRepository.readAll(
              userId: any(named: 'userId'),
              pagination: any(named: 'pagination'),
              sort: any(named: 'sort'),
            ),
          ).thenAnswer((_) async {
            return PaginatedResponse<InAppNotification>(
              items: [notificationBreaking],
              cursor: null,
              hasMore: false,
            );
          });
        },
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const InAppNotificationCenterSubscriptionRequested()),
        expect: () => [
          const InAppNotificationCenterState(
            status: InAppNotificationCenterStatus.loading,
          ),
          InAppNotificationCenterState(
            status: InAppNotificationCenterStatus.success,
            notifications: [notificationBreaking],
            hasMore: false,
          ),
        ],
      );

      blocTest<InAppNotificationCenterBloc, InAppNotificationCenterState>(
        'emits [loading, failure] when user is not logged in',
        setUp: () {
          when(() => appBloc.state).thenReturn(
            const AppState(status: AppLifeCycleStatus.unauthenticated),
          );
        },
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const InAppNotificationCenterSubscriptionRequested()),
        expect: () => [
          const InAppNotificationCenterState(
            status: InAppNotificationCenterStatus.loading,
          ),
          const InAppNotificationCenterState(
            status: InAppNotificationCenterStatus.failure,
          ),
        ],
      );

      blocTest<InAppNotificationCenterBloc, InAppNotificationCenterState>(
        'emits [loading, failure] when repository throws exception',
        setUp: () {
          when(
            () => inAppNotificationRepository.readAll(
              userId: any(named: 'userId'),
              pagination: any(named: 'pagination'),
              sort: any(named: 'sort'),
            ),
          ).thenThrow(const HttpException('Not Found'));
        },
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const InAppNotificationCenterSubscriptionRequested()),
        expect: () => [
          const InAppNotificationCenterState(
            status: InAppNotificationCenterStatus.loading,
          ),
          isA<InAppNotificationCenterState>()
              .having(
                (s) => s.status,
                'status',
                InAppNotificationCenterStatus.failure,
              )
              .having((s) => s.error?.message, 'error message', 'Not Found'),
        ],
      );
    });

    group('InAppNotificationCenterFetchMoreRequested', () {
      blocTest<InAppNotificationCenterBloc, InAppNotificationCenterState>(
        'does nothing if status is loadingMore',
        seed: () => const InAppNotificationCenterState(
          status: InAppNotificationCenterStatus.loadingMore,
        ),
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const InAppNotificationCenterFetchMoreRequested()),
        // ignore: inference_failure_on_collection_literal
        expect: () => [],
      );

      blocTest<InAppNotificationCenterBloc, InAppNotificationCenterState>(
        'does nothing if hasMore is false for current tab (Breaking News)',
        seed: () => const InAppNotificationCenterState(
          status: InAppNotificationCenterStatus.success,
          hasMore: false,
        ),
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const InAppNotificationCenterFetchMoreRequested()),
        // ignore: inference_failure_on_collection_literal
        expect: () => [],
      );

      blocTest<InAppNotificationCenterBloc, InAppNotificationCenterState>(
        'emits [loadingMore, success] with appended items for Breaking News',
        seed: () => InAppNotificationCenterState(
          status: InAppNotificationCenterStatus.success,
          notifications: [notificationBreaking],
          hasMore: true,
          cursor: 'cursor-1',
        ),
        setUp: () {
          when(
            () => inAppNotificationRepository.readAll(
              userId: any(named: 'userId'),
              pagination: any(named: 'pagination'),
              sort: any(named: 'sort'),
            ),
          ).thenAnswer(
            (_) async => PaginatedResponse<InAppNotification>(
              items: [notificationBreaking],
              hasMore: false,
              cursor: 'cursor-2',
            ),
          );
        },
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const InAppNotificationCenterFetchMoreRequested()),
        expect: () => [
          InAppNotificationCenterState(
            status: InAppNotificationCenterStatus.loadingMore,
            notifications: [notificationBreaking],
            hasMore: true,
            cursor: 'cursor-1',
          ),
          InAppNotificationCenterState(
            status: InAppNotificationCenterStatus.success,
            notifications: [notificationBreaking, notificationBreaking],
            hasMore: false,
            cursor: 'cursor-2',
          ),
        ],
      );
    });

    group('InAppNotificationCenterMarkedAsRead', () {
      final unreadNotification = notificationBreaking.copyWith(readAt: null);
      final readNotification = notificationBreaking.copyWith(
        readAt: DateTime.now(),
      );

      blocTest<InAppNotificationCenterBloc, InAppNotificationCenterState>(
        'updates notification locally and calls repository',
        seed: () =>
            InAppNotificationCenterState(notifications: [unreadNotification]),
        setUp: () {
          when(
            () => inAppNotificationRepository.update(
              id: any(named: 'id'),
              item: any(named: 'item'),
              userId: any(named: 'userId'),
            ),
          ).thenAnswer((_) async => readNotification);
        },
        build: () => bloc,
        act: (bloc) => bloc.add(
          InAppNotificationCenterMarkedAsRead(unreadNotification.id),
        ),
        verify: (_) {
          verify(
            () => inAppNotificationRepository.update(
              id: unreadNotification.id,
              item: any(named: 'item'),
              userId: user.id,
            ),
          ).called(1);
          verify(
            () => appBloc.add(const AppInAppNotificationMarkedAsRead()),
          ).called(1);
        },
        // We expect the state to update. Note: The exact DateTime.now() in the
        // bloc implementation makes strict equality check hard without a clock
        // abstraction, but we can check if the item is updated in the list.
        expect: () => [
          isA<InAppNotificationCenterState>().having(
            (s) => s.notifications.first.isRead,
            'notification is read',
            true,
          ),
        ],
      );
    });

    group('InAppNotificationCenterMarkAllAsRead', () {
      final unread1 = notificationBreaking.copyWith(
        id: '1',
        readAt: null,
        payload: notificationBreaking.payload.copyWith(notificationId: '1'),
      );

      blocTest<InAppNotificationCenterBloc, InAppNotificationCenterState>(
        'marks all unread notifications as read and updates repository',
        seed: () => InAppNotificationCenterState(notifications: [unread1]),
        setUp: () {
          when(
            () => inAppNotificationRepository.update(
              id: any(named: 'id'),
              item: any(named: 'item'),
              userId: any(named: 'userId'),
            ),
          ).thenAnswer((invocation) async {
            final item = invocation.namedArguments[#item] as InAppNotification;
            return item;
          });
        },
        build: () => bloc,
        act: (bloc) => bloc.add(const InAppNotificationCenterMarkAllAsRead()),
        verify: (_) {
          verify(
            () => inAppNotificationRepository.update(
              id: any(named: 'id'),
              item: any(named: 'item'),
              userId: user.id,
            ),
          ).called(1);
          verify(
            () => appBloc.add(const AppAllInAppNotificationsMarkedAsRead()),
          ).called(1);
        },
        expect: () => [
          isA<InAppNotificationCenterState>().having(
            (s) => s.notifications.every((n) => n.isRead),
            'all notifications are read',
            true,
          ),
        ],
      );
    });

    group('InAppNotificationCenterReadItemsDeleted', () {
      final readNotif = notificationBreaking.copyWith(
        readAt: DateTime.now(),
        id: 'read-1',
      );
      final unreadNotif = notificationBreaking.copyWith(
        readAt: null,
        id: 'unread-1',
      );

      blocTest<InAppNotificationCenterBloc, InAppNotificationCenterState>(
        'deletes read items and refreshes the list',
        seed: () => InAppNotificationCenterState(
          status: InAppNotificationCenterStatus.success,
          notifications: [readNotif, unreadNotif],
        ),
        setUp: () {
          when(
            () => inAppNotificationRepository.delete(
              id: any(named: 'id'),
              userId: any(named: 'userId'),
            ),
          ).thenAnswer((_) async {});

          // Mock re-fetch after deletion
          when(
            () => inAppNotificationRepository.readAll(
              userId: any(named: 'userId'),
              pagination: any(named: 'pagination'),
              sort: any(named: 'sort'),
            ),
          ).thenAnswer(
            (_) async => PaginatedResponse<InAppNotification>(
              items: [unreadNotif],
              hasMore: false,
              cursor: null,
            ),
          );
        },
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const InAppNotificationCenterReadItemsDeleted()),
        verify: (_) {
          verify(
            () => inAppNotificationRepository.delete(
              id: readNotif.id,
              userId: user.id,
            ),
          ).called(1);
          // Should not delete unread item
          verifyNever(
            () => inAppNotificationRepository.delete(
              id: unreadNotif.id,
              userId: any(named: 'userId'),
            ),
          );
        },
        expect: () => [
          InAppNotificationCenterState(
            status: InAppNotificationCenterStatus.deleting,
            notifications: [readNotif, unreadNotif],
          ),
          InAppNotificationCenterState(
            status: InAppNotificationCenterStatus.success,
            notifications: [unreadNotif],
            hasMore: false,
          ),
        ],
      );

      blocTest<InAppNotificationCenterBloc, InAppNotificationCenterState>(
        'does nothing if no read items exist',
        seed: () => InAppNotificationCenterState(
          status: InAppNotificationCenterStatus.success,
          notifications: [unreadNotif],
        ),
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const InAppNotificationCenterReadItemsDeleted()),
        expect: () => [
          InAppNotificationCenterState(
            status: InAppNotificationCenterStatus.deleting,
            notifications: [unreadNotif],
          ),
          InAppNotificationCenterState(
            status: InAppNotificationCenterStatus.success,
            notifications: [unreadNotif],
          ),
        ],
      );
    });

    group('InAppNotificationCenterMarkOneAsRead', () {
      final unreadNotification = notificationBreaking.copyWith(readAt: null);
      final readNotification = notificationBreaking.copyWith(
        readAt: DateTime.now(),
      );

      blocTest<InAppNotificationCenterBloc, InAppNotificationCenterState>(
        'marks notification as read when it exists and is unread',
        seed: () =>
            InAppNotificationCenterState(notifications: [unreadNotification]),
        setUp: () {
          when(
            () => inAppNotificationRepository.update(
              id: any(named: 'id'),
              item: any(named: 'item'),
              userId: any(named: 'userId'),
            ),
          ).thenAnswer((_) async => readNotification);
        },
        build: () => bloc,
        act: (bloc) => bloc.add(
          InAppNotificationCenterMarkOneAsRead(unreadNotification.id),
        ),
        verify: (_) {
          verify(
            () => inAppNotificationRepository.update(
              id: unreadNotification.id,
              item: any(named: 'item'),
              userId: user.id,
            ),
          ).called(1);
          verify(
            () => appBloc.add(const AppInAppNotificationMarkedAsRead()),
          ).called(1);
        },
        expect: () => [
          isA<InAppNotificationCenterState>().having(
            (s) => s.notifications.first.isRead,
            'notification is read',
            true,
          ),
        ],
      );
    });
  });
}
