// ignore_for_file: strict_raw_type

import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockEngagementRepository extends Mock
    implements DataRepository<Engagement> {}

class MockReportRepository extends Mock implements DataRepository<Report> {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockLogger extends Mock implements Logger {}

class FakeLimitExceededPayload extends Fake implements LimitExceededPayload {}

final testDate = DateTime(2024);

void main() {
  late ContentLimitationService service;
  late MockEngagementRepository mockEngagementRepository;
  late MockReportRepository mockReportRepository;
  late MockAnalyticsService mockAnalyticsService;
  late MockAppBloc mockAppBloc;
  late MockLogger mockLogger;

  // Define here to be accessible in all tests
  final guestUser = User(
    id: 'guest',
    email: 'guest@example.com',
    role: UserRole.user,
    tier: AccessTier.guest,
    createdAt: DateTime.now(),
    isAnonymous: true,
  );

  final standardUser = User(
    id: 'standard',
    email: 'standard@example.com',
    role: UserRole.user,
    tier: AccessTier.standard,
    createdAt: DateTime.now(),
    isAnonymous: false,
  );

  setUp(() {
    mockEngagementRepository = MockEngagementRepository();
    mockReportRepository = MockReportRepository();
    mockAnalyticsService = MockAnalyticsService();
    mockAppBloc = MockAppBloc();
    mockLogger = MockLogger();

    service = ContentLimitationService(
      engagementRepository: mockEngagementRepository,
      reportRepository: mockReportRepository,
      analyticsService: mockAnalyticsService,
      cacheDuration: const Duration(minutes: 5),
      logger: mockLogger,
    );

    registerFallbackValue(FakeLimitExceededPayload());
    registerFallbackValue(AnalyticsEvent.limitExceeded);

    // Default stub for readAll to return an empty paginated response.
    when(
      () => mockEngagementRepository.readAll(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        pagination: any(named: 'pagination'),
      ),
    ).thenAnswer(
      (_) async =>
          const PaginatedResponse(items: [], cursor: null, hasMore: false),
    );
    when(
      () => mockReportRepository.readAll(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        pagination: any(named: 'pagination'),
      ),
    ).thenAnswer(
      (_) async =>
          const PaginatedResponse(items: [], cursor: null, hasMore: false),
    );

    // Default stubs to prevent Null subtype errors and Future.wait failures
    when(
      () =>
          mockAnalyticsService.logEvent(any(), payload: any(named: 'payload')),
    ).thenAnswer((_) async {});
  });

  group('ContentLimitationService', () {
    const emptyPreferences = UserContentPreferences(
      id: 'prefs',
      followedCountries: [],
      followedSources: [],
      followedTopics: [],
      savedHeadlines: [],
      savedHeadlineFilters: [],
      savedSourceFilters: [],
    );

    final mockRemoteConfig = RemoteConfig(
      id: 'config',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      app: const AppConfig(
        maintenance: MaintenanceConfig(isUnderMaintenance: false),
        update: UpdateConfig(
          latestAppVersion: '1.0.0',
          isLatestVersionOnly: false,
          iosUpdateUrl: '',
          androidUpdateUrl: '',
        ),
        general: GeneralAppConfig(termsOfServiceUrl: '', privacyPolicyUrl: ''),
      ),
      features: const FeaturesConfig(
        analytics: AnalyticsConfig(
          enabled: true,
          activeProvider: AnalyticsProviders.firebase,
          disabledEvents: {},
          eventSamplingRates: {},
        ),
        ads: AdConfig(
          enabled: false,
          primaryAdPlatform: AdPlatformType.admob,
          platformAdIdentifiers: {},
          feedAdConfiguration: FeedAdConfiguration(
            enabled: false,
            adType: AdType.native,
            visibleTo: {},
          ),
          navigationAdConfiguration: NavigationAdConfiguration(
            enabled: false,
            visibleTo: {},
          ),
        ),
        pushNotifications: PushNotificationConfig(
          enabled: false,
          primaryProvider: PushNotificationProviders.firebase,
          deliveryConfigs: {},
        ),
        feed: FeedConfig(
          itemClickBehavior: FeedItemClickBehavior.defaultBehavior,
          decorators: {},
        ),
        community: CommunityConfig(
          enabled: true,
          engagement: EngagementConfig(
            enabled: true,
            engagementMode: EngagementMode.reactionsAndComments,
          ),
          reporting: ReportingConfig(
            headlineReportingEnabled: true,
            sourceReportingEnabled: true,
            commentReportingEnabled: true,
            enabled: true,
          ),
          appReview: AppReviewConfig(
            enabled: false,
            interactionCycleThreshold: 10,
            initialPromptCooldownDays: 30,
            eligiblePositiveInteractions: [],
            isNegativeFeedbackFollowUpEnabled: false,
            isPositiveFeedbackFollowUpEnabled: false,
          ),
        ),
        rewards: RewardsConfig(enabled: true, rewards: {}),
      ),
      user: const UserConfig(
        limits: UserLimitsConfig(
          followedItems: {AccessTier.guest: 2, AccessTier.standard: 5},
          savedHeadlines: {AccessTier.standard: 10},
          savedHeadlineFilters: {
            AccessTier.standard: SavedFilterLimits(total: 2, pinned: 1),
          },
          savedSourceFilters: {
            AccessTier.standard: SavedFilterLimits(total: 2, pinned: 1),
          },
          commentsPerDay: {AccessTier.guest: 0, AccessTier.standard: 3},
          reactionsPerDay: {AccessTier.guest: 2, AccessTier.standard: 10},
          reportsPerDay: {AccessTier.guest: 1, AccessTier.standard: 5},
        ),
      ),
    );

    test('dispose cancels stream subscription', () {
      // Arrange
      final streamController = StreamController<AppState>();
      when(() => mockAppBloc.stream).thenAnswer((_) => streamController.stream);
      when(
        () => mockAppBloc.state,
      ).thenReturn(const AppState(status: AppLifeCycleStatus.unauthenticated));
      service.init(appBloc: mockAppBloc);

      // Act
      service.dispose();

      // Assert
      expect(streamController.hasListener, isFalse);
    });

    test('clears cache and fetches new data on user change', () async {
      // Arrange: Initial user (guest)
      final streamController = StreamController<AppState>.broadcast();
      when(() => mockAppBloc.stream).thenAnswer((_) => streamController.stream);
      when(() => mockAppBloc.state).thenReturn(
        AppState(user: guestUser, status: AppLifeCycleStatus.anonymous),
      );
      service.init(appBloc: mockAppBloc);
      await Future<void>.delayed(Duration.zero);
      verify(
        () => mockEngagementRepository.readAll(
          userId: guestUser.id,
          filter: any(named: 'filter'),
          pagination: any(named: 'pagination'),
        ),
      ).called(1);
      clearInteractions(mockEngagementRepository);

      // Act: Simulate user logging in
      streamController.add(
        AppState(user: standardUser, status: AppLifeCycleStatus.authenticated),
      );
      await Future<void>.delayed(Duration.zero);

      // Assert: Verify a new fetch was triggered for the new user
      verify(
        () => mockEngagementRepository.readAll(
          userId: standardUser.id,
          filter: any(named: 'filter'),
          pagination: any(named: 'pagination'),
        ),
      ).called(1);
      unawaited(streamController.close());
    });

    test(
      'Guest user is restricted from posting comments because limit is 0',
      () async {
        when(() => mockAppBloc.state).thenReturn(
          AppState(
            status: AppLifeCycleStatus.anonymous,
            user: guestUser,
            userContentPreferences: emptyPreferences,
            remoteConfig: mockRemoteConfig,
          ),
        );
        // Daily count for comments is 0, which is the limit. No need to mock
        // readAll as the default empty response will result in a count of 0.

        service.init(appBloc: mockAppBloc);

        expect(
          await service.checkAction(ContentAction.postComment),
          LimitationStatus.anonymousLimitReached,
        );
      },
    );

    test('Guest user is allowed to react when under limit', () async {
      when(() => mockAppBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.anonymous,
          user: guestUser,
          userContentPreferences: emptyPreferences,
          remoteConfig: mockRemoteConfig,
        ),
      );
      // Daily count for reactions is 1, limit is 2.
      when(
        () => mockEngagementRepository.readAll(
          userId: guestUser.id,
          filter: any(named: 'filter'),
          pagination: any(named: 'pagination'),
        ),
      ).thenAnswer(
        (_) async => PaginatedResponse(
          items: [
            Engagement(
              id: 'e1',
              userId: 'guest',
              entityId: 'h1',
              entityType: EngageableType.headline,
              reaction: const Reaction(reactionType: ReactionType.like),
              createdAt: testDate,
              updatedAt: testDate,
            ),
          ],
          cursor: null,
          hasMore: false,
        ),
      );

      service.init(appBloc: mockAppBloc);

      expect(
        await service.checkAction(ContentAction.reactToContent),
        LimitationStatus.allowed,
      );
    });

    test('Guest user is restricted from reacting when at limit', () async {
      when(() => mockAppBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.anonymous,
          user: guestUser,
          userContentPreferences: emptyPreferences,
          remoteConfig: mockRemoteConfig,
        ),
      );
      // Daily count for reactions is 2, limit is 2.
      when(
        () => mockEngagementRepository.readAll(
          userId: guestUser.id,
          filter: any(named: 'filter'),
          pagination: any(named: 'pagination'),
        ),
      ).thenAnswer(
        (_) async => PaginatedResponse(
          items: [
            Engagement(
              id: 'e1',
              userId: 'guest',
              entityId: 'h1',
              entityType: EngageableType.headline,
              reaction: const Reaction(reactionType: ReactionType.like),
              createdAt: testDate,
              updatedAt: testDate,
            ),
            Engagement(
              id: 'e2',
              userId: 'guest',
              entityId: 'h2',
              entityType: EngageableType.headline,
              reaction: const Reaction(reactionType: ReactionType.like),
              createdAt: testDate,
              updatedAt: testDate,
            ),
          ],
          cursor: null,
          hasMore: false,
        ),
      );

      service.init(appBloc: mockAppBloc);

      expect(
        await service.checkAction(ContentAction.reactToContent),
        LimitationStatus.anonymousLimitReached,
      );
    });

    test('Guest user is allowed to report when under limit', () async {
      when(() => mockAppBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.anonymous,
          user: guestUser,
          userContentPreferences: emptyPreferences,
          remoteConfig: mockRemoteConfig,
        ),
      );
      // Daily count for reports is 0, limit is 1.
      // No need to mock readAll as the default empty response will result
      // in a count of 0.

      service.init(appBloc: mockAppBloc);

      expect(
        await service.checkAction(ContentAction.submitReport),
        LimitationStatus.allowed,
      );
    });

