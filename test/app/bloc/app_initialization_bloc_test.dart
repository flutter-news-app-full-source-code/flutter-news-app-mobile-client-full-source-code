import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_initialization_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/initialization_result.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_initializer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockAppInitializer extends Mock implements AppInitializer {}

class MockLogger extends Mock implements Logger {}

void main() {
  group('AppInitializationBloc', () {
    late AppInitializer appInitializer;
    late Logger logger;

    final successResult = InitializationSuccess(
      remoteConfig: RemoteConfig(
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
        ),
      ),
      user: User(
        id: 'user-123',
        email: 'test@example.com',
        role: UserRole.user,
        tier: AccessTier.standard,
        createdAt: DateTime(2025),
        isAnonymous: false,
      ),
      settings: AppSettings(
        id: 'user-123',
        language: Language(
          id: 'en',
          name: 'English',
          nativeName: 'English',
          code: 'en',
          status: ContentStatus.active,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
        displaySettings: const DisplaySettings(
          baseTheme: AppBaseTheme.system,
          accentTheme: AppAccentTheme.defaultBlue,
          fontFamily: '',
          textScaleFactor: AppTextScaleFactor.medium,
          fontWeight: AppFontWeight.regular,
        ),
        feedSettings: const FeedSettings(
          feedItemDensity: FeedItemDensity.comfortable,
          feedItemImageStyle: FeedItemImageStyle.smallThumbnail,
          feedItemClickBehavior: FeedItemClickBehavior.internalNavigation,
        ),
      ),
      userContentPreferences: const UserContentPreferences(
        id: 'user-123',
        followedCountries: [],
        followedSources: [],
        followedTopics: [],
        savedHeadlineFilters: [],
        savedSourceFilters: [],
        savedHeadlines: [],
      ),
      userContext: const UserContext(
        userId: 'user-123',
        feedDecoratorStatus: {},
        id: 'ctx-123',
      ),
      userSubscription: null,
    );

    setUp(() {
      appInitializer = MockAppInitializer();
      logger = MockLogger();
    });

    blocTest<AppInitializationBloc, AppInitializationState>(
      'emits [InProgress, Succeeded] when initialization is successful',
      build: () {
        when(
          () => appInitializer.initializeApp(),
        ).thenAnswer((_) async => successResult);
        return AppInitializationBloc(
          appInitializer: appInitializer,
          logger: logger,
        );
      },
      act: (bloc) => bloc.add(const AppInitializationStarted()),
      expect: () => [
        const AppInitializationInProgress(),
        AppInitializationSucceeded(successResult),
      ],
    );

    blocTest<AppInitializationBloc, AppInitializationState>(
      'emits [InProgress, Failed] when initialization fails',
      build: () {
        const failure = InitializationFailure(
          status: AppLifeCycleStatus.underMaintenance,
          error: const HttpException('Maintenance'),
        );
        when(
          () => appInitializer.initializeApp(),
        ).thenAnswer((_) async => failure);
        return AppInitializationBloc(
          appInitializer: appInitializer,
          logger: logger,
        );
      },
      act: (bloc) => bloc.add(const AppInitializationStarted()),
      expect: () => [
        const AppInitializationInProgress(),
        isA<AppInitializationFailed>(),
      ],
    );
  });
}
