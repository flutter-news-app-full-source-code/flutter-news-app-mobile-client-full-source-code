import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/initialization_result.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_initializer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/package_info_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDataRepository<T> extends Mock implements DataRepository<T> {}

class MockPackageInfoService extends Mock implements PackageInfoService {}

class MockLogger extends Mock implements Logger {}

void main() {
  group('AppInitializer', () {
    late AuthRepository authRepository;
    late DataRepository<AppSettings> appSettingsRepository;
    late DataRepository<UserContentPreferences>
    userContentPreferencesRepository;
    late DataRepository<UserContext> userContextRepository;
    late DataRepository<UserSubscription> userSubscriptionRepository;
    late DataRepository<RemoteConfig> remoteConfigRepository;
    late PackageInfoService packageInfoService;
    late Logger logger;
    late AppInitializer appInitializer;

    const kRemoteConfigId = 'remote-config';

    final remoteConfigBase = RemoteConfig(
      id: kRemoteConfigId,
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
      authRepository = MockAuthRepository();
      appSettingsRepository = MockDataRepository<AppSettings>();
      userContentPreferencesRepository =
          MockDataRepository<UserContentPreferences>();
      userContextRepository = MockDataRepository<UserContext>();
      userSubscriptionRepository = MockDataRepository<UserSubscription>();
      remoteConfigRepository = MockDataRepository<RemoteConfig>();
      packageInfoService = MockPackageInfoService();
      logger = MockLogger();

      appInitializer = AppInitializer(
        authenticationRepository: authRepository,
        appSettingsRepository: appSettingsRepository,
        userContentPreferencesRepository: userContentPreferencesRepository,
        userContextRepository: userContextRepository,
        userSubscriptionRepository: userSubscriptionRepository,
        remoteConfigRepository: remoteConfigRepository,
        packageInfoService: packageInfoService,
        logger: logger,
      );

      when(
        () => remoteConfigRepository.read(id: any(named: 'id')),
      ).thenAnswer((_) => Future.value(remoteConfigBase));
      when(
        () => packageInfoService.getAppVersion(),
      ).thenAnswer((_) async => '1.0.0');
    });

    AppSettings createSettings(String id) => AppSettings(
      id: id,
      language: Language(
        id: 'en',
        name: 'English',
        nativeName: 'English',
        code: 'en',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        status: ContentStatus.active,
      ),
      displaySettings: const DisplaySettings(
        baseTheme: AppBaseTheme.system,
        accentTheme: AppAccentTheme.defaultBlue,
        fontFamily: 'SystemDefault',
        fontWeight: AppFontWeight.regular,
        textScaleFactor: AppTextScaleFactor.medium,
      ),
      feedSettings: const FeedSettings(
        feedItemDensity: FeedItemDensity.comfortable,
        feedItemImageStyle: FeedItemImageStyle.smallThumbnail,
        feedItemClickBehavior: FeedItemClickBehavior.internalNavigation,
      ),
    );

    UserContentPreferences createPreferences(String id) =>
        UserContentPreferences(
          id: id,
          followedCountries: const [],
          followedSources: const [],
          followedTopics: const [],
          savedHeadlineFilters: const [],
          savedSourceFilters: const [],
          savedHeadlines: [],
        );

    UserContext createContext(String userId) =>
        UserContext(userId: userId, feedDecoratorStatus: const {}, id: '');

    group('initializeApp', () {
      test('Success: Full Hydration (Authenticated)', () async {
        const userId = 'user-123';
        final user = User(
          id: userId,
          email: 'test@news.com',
          role: UserRole.user,
          tier: AccessTier.standard,
          createdAt: DateTime(2025),
        );

        when(
          () => authRepository.getCurrentUser(),
        ).thenAnswer((_) async => user);
        when(
          () => appSettingsRepository.read(id: userId, userId: userId),
        ).thenAnswer((_) async => createSettings(userId));
        when(
          () =>
              userContentPreferencesRepository.read(id: userId, userId: userId),
        ).thenAnswer((_) async => createPreferences(userId));
        when(
          () => userContextRepository.read(id: userId, userId: userId),
        ).thenAnswer((_) async => createContext(userId));
        when(
          () => userSubscriptionRepository.readAll(
            userId: userId,
            filter: any(named: 'filter'),
            pagination: any(named: 'pagination'),
          ),
        ).thenAnswer(
          (_) async => const PaginatedResponse<UserSubscription>(
            items: [],
            cursor: null,
            hasMore: false,
          ),
        );

        final result = await appInitializer.initializeApp();

        expect(result, isA<InitializationSuccess>());
        expect((result as InitializationSuccess).user, user);
      });

      test('Success: Anonymous Entry', () async {
        when(
          () => authRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);

        final result = await appInitializer.initializeApp();

        expect(result, isA<InitializationSuccess>());
        expect((result as InitializationSuccess).user, isNull);
      });

      test('Failure: Under Maintenance', () async {
        final maintenanceMocks = remoteConfigBase.copyWith(
          app: remoteConfigBase.app.copyWith(
            maintenance: const MaintenanceConfig(isUnderMaintenance: true),
          ),
        );
        when(
          () => remoteConfigRepository.read(id: any(named: 'id')),
        ).thenAnswer((_) => Future.value(maintenanceMocks));

        final result = await appInitializer.initializeApp();

        expect(result, isA<InitializationFailure>());
        expect(
          (result as InitializationFailure).status,
          AppLifeCycleStatus.underMaintenance,
        );
      });
    });
  });
}
