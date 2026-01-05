// ignore_for_file: strict_raw_type

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

void main() {
  late ContentLimitationService service;
  late MockEngagementRepository mockEngagementRepository;
  late MockReportRepository mockReportRepository;
  late MockAnalyticsService mockAnalyticsService;
  late MockAppBloc mockAppBloc;
  late MockLogger mockLogger;

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

    // Default stubs to prevent Null subtype errors and Future.wait failures
    // during service initialization.
    when(
      () => mockEngagementRepository.count(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
      ),
    ).thenAnswer((_) async => 0);
    when(
      () => mockReportRepository.count(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
      ),
    ).thenAnswer((_) async => 0);

    // Default stubs to prevent Null subtype errors and Future.wait failures
    when(
      () =>
          mockAnalyticsService.logEvent(any(), payload: any(named: 'payload')),
    ).thenAnswer((_) async {});
    when(
      () => mockReportRepository.count(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
      ),
    ).thenAnswer((_) async => 0);
  });

  group('ContentLimitationService', () {
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

    final premiumUser = User(
      id: 'premium',
      email: 'premium@example.com',
      role: UserRole.user,
      tier: AccessTier.premium,
      createdAt: DateTime.now(),
      isAnonymous: false,
    );

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
        subscription: SubscriptionConfig(
          enabled: true,
          monthlyPlan: PlanDetails(
            enabled: true,
            isRecommended: false,
            googleProductId: 'monthly_id',
          ),
          annualPlan: PlanDetails(
            enabled: true,
            isRecommended: true,
            googleProductId: 'annual_id',
          ),
        ),
      ),
      user: const UserConfig(
        limits: UserLimitsConfig(
          followedItems: {AccessTier.standard: 5},
          savedHeadlines: {AccessTier.standard: 10},
          savedHeadlineFilters: {
            AccessTier.standard: SavedFilterLimits(total: 2, pinned: 1),
          },
          savedSourceFilters: {
            AccessTier.standard: SavedFilterLimits(total: 2, pinned: 1),
          },
          commentsPerDay: {AccessTier.standard: 3},
          reactionsPerDay: {AccessTier.standard: 10},
          reportsPerDay: {AccessTier.standard: 5},
        ),
      ),
    );

    final mockRemoteConfigWithPremiumLimits = mockRemoteConfig.copyWith(
      user: const UserConfig(
        limits: UserLimitsConfig(
          followedItems: {AccessTier.standard: 5, AccessTier.premium: 50},
          savedHeadlines: {AccessTier.standard: 10, AccessTier.premium: 100},
          savedHeadlineFilters: {
            AccessTier.standard: SavedFilterLimits(total: 2, pinned: 1),
            AccessTier.premium: SavedFilterLimits(total: 20, pinned: 10),
          },
          savedSourceFilters: {
            AccessTier.standard: SavedFilterLimits(total: 2, pinned: 1),
            AccessTier.premium: SavedFilterLimits(total: 20, pinned: 10),
          },
          commentsPerDay: {AccessTier.standard: 3, AccessTier.premium: 100},
          reactionsPerDay: {AccessTier.standard: 10, AccessTier.premium: 200},
          reportsPerDay: {AccessTier.standard: 5, AccessTier.premium: 20},
        ),
      ),
    );

    test('Guest user should be restricted from engagement actions', () async {
      when(() => mockAppBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.anonymous,
          user: guestUser,
          userContentPreferences: emptyPreferences,
          remoteConfig: mockRemoteConfig,
        ),
      );

      service.init(appBloc: mockAppBloc);

      expect(
        await service.checkAction(ContentAction.postComment),
        LimitationStatus.anonymousLimitReached,
      );
      expect(
        await service.checkAction(ContentAction.reactToContent),
        LimitationStatus.anonymousLimitReached,
      );
      expect(
        await service.checkAction(ContentAction.submitReport),
        LimitationStatus.anonymousLimitReached,
      );
    });

    test('Premium user should be allowed if no limit is configured', () async {
      when(() => mockAppBloc.state).thenReturn(
        AppState(
          status: AppLifeCycleStatus.authenticated,
          user: premiumUser,
          userContentPreferences: emptyPreferences,
          remoteConfig: mockRemoteConfig,
        ),
      );

      // Mock high usage to ensure limits are ignored because they are not
      // configured for premium in the default mockRemoteConfig.
      when(
        () => mockEngagementRepository.count(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer((_) async => 100);

      service.init(appBloc: mockAppBloc);

      expect(
        await service.checkAction(ContentAction.postComment),
        LimitationStatus.allowed,
      );
      expect(
        await service.checkAction(ContentAction.bookmarkHeadline),
        LimitationStatus.allowed,
      );
    });

    test(
      'Premium user should be restricted if premium daily limit reached',
      () async {
        when(() => mockAppBloc.state).thenReturn(
          AppState(
            status: AppLifeCycleStatus.authenticated,
            user: premiumUser,
            userContentPreferences: emptyPreferences,
            remoteConfig: mockRemoteConfigWithPremiumLimits,
          ),
        );

        // Mock comment count to be at the premium limit
        when(
          () => mockEngagementRepository.count(
            userId: premiumUser.id,
            filter: any(
              named: 'filter',
              that: containsPair('comment', isA<Map>()),
            ),
          ),
        ).thenAnswer((_) async => 100); // Premium comment limit is 100

        // Mock other counts to be zero to not interfere
        when(
          () => mockEngagementRepository.count(
            userId: premiumUser.id,
            filter: any(
              named: 'filter',
              that: containsPair('reaction', isA<Map>()),
            ),
          ),
        ).thenAnswer((_) async => 0);

        service.init(appBloc: mockAppBloc);

        expect(
          await service.checkAction(ContentAction.postComment),
          LimitationStatus.premiumUserLimitReached,
        );
      },
    );

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
      when(
        () => mockEngagementRepository.count(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer((_) async => 0);
      when(
        () => mockReportRepository.count(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer((_) async => 0);

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
        () => mockEngagementRepository.count(
          userId: standardUser.id,
          filter: any(
            named: 'filter',
            that: containsPair('comment', isA<Map>()),
          ),
        ),
      ).thenAnswer((_) async => 3);

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
          () => mockEngagementRepository.count(
            userId: standardUser.id,
            filter: any(
              named: 'filter',
              that: containsPair('reaction', isA<Map>()),
            ),
          ),
        ).thenAnswer((_) async => 10); // Standard reaction limit is 10

        // Mock other counts to be zero
        when(
          () => mockEngagementRepository.count(
            userId: standardUser.id,
            filter: any(
              named: 'filter',
              that: containsPair('comment', isA<Map>()),
            ),
          ),
        ).thenAnswer((_) async => 0);

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
          () => mockReportRepository.count(
            userId: standardUser.id,
            filter: any(named: 'filter'),
          ),
        ).thenAnswer((_) async => 5); // Standard report limit is 5

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
  });
}
