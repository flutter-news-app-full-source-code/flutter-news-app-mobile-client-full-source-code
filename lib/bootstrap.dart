import 'package:auth_api/auth_api.dart';
import 'package:auth_client/auth_client.dart';
import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart';
import 'package:data_api/data_api.dart';
import 'package:data_client/data_client.dart';
import 'package:data_repository/data_repository.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/providers/ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/providers/admob_ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/providers/no_op_ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/providers/analytics_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/providers/firebase_analytics_provider.dart'
    as analytics_firebase;
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/providers/mixpanel_analytics_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/providers/no_op_analytics_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/config.dart'
    as app_config;
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_initializer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/package_info_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/view/app_initialization_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/bloc_observer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/services/feed_decorator_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/services/feed_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/media/client/media_api.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/push_notification/providers/firebase_push_notification_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/push_notification/providers/no_op_push_notification_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/push_notification/providers/one_signal_push_notification_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/push_notification/providers/push_notification_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/push_notification/services/push_notification_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/push_notification/services/push_notification_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/services/app_review_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/services/in_app_review_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/services/native_review_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/app_review/services/no_op_native_review_service.dart';
import 'package:http_client/http_client.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:kv_storage_service/kv_storage_service.dart';
import 'package:kv_storage_shared_preferences/kv_storage_shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ui_kit/ui_kit.dart';