    test('Guest user is restricted from reporting when at limit', () async {
      when(() => mockAppBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.anonymous,
          user: guestUser,
          userContentPreferences: emptyPreferences,
          remoteConfig: mockRemoteConfig,
        ),
      );
      // Daily count for reports is 1, limit is 1.
      when(
        () => mockReportRepository.readAll(
          userId: guestUser.id,
          filter: any(named: 'filter'),
          pagination: any(named: 'pagination'),
        ),
      ).thenAnswer(
        (_) async => PaginatedResponse(
          items: [
            Report(
              id: 'r1',
              reporterUserId: 'guest',
              entityType: ReportableEntity.headline,
              entityId: 'h1',
              reason: 'spam',
              status: ModerationStatus.pendingReview,
              createdAt: testDate,
            ),
          ],
          cursor: null,
          hasMore: false,
        ),
      );

      service.init(appBloc: mockAppBloc);

      expect(
        await service.checkAction(ContentAction.submitReport),
        LimitationStatus.anonymousLimitReached,
      );
    });

    test('Standard user should be allowed if within limits', () async {
      when(() => mockAppBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.authenticated,
          user: standardUser,
          userContentPreferences: emptyPreferences,
          remoteConfig: mockRemoteConfig,
        ),
      );

      // Mock daily counts to be 0

      service.init(appBloc: mockAppBloc);

      expect(
        await service.checkAction(ContentAction.postComment),
        LimitationStatus.allowed,
      );
    });

    test('Standard user should be restricted if daily limit reached', () async {
      when(() => mockAppBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.authenticated,
          user: standardUser,
          userContentPreferences: emptyPreferences,
          remoteConfig: mockRemoteConfig,
        ),
      );

      // Mock daily comment count to be 3 (limit is 3)
      when(
        () => mockEngagementRepository.readAll(
          userId: standardUser.id,
          filter: any(named: 'filter'),
          pagination: any(named: 'pagination'),
        ),
      ).thenAnswer(
        (_) async => PaginatedResponse(
          items: List.generate(
            3,
            (i) => Engagement(
              id: 'e$i',
              userId: 'standard',
              entityId: 'h$i',
              entityType: EngageableType.headline,
              comment: Comment(
                language: Language(
                  id: 'en',
                  code: 'en',
                  name: 'English',
                  nativeName: 'English',
                  createdAt: testDate,
                  updatedAt: testDate,
                  status: ContentStatus.active,
                ),
                content: 'c',
              ),
              createdAt: testDate,
              updatedAt: testDate,
            ),
          ),
          cursor: null,
          hasMore: false,
        ),
      );

      service.init(appBloc: mockAppBloc);

      // Trigger fetch
      // We need to simulate the bloc stream or manually call init logic
      // Since init calls fetchDailyCounts async, we wait a bit or rely on checkAction triggering it if stale
      // checkAction triggers fetch if cache is stale/null.

      expect(
        await service.checkAction(ContentAction.postComment),
        LimitationStatus.standardUserLimitReached,
      );
    });

    test(
      'Standard user should be restricted if saved headline limit reached',
      () async {
        final filledPreferences = emptyPreferences.copyWith(
          savedHeadlines: List.generate(
            10,
            (i) => Headline(
              id: '$i',
              title: 't',
              url: 'u',
              imageUrl: 'i',
              source: Source(
                id: 's',
                name: 'n',
                description: 'd',
                url: 'u',
                logoUrl: 'l',
                sourceType: SourceType.newsAgency,
                language: Language(
                  id: 'en',
                  code: 'en',
                  name: 'English',
                  nativeName: 'English',
                  createdAt: DateTime(2023),
                  updatedAt: DateTime(2023),
                  status: ContentStatus.active,
                ),
                headquarters: Country(
                  isoCode: 'US',
                  name: 'USA',
                  flagUrl: 'f',
                  id: 'c',
                  createdAt: DateTime(2023),
                  updatedAt: DateTime(2023),
                  status: ContentStatus.active,
                ),
                createdAt: DateTime(2023),
                updatedAt: DateTime(2023),
                status: ContentStatus.active,
              ),
              eventCountry: Country(
                isoCode: 'US',
                name: 'USA',
                flagUrl: 'f',
                id: 'c',
                createdAt: DateTime(2023),
                updatedAt: DateTime(2023),
                status: ContentStatus.active,
              ),
              topic: Topic(
                id: 't',
                name: 't',
                description: 'd',
                iconUrl: 'i',
                createdAt: DateTime(2023),
                updatedAt: DateTime(2023),
                status: ContentStatus.active,
              ),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              status: ContentStatus.active,
              isBreaking: false,
            ),
          ),
        );

        when(() => mockAppBloc.state).thenReturn(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: standardUser,
            userContentPreferences: filledPreferences,
            remoteConfig: mockRemoteConfig,
          ),
        );

        service.init(appBloc: mockAppBloc);

        expect(
          await service.checkAction(ContentAction.bookmarkHeadline),
          LimitationStatus.standardUserLimitReached,
        );
      },
    );

    test(
      'Standard user should be restricted if daily reaction limit reached',
      () async {
        when(() => mockAppBloc.state).thenReturn(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: standardUser,
            userContentPreferences: emptyPreferences,
            remoteConfig: mockRemoteConfig,
          ),
        );

        // Mock reaction count to be at the standard limit
        when(
          () => mockEngagementRepository.readAll(
            userId: standardUser.id,
            filter: any(named: 'filter'),
            pagination: any(named: 'pagination'),
          ),
        ).thenAnswer(
          (_) async => PaginatedResponse(
            items: List.generate(
              10,
              (i) => Engagement(
                id: 'e$i',
                userId: 'standard',
                entityId: 'h$i',
                entityType: EngageableType.headline,
                reaction: const Reaction(reactionType: ReactionType.like),
                createdAt: testDate,
                updatedAt: testDate,
              ),
            ),
            cursor: null,
            hasMore: false,
          ),
        );

        service.init(appBloc: mockAppBloc);

        expect(
          await service.checkAction(ContentAction.reactToContent),
          LimitationStatus.standardUserLimitReached,
        );
      },
    );

    test(
      'Standard user should be restricted if daily report limit reached',
      () async {
        when(() => mockAppBloc.state).thenReturn(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: standardUser,
            userContentPreferences: emptyPreferences,
            remoteConfig: mockRemoteConfig,
          ),
        );

        // Mock report count to be at the standard limit
        when(
          () => mockReportRepository.readAll(
            userId: standardUser.id,
            filter: any(named: 'filter'),
            pagination: any(named: 'pagination'),
          ),
        ).thenAnswer(
          (_) async => PaginatedResponse(
            items: List.generate(
              5,
              (i) => Report(
                id: 'r$i',
                reporterUserId: 'standard',
                entityType: ReportableEntity.headline,
                entityId: 'h$i',
                reason: 'spam',
                status: ModerationStatus.pendingReview,
                createdAt: testDate,
              ),
            ),
            cursor: null,
            hasMore: false,
          ),
        );

        service.init(appBloc: mockAppBloc);

        expect(
          await service.checkAction(ContentAction.submitReport),
          LimitationStatus.standardUserLimitReached,
        );
      },
    );

    test(
      'Standard user should be restricted if followed items limit reached',
      () async {
        final filledPreferences = emptyPreferences.copyWith(
          followedTopics: List.generate(
            5, // Limit is 5
            (i) => Topic(
              id: '$i',
              name: 't',
              description: 'd',
              iconUrl: 'i',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              status: ContentStatus.active,
            ),
          ),
        );

        when(() => mockAppBloc.state).thenReturn(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: standardUser,
            userContentPreferences: filledPreferences,
            remoteConfig: mockRemoteConfig,
          ),
        );

        service.init(appBloc: mockAppBloc);

        expect(
          await service.checkAction(ContentAction.followTopic),
          LimitationStatus.standardUserLimitReached,
        );
      },
    );

    test(
      'Standard user should be restricted if saved filter limit reached',
      () async {
        final filledPreferences = emptyPreferences.copyWith(
          savedHeadlineFilters: List.generate(
            2, // Limit is 2
            (i) => SavedHeadlineFilter(
              id: '$i',
              userId: 'standard',
              name: 'filter',
              criteria: const HeadlineFilterCriteria(
                topics: [],
                sources: [],
                countries: [],
              ),
              isPinned: false,
              deliveryTypes: const {},
            ),
          ),
        );

        when(() => mockAppBloc.state).thenReturn(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: standardUser,
            userContentPreferences: filledPreferences,
            remoteConfig: mockRemoteConfig,
          ),
        );

        service.init(appBloc: mockAppBloc);

        expect(
          await service.checkAction(ContentAction.saveFilter),
          LimitationStatus.standardUserLimitReached,
        );
      },
    );

    test(
      'allows action and schedules retry when initial fetch fails',
      () async {
        when(() => mockAppBloc.state).thenReturn(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: standardUser,
            userContentPreferences: emptyPreferences,
            remoteConfig: mockRemoteConfig,
          ),
        );

        // Simulate a network failure during the initial count fetch.
        when(
          () => mockEngagementRepository.readAll(
            userId: any(named: 'userId'),
            filter: any(named: 'filter'),
            pagination: any(named: 'pagination'),
          ),
        ).thenThrow(const NetworkException());

        // Initialize the service, which will trigger the failing fetch.
        service.init(appBloc: mockAppBloc);
        await Future<void>.delayed(
          Duration.zero,
        ); // Allow async operations to complete.

        // The service should now be in a 'failed' state and allow the action.
        final status = await service.checkAction(ContentAction.reactToContent);
        expect(status, LimitationStatus.allowed);

        // Verify that a retry was scheduled.
        verify(
          () => mockLogger.info(
            any(that: contains('Scheduling daily count fetch retry')),
          ),
        ).called(1);
      },
    );

    test(
      'invalidateAndForceRefresh clears cache and triggers a new fetch',
      () async {
        // Arrange
        when(() => mockAppBloc.state).thenReturn(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: standardUser,
            userContentPreferences: emptyPreferences,
            remoteConfig: mockRemoteConfig,
          ),
        );
        // Initial fetch is successful (default mock)
        service.init(appBloc: mockAppBloc);
        await Future<void>.delayed(
          Duration.zero,
        ); // Allow initial fetch to complete

        // Verify initial fetch happened and clear mocks for next verification
        verify(
          () => mockEngagementRepository.readAll(
            userId: standardUser.id,
            filter: any(named: 'filter'),
            pagination: any(named: 'pagination'),
          ),
        ).called(1);
        verify(
          () => mockReportRepository.readAll(
            userId: standardUser.id,
            filter: any(named: 'filter'),
            pagination: any(named: 'pagination'),
          ),
        ).called(1);
        clearInteractions(mockEngagementRepository);
        clearInteractions(mockReportRepository);

        // Act
        service.invalidateAndForceRefresh();
        await Future<void>.delayed(Duration.zero); // Allow refresh to complete

        // Assert
        // Verify that a new fetch was triggered
        verify(
          () => mockEngagementRepository.readAll(
            userId: standardUser.id,
            filter: any(named: 'filter'),
            pagination: any(named: 'pagination'),
          ),
        ).called(1);
        verify(
          () => mockReportRepository.readAll(
            userId: standardUser.id,
            filter: any(named: 'filter'),
            pagination: any(named: 'pagination'),
          ),
        ).called(1);
      },
    );

    test('triggers background refresh when cache is stale', () async {
      // Arrange
      // Create a service instance with a zero duration cache for this test
      final shortCacheService = ContentLimitationService(
        engagementRepository: mockEngagementRepository,
        reportRepository: mockReportRepository,
        analyticsService: mockAnalyticsService,
        cacheDuration: Duration.zero, // Stale immediately
        logger: mockLogger,
      );

      when(() => mockAppBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.authenticated,
          user: standardUser,
          userContentPreferences: emptyPreferences,
          remoteConfig: mockRemoteConfig,
        ),
      );

      // Initial fetch
      shortCacheService.init(appBloc: mockAppBloc);
      await Future<void>.delayed(Duration.zero);
      verify(
        () => mockEngagementRepository.readAll(
          userId: standardUser.id,
          filter: any(named: 'filter'),
          pagination: any(named: 'pagination'),
        ),
      ).called(1);
      clearInteractions(mockEngagementRepository);

      // Act
      // Call checkAction, which should find the cache is stale and trigger a refresh
      await shortCacheService.checkAction(ContentAction.reactToContent);
      await Future<void>.delayed(
        Duration.zero,
      ); // Allow async refresh to be called

      // Assert
      // Verify that a second fetch was triggered
      verify(
        () => mockEngagementRepository.readAll(
          userId: standardUser.id,
          filter: any(named: 'filter'),
          pagination: any(named: 'pagination'),
        ),
      ).called(1);
      verify(
        () => mockLogger.info(
          any(
            that: contains(
              'Daily count cache is stale. Triggering background refresh.',
            ),
          ),
        ),
      ).called(1);
    });
  });
}
