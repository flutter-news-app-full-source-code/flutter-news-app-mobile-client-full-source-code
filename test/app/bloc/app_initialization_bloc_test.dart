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
          pushNotifications: const PushNotificationConfig(
            enabled: true,
            primaryProvider: PushNotificationProviders.firebase,
            deliveryConfigs: {},
          ),
          feed: const FeedConfig(
            itemClickBehavior: FeedItemClickBehavior.internalNavigation,
            decorators: {},
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
      ),
      user: null,
      settings: null,
      userContentPreferences: null,
      userContext: null,
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
        final failure = InitializationFailure(
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