Future<Widget> bootstrap(
  app_config.AppConfig appConfig,
  app_config.AppEnvironment environment,
) async {
  if (kIsWeb) {
    throw UnsupportedError('This application is not supported on the web.');
  }

  // Setup logging
  Logger.root.level = environment == app_config.AppEnvironment.production
      ? Level.INFO
      : Level.ALL;

  Logger.root.onRecord.listen((record) {
    final message = StringBuffer(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
    if (record.error != null) {
      message.write('\nError: ${record.error}');
    }
    if (record.stackTrace != null) {
      message.write('\nStack Trace: ${record.stackTrace}');
    }
    print(message);
  });

  final logger = Logger('bootstrap')
    ..config('--- Starting Bootstrap Process ---')
    ..config('App Environment: $environment');

  Bloc.observer = const AppBlocObserver();
  timeago.setLocaleMessages('en', EnTimeagoMessages());
  timeago.setLocaleMessages('ar', ArTimeagoMessages());

  logger.info('1. Initializing KV Storage Service...');
  // 1. Initialize KV Storage Service first, as it's a foundational dependency.
  final kvStorage = await KVStorageSharedPreferences.getInstance();
  logger.fine('KV Storage Service initialized (SharedPreferences).');

  // Initialize InlineAdCacheService early as it's a singleton and needs AdService.
  // It will be fully configured once AdService is available.
  InlineAdCacheService? inlineAdCacheService;

  // 2. Initialize HttpClient. Its tokenProvider now directly reads from
  // kvStorage, breaking the circular dependency with AuthRepository.
  logger.info('2. Initializing HttpClient...');
  // This HttpClient instance is used for all subsequent API calls, including
  // the initial unauthenticated fetch of RemoteConfig.
  final httpClient = HttpClient(
    baseUrl: appConfig.baseUrl,
    tokenProvider: () =>
        kvStorage.readString(key: StorageKey.authToken.stringValue),
    logger: logger,
  );

  logger
    ..fine('HttpClient initialized for base URL: ${appConfig.baseUrl}')
    ..info('3. Initializing RemoteConfig client and repository...');

  // 3. Initialize RemoteConfigClient and Repository, and fetch RemoteConfig.
  // This is done early because RemoteConfig is now publicly accessible (unauthenticated).
  late DataClient<RemoteConfig> remoteConfigClient;
  logger.fine('Using API client for RemoteConfig.');
  // For development and production environments, use DataApi.
  remoteConfigClient = DataApi<RemoteConfig>(
    httpClient: httpClient,
    modelName: 'remote_config',
    fromJson: RemoteConfig.fromJson,
    toJson: (config) => config.toJson(),
    logger: logger,
  );
  final remoteConfigRepository = DataRepository<RemoteConfig>(
    dataClient: remoteConfigClient,
  );
  // Fetch RemoteConfig once, early in the process.
  // This configuration is required by Analytics, Push Notifications etc
  // to determine which providers to initialize.
  RemoteConfig? remoteConfig;
  try {
    remoteConfig = await remoteConfigRepository.read(id: kRemoteConfigId);
    logger.fine('RemoteConfig fetched successfully.');
  } catch (e, s) {
    logger.warning(
      'Failed to fetch RemoteConfig in bootstrap. '
      'Services will be initialized in default (disabled) mode. '
      'The AppInitializer will attempt to fetch it again and handle the UI error.',
      e,
      s,
    );
  }

  logger.info('4. Initializing Authentication services...');
  // 4. Conditionally initialize Auth services based on environment.
  // This is done after RemoteConfig is fetched, as Auth services might depend
  // on configurations defined in RemoteConfig.
  late final AuthClient authClient;
  late final AuthRepository authenticationRepository;
  logger.fine('Using API client for Authentication.');
  // Now that httpClient is available, initialize AuthApi and AuthRepository.
  authClient = AuthApi(httpClient: httpClient);
  authenticationRepository = AuthRepository(
    authClient: authClient,
    storageService: kvStorage,
  );
  logger
    ..fine('Authentication repository initialized.')
    ..info('5. Initializing Analytics service...');

  // 5. Initialize Analytics Service.
  late final AnalyticsService analyticsService;
  final analyticsProviders = <AnalyticsProviders, AnalyticsProvider>{};

  // Initialize providers based on environment and config
  // Add Firebase
  analyticsProviders[AnalyticsProviders.firebase] =
      analytics_firebase.FirebaseAnalyticsProvider(
        firebaseAnalytics: FirebaseAnalytics.instance,
        logger: logger,
      );
  // Add Mixpanel
  analyticsProviders[AnalyticsProviders.mixpanel] = MixpanelAnalyticsProvider(
    projectToken: appConfig.mixpanelProjectToken,
    trackAutomaticEvents: true,
    logger: logger,
  );

  // Always instantiate the Manager. It handles enabled/disabled state internally.
  analyticsService = AnalyticsManager(
    initialConfig: remoteConfig?.features.analytics,
    providers: analyticsProviders,
    noOpProvider: NoOpAnalyticsProvider(logger: logger),
    logger: logger,
  );

  await analyticsService.initialize();
  logger
    ..fine('Analytics service initialized.')
    ..info('6. Initializing Ad providers and AdService...');

  // 6. Initialize AdProvider and AdService.
  late final AdService adService;
  final adProviders = <AdPlatformType, AdProvider>{};
  logger.fine('Using AdMobAdProvider.');
  adProviders[AdPlatformType.admob] = AdMobAdProvider(
    analyticsService: analyticsService,
    logger: logger,
  );
  // Always instantiate the Manager. It handles enabled/disabled state internally.
  adService = AdManager(
    initialConfig: remoteConfig?.features.ads,
    adProviders: adProviders,
    noOpProvider: NoOpAdProvider(logger: logger),
    analyticsService: analyticsService,
    logger: logger,
  );
  await adService.initialize();
  logger.fine('AdService initialized.');

  // Initialize InlineAdCacheService with the created AdService.
  inlineAdCacheService = InlineAdCacheService(adService: adService);
  logger.fine('InlineAdCacheService initialized.');

  // Initialize FeedCacheService as a singleton for session-based caching.
  final feedCacheService = FeedCacheService(logger: logger);
  logger.fine('FeedCacheService initialized.');

  // Initialize FeedDecoratorService.
  final feedDecoratorService = FeedDecoratorService(logger: logger);
  logger.fine('FeedDecoratorService initialized.');

  // Create a GlobalKey for the NavigatorState to be used by AppBloc
  // and InterstitialAdManager for BuildContext access.
  final navigatorKey = GlobalKey<NavigatorState>();

  // Initialize PackageInfoService
  final packageInfoService = PackageInfoServiceImpl(logger: logger);
  logger
    ..fine('PackageInfoService initialized.')
    ..info('7. Initializing Data clients and repositories...');

  // 7. Initialize all other DataClients and Repositories.
  // These now also have a guaranteed valid httpClient.
  late final DataClient<Headline> headlinesClient;
  late final DataClient<Topic> topicsClient;
  late final DataClient<Country> countriesClient;
  late final DataClient<Source> sourcesClient;
  late final DataClient<UserContentPreferences> userContentPreferencesClient;
  late final DataClient<AppSettings> appSettingsClient;
  late final DataClient<User> userClient;
  late final DataClient<UserContext> userContextClient;
  late final DataClient<InAppNotification> inAppNotificationClient;
  late final DataClient<PushNotificationDevice> pushNotificationDeviceClient;
  late final DataClient<Engagement> engagementClient;
  late final DataClient<Report> reportClient;
  late final DataClient<AppReview> appReviewClient;
  late final DataClient<UserRewards> userRewardsClient;
  late final MediaClient mediaClient;
  logger.fine('Using API clients for all data repositories.');
  headlinesClient = DataApi<Headline>(
    httpClient: httpClient,
    modelName: 'headline',
    fromJson: Headline.fromJson,
    toJson: (headline) => headline.toJson(),
    logger: logger,
  );
  topicsClient = DataApi<Topic>(
    httpClient: httpClient,
    modelName: 'topic',
    fromJson: Topic.fromJson,
    toJson: (topic) => topic.toJson(),
    logger: logger,
  );
  countriesClient = DataApi<Country>(
    httpClient: httpClient,
    modelName: 'country',
    fromJson: Country.fromJson,
    toJson: (country) => country.toJson(),
    logger: logger,
  );
  sourcesClient = DataApi<Source>(
    httpClient: httpClient,
    modelName: 'source',
    fromJson: Source.fromJson,
    toJson: (source) => source.toJson(),
    logger: logger,
  );
  userContentPreferencesClient = DataApi<UserContentPreferences>(
    httpClient: httpClient,
    modelName: 'user_content_preferences',
    fromJson: UserContentPreferences.fromJson,
    toJson: (prefs) => prefs.toJson(),
    logger: logger,
  );
  appSettingsClient = DataApi<AppSettings>(
    httpClient: httpClient,
    modelName: 'app_settings',
    fromJson: AppSettings.fromJson,
    toJson: (settings) => settings.toJson(),
    logger: logger,
  );
  userClient = DataApi<User>(
    httpClient: httpClient,
    modelName: 'user',
    fromJson: User.fromJson,
    toJson: (user) => user.toJson(),
    logger: logger,
  );
  userContextClient = DataApi<UserContext>(
    httpClient: httpClient,
    modelName: 'user_context',
    fromJson: UserContext.fromJson,
    toJson: (context) => context.toJson(),
    logger: logger,
  );
  inAppNotificationClient = DataApi<InAppNotification>(
    httpClient: httpClient,
    modelName: 'in_app_notification',
    fromJson: InAppNotification.fromJson,
    toJson: (notification) => notification.toJson(),
    logger: logger,
  );
  pushNotificationDeviceClient = DataApi<PushNotificationDevice>(
    httpClient: httpClient,
    modelName: 'push_notification_device',
    fromJson: PushNotificationDevice.fromJson,
    toJson: (device) => device.toJson(),
    logger: logger,
  );
  engagementClient = DataApi<Engagement>(
    httpClient: httpClient,
    modelName: 'engagement',
    fromJson: Engagement.fromJson,
    toJson: (engagement) => engagement.toJson(),
    logger: logger,
  );
  reportClient = DataApi<Report>(
    httpClient: httpClient,
    modelName: 'report',
    fromJson: Report.fromJson,
    toJson: (report) => report.toJson(),
    logger: logger,
  );
  appReviewClient = DataApi<AppReview>(
    httpClient: httpClient,
    modelName: 'app_review',
    fromJson: AppReview.fromJson,
    toJson: (review) => review.toJson(),
    logger: logger,
  );
  userRewardsClient = DataApi<UserRewards>(
    httpClient: httpClient,
    modelName: 'user_rewards',
    fromJson: UserRewards.fromJson,
    toJson: (rewards) => rewards.toJson(),
    logger: logger,
  );
  mediaClient = MediaApi(httpClient: httpClient, logger: logger);
  logger.fine('All data clients instantiated.');

  final headlinesRepository = DataRepository<Headline>(
    dataClient: headlinesClient,
  );
  final topicsRepository = DataRepository<Topic>(dataClient: topicsClient);
  final countriesRepository = DataRepository<Country>(
    dataClient: countriesClient,
  );
  final sourcesRepository = DataRepository<Source>(dataClient: sourcesClient);
  final userContentPreferencesRepository =
      DataRepository<UserContentPreferences>(
        dataClient: userContentPreferencesClient,
      );
  final appSettingsRepository = DataRepository<AppSettings>(
    dataClient: appSettingsClient,
  );
  final userRepository = DataRepository<User>(dataClient: userClient);
  final userContextRepository = DataRepository<UserContext>(
    dataClient: userContextClient,
  );
  final inAppNotificationRepository = DataRepository<InAppNotification>(
    dataClient: inAppNotificationClient,
  );
  final pushNotificationDeviceRepository =
      DataRepository<PushNotificationDevice>(
        dataClient: pushNotificationDeviceClient,
      );
  final engagementRepository = DataRepository<Engagement>(
    dataClient: engagementClient,
  );
  final reportRepository = DataRepository<Report>(dataClient: reportClient);
  final appReviewRepository = DataRepository<AppReview>(
    dataClient: appReviewClient,
  );

  final userRewardsRepository = DataRepository<UserRewards>(
    dataClient: userRewardsClient,
  );

  final mediaRepository = MediaRepository(mediaClient: mediaClient);

  logger
    ..fine('All data repositories initialized.')
    ..info('8. Initializing Push Notification service...');

  // 8. Initialize the PushNotificationService based on the remote config.
  // This is a crucial step for the provider-agnostic architecture.
  late final PushNotificationService pushNotificationService;
  final pushNotificationProviders =
      <PushNotificationProviders, PushNotificationProvider>{};

  pushNotificationProviders[PushNotificationProviders.firebase] =
      FirebasePushNotificationService(logger: logger);
  pushNotificationProviders[PushNotificationProviders.oneSignal] =
      OneSignalPushNotificationService(
        appId: appConfig.oneSignalAppId,
        logger: logger,
      );

  pushNotificationService = PushNotificationManager(
    initialConfig: remoteConfig?.features.pushNotifications,
    providers: pushNotificationProviders,
    noOpProvider: NoOpPushNotificationProvider(logger: logger),
    pushNotificationDeviceRepository: pushNotificationDeviceRepository,
    storageService: kvStorage,
    logger: logger,
  );

  // Initialize the selected provider.
  await pushNotificationService.initialize();
  logger.fine('PushNotificationService initialized.');

  // Initialize AppReviewService
  late final NativeReviewService nativeReviewService;
  final communityConfig = remoteConfig?.features.community;

  if (communityConfig != null &&
      communityConfig.enabled &&
      communityConfig.appReview.enabled) {
    nativeReviewService = InAppReviewService(
      inAppReview: InAppReview.instance,
      logger: logger,
    );
  } else {
    nativeReviewService = NoOpNativeReviewService(logger: logger);
  }

  final appReviewService = AppReviewService(
    appReviewRepository: appReviewRepository,
    nativeReviewService: nativeReviewService,
    analyticsService: analyticsService,
    logger: logger,
  );

  // Initialize ContentLimitationService.
  final contentLimitationService = ContentLimitationService(
    engagementRepository: engagementRepository,
    reportRepository: reportRepository,
    analyticsService: analyticsService,
    cacheDuration: const Duration(minutes: 5),
    logger: logger,
  );
  logger
    ..fine('ContentLimitationService initialized.')
    ..fine('AppReviewService initialized.')
    ..info('9. Initializing AppInitializer service...');
  final appInitializer = AppInitializer(
    authenticationRepository: authenticationRepository,
    appSettingsRepository: appSettingsRepository,
    userContentPreferencesRepository: userContentPreferencesRepository,
    userContextRepository: userContextRepository,
    userRewardsRepository: userRewardsRepository,
    remoteConfigRepository: remoteConfigRepository,
    storageService: kvStorage,
    packageInfoService: packageInfoService,
    logger: logger,
  );
  logger
    ..fine('AppInitializer service initialized.')
    // The initialization is now deferred to the AppInitializationPage, which
    // will use the AppInitializationBloc to run the AppInitializer.
    ..info('10. Deferring app initialization to AppInitializationPage.')
    ..info(
      '--- Bootstrap Process Complete. '
      'Returning AppInitializationPage widget. ---',
    );
  // Provide the AppInitializer and Logger at the root so they can be accessed
  // by the AppInitializationBloc within AppInitializationPage.
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: analyticsService),
      RepositoryProvider.value(value: appInitializer),
      RepositoryProvider.value(value: kvStorage),
      RepositoryProvider.value(value: logger),
    ],
    child: AppInitializationPage(
      // All other repositories and services are passed directly to the
      // initialization page, which will then pass them to the main App widget
      // upon successful initialization.
      kvStorage: kvStorage,
      authenticationRepository: authenticationRepository,
      headlinesRepository: headlinesRepository,
      topicsRepository: topicsRepository,
      userRepository: userRepository,
      countriesRepository: countriesRepository,
      sourcesRepository: sourcesRepository,
      remoteConfigRepository: remoteConfigRepository,
      appSettingsRepository: appSettingsRepository,
      userContentPreferencesRepository: userContentPreferencesRepository,
      userContextRepository: userContextRepository,
      pushNotificationService: pushNotificationService,
      inAppNotificationRepository: inAppNotificationRepository,
      environment: environment,
      adService: adService,
      feedDecoratorService: feedDecoratorService,
      inlineAdCacheService: inlineAdCacheService,
      feedCacheService: feedCacheService,
      navigatorKey: navigatorKey,
      engagementRepository: engagementRepository,
      reportRepository: reportRepository,
      appReviewRepository: appReviewRepository,
      appReviewService: appReviewService,
      contentLimitationService: contentLimitationService,
      analyticsService: analyticsService,
      userRewardsRepository: userRewardsRepository,
      mediaRepository: mediaRepository,
    ),
  );
}
