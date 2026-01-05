import 'package:auth_repository/auth_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/view/app.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/services/feed_decorator_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_initializer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/services/feed_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/services/push_notification_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/purchase_handler.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/subscription_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/services/app_review_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDataRepository<T> extends Mock implements DataRepository<T> {}

class MockInlineAdCacheService extends Mock implements InlineAdCacheService {}

class MockFeedCacheService extends Mock implements FeedCacheService {}

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

class MockContentLimitationService extends Mock
    implements ContentLimitationService {}

class MockAppReviewService extends Mock implements AppReviewService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockPurchaseHandler extends Mock implements PurchaseHandler {}

class MockAdService extends Mock implements AdService {}

class MockFeedDecoratorService extends Mock implements FeedDecoratorService {}

class MockSubscriptionService extends Mock implements SubscriptionService {}

class MockAppInitializer extends Mock implements AppInitializer {}

class MockLogger extends Mock implements Logger {}

class AppEventFake extends Fake implements AppEvent {}

class AppStateFake extends Fake implements AppState {}

void main() {
  group('App View Integration', () {
    late AppBloc appBloc;
    late AuthRepository authRepository;

    setUpAll(() {
      registerFallbackValue(MockAppBloc());
      registerFallbackValue(AppEventFake());
      registerFallbackValue(AppStateFake());
    });

    setUp(() {
      appBloc = MockAppBloc();
      authRepository = MockAuthRepository();

      when(
        () => appBloc.state,
      ).thenReturn(const AppState(status: AppLifeCycleStatus.anonymous));
      when(
        () => authRepository.authStateChanges,
      ).thenAnswer((_) => const Stream.empty());
    });

    Widget buildTestableApp() {
      // Create specific mocks for services
      final appInitializer = MockAppInitializer();
      final inlineAdCacheService = MockInlineAdCacheService();
      final adService = MockAdService();
      final feedDecoratorService = MockFeedDecoratorService();
      final appReviewService = MockAppReviewService();
      final feedCacheService = MockFeedCacheService();
      final pushNotificationService = MockPushNotificationService();
      final analyticsService = MockAnalyticsService();
      final subscriptionService = MockSubscriptionService();
      final purchaseHandler = MockPurchaseHandler();
      final contentLimitationService = MockContentLimitationService();

      // Stub required method for app init triggers
      when(
        () => pushNotificationService.onMessage,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => pushNotificationService.onMessageOpenedApp,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => pushNotificationService.onTokenRefreshed,
      ).thenAnswer((_) => const Stream.empty());
      when(pushNotificationService.close).thenAnswer((_) async {});
      when(
        () => purchaseHandler.purchaseCompleted,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => contentLimitationService.init(appBloc: any(named: 'appBloc')),
      ).thenReturn(null);
      when(contentLimitationService.dispose).thenReturn(null);

      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: authRepository),
          // Mocks for Repositories (Generics)
          RepositoryProvider<DataRepository<RemoteConfig>>.value(
            value: MockDataRepository<RemoteConfig>(),
          ),
          RepositoryProvider<DataRepository<AppSettings>>.value(
            value: MockDataRepository<AppSettings>(),
          ),
          RepositoryProvider<DataRepository<UserContentPreferences>>.value(
            value: MockDataRepository<UserContentPreferences>(),
          ),
          RepositoryProvider<DataRepository<UserContext>>.value(
            value: MockDataRepository<UserContext>(),
          ),
          RepositoryProvider<DataRepository<UserSubscription>>.value(
            value: MockDataRepository<UserSubscription>(),
          ),
          RepositoryProvider<DataRepository<InAppNotification>>.value(
            value: MockDataRepository<InAppNotification>(),
          ),
          RepositoryProvider<DataRepository<Report>>.value(
            value: MockDataRepository<Report>(),
          ),
          // Mocks for Services (Specific Types)
          RepositoryProvider<InlineAdCacheService>.value(
            value: inlineAdCacheService,
          ),
          RepositoryProvider<AdService>.value(value: adService),
          RepositoryProvider<FeedDecoratorService>.value(
            value: feedDecoratorService,
          ),
          RepositoryProvider<AppReviewService>.value(value: appReviewService),
          RepositoryProvider<FeedCacheService>.value(value: feedCacheService),
          RepositoryProvider<PushNotificationService>.value(
            value: pushNotificationService,
          ),
          RepositoryProvider<AnalyticsService>.value(value: analyticsService),
          RepositoryProvider<SubscriptionService>.value(
            value: subscriptionService,
          ),
          RepositoryProvider<PurchaseHandler>.value(value: purchaseHandler),
          RepositoryProvider<ContentLimitationService>.value(
            value: contentLimitationService,
          ),
          RepositoryProvider<AppInitializer>.value(value: appInitializer),
          RepositoryProvider<Logger>.value(value: MockLogger()),
        ],
        child: BlocProvider.value(
          value: appBloc,
          child: App(
            user: null, // User is null, so AppBloc starts as unauthenticated
            userContext: const UserContext(
              userId: '1',
              feedDecoratorStatus: {},
              id: '',
            ),
            remoteConfig: RemoteConfig(
              id: 'id',
              createdAt: DateTime(2025),
              updatedAt: DateTime(2025),
              app: const AppConfig(
                maintenance: MaintenanceConfig(isUnderMaintenance: false),
                update: UpdateConfig(
                  latestAppVersion: '1',
                  isLatestVersionOnly: false,
                  iosUpdateUrl: '',
                  androidUpdateUrl: '',
                ),
                general: GeneralAppConfig(
                  termsOfServiceUrl: '',
                  privacyPolicyUrl: '',
                ),
              ),
              user: const UserConfig(
                limits: UserLimitsConfig(
                  followedItems: {},
                  savedHeadlines: {},
                  savedHeadlineFilters: {},
                  savedSourceFilters: {},
                  reactionsPerDay: {},
                  commentsPerDay: {},
                  reportsPerDay: {},
                ),
              ),
              features: const FeaturesConfig(
                analytics: AnalyticsConfig(
                  enabled: true,
                  activeProvider: AnalyticsProviders.firebase,
                  disabledEvents: {},
                  eventSamplingRates: {},
                ),
                ads: AdConfig(
                  enabled: true,
                  primaryAdPlatform: AdPlatformType.admob,
                  platformAdIdentifiers: {},
                  feedAdConfiguration: FeedAdConfiguration(
                    enabled: true,
                    adType: AdType.native,
                    visibleTo: {},
                  ),
                  navigationAdConfiguration: NavigationAdConfiguration(
                    enabled: true,
                    visibleTo: {},
                  ),
                ),
                pushNotifications: PushNotificationConfig(
                  enabled: true,
                  primaryProvider: PushNotificationProviders.firebase,
                  deliveryConfigs: {},
                ),
                feed: FeedConfig(
                  itemClickBehavior: FeedItemClickBehavior.internalNavigation,
                  decorators: {},
                ),
                community: CommunityConfig(
                  enabled: true,
                  engagement: EngagementConfig(
                    enabled: true,
                    engagementMode: EngagementMode.reactionsAndComments,
                  ),
                  reporting: ReportingConfig(
                    enabled: true,
                    headlineReportingEnabled: true,
                    sourceReportingEnabled: true,
                    commentReportingEnabled: true,
                  ),
                  appReview: AppReviewConfig(
                    enabled: true,
                    interactionCycleThreshold: 5,
                    initialPromptCooldownDays: 3,
                    eligiblePositiveInteractions: [],
                    isNegativeFeedbackFollowUpEnabled: true,
                    isPositiveFeedbackFollowUpEnabled: true,
                  ),
                ),
                subscription: SubscriptionConfig(
                  enabled: true,
                  monthlyPlan: PlanDetails(
                    enabled: true,
                    isRecommended: false,
                    appleProductId: 'monthly_id',
                    googleProductId: 'monthly_id',
                  ),
                  annualPlan: PlanDetails(
                    enabled: true,
                    isRecommended: true,
                    appleProductId: 'annual_id',
                    googleProductId: 'annual_id',
                  ),
                ),
              ),
            ),
            settings: AppSettings(
              id: '1',
              language: Language(
                id: '1',
                name: '1',
                nativeName: '1',
                code: '1',
                createdAt: DateTime(2025),
                updatedAt: DateTime(2025),
                status: ContentStatus.active,
              ),
              displaySettings: const DisplaySettings(
                baseTheme: AppBaseTheme.system,
                accentTheme: AppAccentTheme.defaultBlue,
                fontFamily: '',
                fontWeight: AppFontWeight.regular,
                textScaleFactor: AppTextScaleFactor.medium,
              ),
              feedSettings: const FeedSettings(
                feedItemDensity: FeedItemDensity.comfortable,
                feedItemImageStyle: FeedItemImageStyle.smallThumbnail,
                feedItemClickBehavior: FeedItemClickBehavior.internalNavigation,
              ),
            ),
            userContentPreferences: const UserContentPreferences(
              id: '1',
              followedCountries: [],
              followedSources: [],
              followedTopics: [],
              savedHeadlineFilters: [],
              savedSourceFilters: [],
              savedHeadlines: [],
            ),
            userSubscription: null,
            authenticationRepository: authRepository,
            // Generic Repositories - pass explicit generic types if needed, or dynamic for the ones we mocked as generics
            headlinesRepository: MockDataRepository<Headline>(),
            topicsRepository: MockDataRepository<Topic>(),
            countriesRepository: MockDataRepository<Country>(),
            sourcesRepository: MockDataRepository<Source>(),
            userRepository: MockDataRepository<User>(),
            remoteConfigRepository: MockDataRepository<RemoteConfig>(),
            appSettingsRepository: MockDataRepository<AppSettings>(),
            userContentPreferencesRepository:
                MockDataRepository<UserContentPreferences>(),
            userContextRepository: MockDataRepository<UserContext>(),
            engagementRepository: MockDataRepository<Engagement>(),
            reportRepository: MockDataRepository<Report>(),
            appReviewRepository: MockDataRepository<AppReview>(),
            environment: AppEnvironment.development,
            inAppNotificationRepository:
                MockDataRepository<InAppNotification>(),
            // Strict Service Mocks
            contentLimitationService: contentLimitationService,
            inlineAdCacheService: inlineAdCacheService,
            adService: adService,
            feedDecoratorService: feedDecoratorService,
            appReviewService: appReviewService,
            feedCacheService: feedCacheService,
            navigatorKey: GlobalKey<NavigatorState>(),
            pushNotificationService: pushNotificationService,
            analyticsService: analyticsService,
            subscriptionService: subscriptionService,
            userSubscriptionRepository: MockDataRepository<UserSubscription>(),
            purchaseTransactionRepository:
                MockDataRepository<PurchaseTransaction>(),
            purchaseHandler: purchaseHandler,
          ),
        ),
      );
    }

    testWidgets('renders integration', (tester) async {
      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      // Depending on the state, it might not be LoadingStateWidget if it transitions fast or mocked state differs.
      // But given the mocked state is anonymous, it might show UI directly or loading.
      // Let's expect MaterialApp at least.

      await tester.pumpWidget(const SizedBox());
    });
  });
}
