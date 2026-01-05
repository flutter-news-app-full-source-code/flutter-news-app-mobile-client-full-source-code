import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/initialization_result.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_initializer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/services/feed_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/services/push_notification_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/subscriptions/services/purchase_handler.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/services/app_review_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockAppInitializer extends Mock implements AppInitializer {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDataRepository<T> extends Mock implements DataRepository<T> {}

class MockLogger extends Mock implements Logger {}

class MockInlineAdCacheService extends Mock implements InlineAdCacheService {}

class MockFeedCacheService extends Mock implements FeedCacheService {}

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

class MockContentLimitationService extends Mock
    implements ContentLimitationService {}

class MockAppReviewService extends Mock implements AppReviewService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockPurchaseHandler extends Mock implements PurchaseHandler {}

void main() {
  group('AppBloc', () {
    late AppInitializer appInitializer;
    late AuthRepository authRepository;
    late Logger logger;
    late InlineAdCacheService inlineAdCacheService;
    late FeedCacheService feedCacheService;
    late PushNotificationService pushNotificationService;
    late ContentLimitationService contentLimitationService;
    late AppReviewService appReviewService;
    late AnalyticsService analyticsService;
    late PurchaseHandler purchaseHandler;
    late DataRepository<UserSubscription> userSubscriptionRepository;

    final remoteConfig = RemoteConfig(
      id: 'id',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
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
      features: FeaturesConfig(
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
        analytics: const AnalyticsConfig(
          enabled: true,
          activeProvider: AnalyticsProviders.firebase,
          disabledEvents: {},
          eventSamplingRates: {},
        ),
        ads: const AdConfig(
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
        feed: const FeedConfig(
          itemClickBehavior: FeedItemClickBehavior.internalNavigation,
          decorators: {},
        ),
        pushNotifications: const PushNotificationConfig(
          enabled: true,
          primaryProvider: PushNotificationProviders.firebase,
          deliveryConfigs: {},
        ),
        community: const CommunityConfig(
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
      ),
    );

    setUp(() {
      appInitializer = MockAppInitializer();
      authRepository = MockAuthRepository();
      logger = MockLogger();
      inlineAdCacheService = MockInlineAdCacheService();
      feedCacheService = MockFeedCacheService();
      pushNotificationService = MockPushNotificationService();
      contentLimitationService = MockContentLimitationService();
      appReviewService = MockAppReviewService();
      analyticsService = MockAnalyticsService();
      purchaseHandler = MockPurchaseHandler();
      userSubscriptionRepository = MockDataRepository<UserSubscription>();

      when(
        () => pushNotificationService.onTokenRefreshed,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => pushNotificationService.onMessage,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => purchaseHandler.purchaseCompleted,
      ).thenAnswer((_) => const Stream.empty());
    });

    AppBloc buildBloc() => AppBloc(
      appInitializer: appInitializer,
      authRepository: authRepository,
      appSettingsRepository: MockDataRepository<AppSettings>(),
      userContentPreferencesRepository:
          MockDataRepository<UserContentPreferences>(),
      userContextRepository: MockDataRepository<UserContext>(),
      userSubscriptionRepository: userSubscriptionRepository,
      remoteConfigRepository: MockDataRepository<RemoteConfig>(),
      inlineAdCacheService: inlineAdCacheService,
      feedCacheService: feedCacheService,
      pushNotificationService: pushNotificationService,
      reportRepository: MockDataRepository<Report>(),
      contentLimitationService: contentLimitationService,
      inAppNotificationRepository: MockDataRepository<InAppNotification>(),
      appReviewService: appReviewService,
      analyticsService: analyticsService,
      purchaseHandler: purchaseHandler,
      remoteConfig: remoteConfig,
      user: null,
      settings: null,
      userContentPreferences: null,
      userContext: null,
      userSubscription: null,
      logger: logger,
    );

    test('initial state is correct', () {
      final bloc = buildBloc();
      expect(bloc.state.status, AppLifeCycleStatus.unauthenticated);
      bloc.close();
    });

    blocTest<AppBloc, AppState>(
      'emits authenticated status when user changes',
      build: () {
        final user = User(
          id: '1',
          email: 'e',
          role: UserRole.user,
          tier: AccessTier.standard,
          createdAt: DateTime(2025),
        );
        final success = InitializationSuccess(
          remoteConfig: remoteConfig,
          user: user,
          settings: null,
          userContentPreferences: null,
          userContext: null,
          userSubscription: null,
        );
        when(
          () => appInitializer.handleUserTransition(
            oldUser: any(named: 'oldUser'),
            newUser: user,
            remoteConfig: remoteConfig,
          ),
        ).thenAnswer((_) async => success);
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        AppUserChanged(
          User(
            id: '1',
            email: 'e',
            role: UserRole.user,
            tier: AccessTier.standard,
            createdAt: DateTime(2025),
          ),
        ),
      ),
      expect: () => [
        isA<AppState>().having(
          (s) => s.status,
          'status',
          AppLifeCycleStatus.loadingUserData,
        ),
        isA<AppState>().having(
          (s) => s.status,
          'status',
          AppLifeCycleStatus.authenticated,
        ),
      ],
    );
  });
}
