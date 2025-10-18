import 'package:auth_api/auth_api.dart';
import 'package:auth_client/auth_client.dart';
import 'package:auth_inmemory/auth_inmemory.dart';
import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart';
import 'package:data_api/data_api.dart';
import 'package:data_client/data_client.dart';
import 'package:data_inmemory/data_inmemory.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
// Conditional import for AdMobAdProvider
// This ensures the AdMob package is only imported when not on the web,
// preventing potential issues or unnecessary logs on web platforms.
import 'package:flutter_news_app_mobile_client_full_source_code/ads/admob_ad_provider.dart'
    if (dart.library.io) 'package:flutter_news_app_mobile_client_full_source_code/ads/admob_ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/demo_ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/local_ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/view/app_initialization_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/config.dart'
    as app_config;
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_initializer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_initializer_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_migration_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/package_info_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/bloc_observer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/data/clients/country_inmemory_client.dart';
import 'package:http_client/http_client.dart';
import 'package:kv_storage_service/kv_storage_service.dart';
import 'package:kv_storage_shared_preferences/kv_storage_shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ui_kit/ui_kit.dart';

Future<Widget> bootstrap(
  app_config.AppConfig appConfig,
  app_config.AppEnvironment environment,
) async {
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

  WidgetsFlutterBinding.ensureInitialized();
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
    // 3. Initialize RemoteConfigClient and Repository, and fetch RemoteConfig.
    ..info('3. Initializing RemoteConfig client and repository...');
  // This is done early because RemoteConfig is now publicly accessible (unauthenticated).
  late DataClient<RemoteConfig> remoteConfigClient;
  if (appConfig.environment == app_config.AppEnvironment.demo) {
    logger.fine('Using in-memory client for RemoteConfig.');
    remoteConfigClient = DataInMemory<RemoteConfig>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: remoteConfigsFixturesData,
      logger: logger,
    );
  } else {
    logger.fine('Using API client for RemoteConfig.');
    // For development and production environments, use DataApi.
    remoteConfigClient = DataApi<RemoteConfig>(
      httpClient: httpClient,
      modelName: 'remote_config',
      fromJson: RemoteConfig.fromJson,
      toJson: (config) => config.toJson(),
      logger: logger,
    );
  }
  final remoteConfigRepository = DataRepository<RemoteConfig>(
    dataClient: remoteConfigClient,
  );
  logger
    ..fine('RemoteConfig repository initialized.')
    // 4. Conditionally initialize Auth services based on environment.
    // This is done after RemoteConfig is fetched, as Auth services might depend
    // on configurations defined in RemoteConfig.
    ..info('5. Initializing Authentication services...');
  late final AuthClient authClient;
  late final AuthRepository authenticationRepository;
  if (appConfig.environment == app_config.AppEnvironment.demo) {
    logger.fine('Using in-memory client for Authentication.');
    // In-memory authentication for demo environment.
    authClient = AuthInmemory();
    authenticationRepository = AuthRepository(
      authClient: authClient,
      storageService: kvStorage,
    );
  } else {
    logger.fine('Using API client for Authentication.');
    // Now that httpClient is available, initialize AuthApi and AuthRepository.
    authClient = AuthApi(httpClient: httpClient);
    authenticationRepository = AuthRepository(
      authClient: authClient,
      storageService: kvStorage,
    );
  }
  logger
    ..fine('Authentication repository initialized.')
    // 5. Initialize AdProvider and AdService.
    ..info('6. Initializing Ad providers and AdService...');
  late final Map<AdPlatformType, AdProvider> adProviders;

  // Conditionally instantiate ad providers based on the application environment.
  // This ensures that only the relevant ad providers are available for the
  // current environment, preventing unintended usage.
  if (appConfig.environment == app_config.AppEnvironment.demo || kIsWeb) {
    logger.fine('Using DemoAdProvider for all ad platforms.');
    final demoAdProvider = DemoAdProvider(logger: logger);
    adProviders = {
      // In the demo environment or on the web, all ad platform types map to
      // the DemoAdProvider. This simulates ad behavior without actual network
      // calls and avoids issues with platform-specific ad SDKs on unsupported
      // platforms (e.g., AdMob on web).
      AdPlatformType.admob: demoAdProvider,
      AdPlatformType.local: demoAdProvider,
      AdPlatformType.demo: demoAdProvider,
    };
  } else {
    logger.fine('Using AdMobAdProvider and LocalAdProvider.');
    // For development and production environments (non-web), use real ad providers.
    adProviders = {
      // AdMob provider for Google Mobile Ads.
      AdPlatformType.admob: AdMobAdProvider(logger: logger),
      // Local ad provider for custom/backend-served ads.
      AdPlatformType.local: LocalAdProvider(
        localAdRepository: DataRepository<LocalAd>(
          dataClient: DataApi<LocalAd>(
            httpClient: httpClient,
            modelName: 'local_ad',
            fromJson: LocalAd.fromJson,
            toJson: LocalAd.toJson,
            logger: logger,
          ),
        ),
        logger: logger,
      ),
      // The demo ad platform is not available in non-demo/non-web environments.
      // If AdService attempts to access it, it will receive null, which is
      // handled by AdService's internal logic (logging a warning).
    };
  }

  final adService = AdService(
    adProviders: adProviders,
    environment: appConfig.environment,
    logger: logger,
  );
  await adService.initialize();
  logger.fine('AdService initialized.');

  // Initialize InlineAdCacheService with the created AdService.
  inlineAdCacheService = InlineAdCacheService(adService: adService);
  logger.fine('InlineAdCacheService initialized.');

  // Create a GlobalKey for the NavigatorState to be used by AppBloc
  // and InterstitialAdManager for BuildContext access.
  final navigatorKey = GlobalKey<NavigatorState>();

  // Initialize PackageInfoService
  final packageInfoService = PackageInfoServiceImpl(logger: logger);
  logger
    ..fine('PackageInfoService initialized.')
    // 6. Initialize all other DataClients and Repositories.
    ..info('8. Initializing Data clients and repositories...');
  // These now also have a guaranteed valid httpClient.
  late final DataClient<Headline> headlinesClient;
  late final DataClient<Topic> topicsClient;
  late final DataClient<Country> countriesClient;
  late final DataClient<Source> sourcesClient;
  late final DataClient<UserContentPreferences> userContentPreferencesClient;
  late final DataClient<UserAppSettings> userAppSettingsClient;
  late final DataClient<User> userClient;
  late final DataClient<LocalAd> localAdClient;
  if (appConfig.environment == app_config.AppEnvironment.demo) {
    logger.fine('Using in-memory clients for all data repositories.');
    headlinesClient = DataInMemory<Headline>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: headlinesFixturesData,
      logger: logger,
    );
    topicsClient = DataInMemory<Topic>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: topicsFixturesData,
      logger: logger,
    );
    // Wrap the generic DataInMemory<Country> with CountryInMemoryClient.
    // This decorator adds specialized filtering for 'hasActiveSources' and
    // 'hasActiveHeadlines' which are specific to the application's needs
    // in the demo environment.
    //
    // Rationale:
    // 1.  **Demo Environment Specific:** This client-side decorator is only
    //     applied in the `demo` environment. In this mode, data is served
    //     from static in-memory fixtures, and this decorator enables complex
    //     filtering on that local data.
    // 2.  **API Environments (Development/Production):** For `development`
    //     and `production` environments, the `countriesClient` is an instance
    //     of `DataApi<Country>`. In these environments, the backend API
    //     (which includes services like `CountryQueryService`) is responsible
    //     for handling all advanced filtering and aggregation logic. Therefore,
    //     this client-side decorator is not needed.
    // 3.  **Preserving Genericity:** The core `DataInMemory<T>` client (from
    //     the `data-inmemory` package) is designed to be generic and reusable
    //     across various projects. Modifying it directly with application-specific
    //     logic would violate the Single Responsibility Principle and reduce
    //     its reusability. The Decorator Pattern allows us to extend its
    //     functionality for `Country` models without altering the generic base.
    countriesClient = CountryInMemoryClient(
      decoratedClient: DataInMemory<Country>(
        toJson: (i) => i.toJson(),
        getId: (i) => i.id,
        initialData: countriesFixturesData,
        logger: logger,
      ),
      allSources: sourcesFixturesData,
      allHeadlines: headlinesFixturesData,
    );

    //
    sourcesClient = DataInMemory<Source>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: sourcesFixturesData,
      logger: logger,
    );
    userContentPreferencesClient = DataInMemory<UserContentPreferences>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      logger: logger,
    );
    userAppSettingsClient = DataInMemory<UserAppSettings>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      logger: logger,
    );
    userClient = DataInMemory<User>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      logger: logger,
    );
    localAdClient = DataInMemory<LocalAd>(
      toJson: LocalAd.toJson,
      getId: (i) => i.id,
      initialData: localAdsFixturesData,
      logger: logger,
    );
  } else if (appConfig.environment == app_config.AppEnvironment.development) {
    logger.fine('Using API clients for all data repositories (Development).');
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
    userAppSettingsClient = DataApi<UserAppSettings>(
      httpClient: httpClient,
      modelName: 'user_app_settings',
      fromJson: UserAppSettings.fromJson,
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
    localAdClient = DataApi<LocalAd>(
      httpClient: httpClient,
      modelName: 'local_ad',
      fromJson: LocalAd.fromJson,
      toJson: LocalAd.toJson,
      logger: logger,
    );
  } else {
    logger.fine('Using API clients for all data repositories (Production).');
    // Default to API clients for production
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
    userAppSettingsClient = DataApi<UserAppSettings>(
      httpClient: httpClient,
      modelName: 'user_app_settings',
      fromJson: UserAppSettings.fromJson,
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
    localAdClient = DataApi<LocalAd>(
      httpClient: httpClient,
      modelName: 'local_ad',
      fromJson: LocalAd.fromJson,
      toJson: LocalAd.toJson,
      logger: logger,
    );
  }
  logger.fine('All data clients instantiated.');

  final headlinesRepository = DataRepository<Headline>(
    dataClient: headlinesClient,
  );
  final localAdRepository = DataRepository<LocalAd>(dataClient: localAdClient);
  final topicsRepository = DataRepository<Topic>(dataClient: topicsClient);
  final countriesRepository = DataRepository<Country>(
    dataClient: countriesClient,
  );
  final sourcesRepository = DataRepository<Source>(dataClient: sourcesClient);
  final userContentPreferencesRepository =
      DataRepository<UserContentPreferences>(
        dataClient: userContentPreferencesClient,
      );
  final userAppSettingsRepository = DataRepository<UserAppSettings>(
    dataClient: userAppSettingsClient,
  );
  final userRepository = DataRepository<User>(dataClient: userClient);
  logger.fine('All data repositories initialized.');

  // Conditionally instantiate DemoDataMigrationService
  final demoDataMigrationService =
      appConfig.environment == app_config.AppEnvironment.demo
      ? DemoDataMigrationService(
          userAppSettingsRepository: userAppSettingsRepository,
          userContentPreferencesRepository: userContentPreferencesRepository,
        )
      : null;
  logger.fine(
    'DemoDataMigrationService initialized: ${demoDataMigrationService != null}',
  );

  // Conditionally instantiate DemoDataInitializerService
  // In the demo environment, this service acts as a "fixture injector".
  // When a new user is encountered, it clones pre-defined fixture data
  // (settings and preferences, including saved filters) for that user,
  // ensuring a rich initial experience.
  final demoDataInitializerService =
      appConfig.environment == app_config.AppEnvironment.demo
      ? DemoDataInitializerService(
          userAppSettingsRepository: userAppSettingsRepository,
          userContentPreferencesRepository: userContentPreferencesRepository,
          userAppSettingsFixturesData: userAppSettingsFixturesData,
          userContentPreferencesFixturesData:
              userContentPreferencesFixturesData,
        )
      : null;
  logger
    ..fine(
      'DemoDataInitializerService initialized: ${demoDataInitializerService != null}',
    )
    ..info('9. Initializing AppInitializer service...');
  final appInitializer = AppInitializer(
    authenticationRepository: authenticationRepository,
    userAppSettingsRepository: userAppSettingsRepository,
    userContentPreferencesRepository: userContentPreferencesRepository,
    remoteConfigRepository: remoteConfigRepository,
    environment: environment,
    packageInfoService: packageInfoService,
    logger: logger,
    demoDataMigrationService: demoDataMigrationService,
    demoDataInitializerService: demoDataInitializerService,
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
  // Provide the AppInitializer at the root so it can be accessed by the
  // AppInitializationBloc within AppInitializationPage.
  return RepositoryProvider.value(
    value: appInitializer,
    child: AppInitializationPage(
      // All repositories and services are passed to the initialization page,
      // which will then pass them to the main App widget upon successful
      // initialization.
      authenticationRepository: authenticationRepository,
      headlinesRepository: headlinesRepository,
      topicsRepository: topicsRepository,
      userRepository: userRepository,
      countriesRepository: countriesRepository,
      sourcesRepository: sourcesRepository,
      remoteConfigRepository: remoteConfigRepository,
      userAppSettingsRepository: userAppSettingsRepository,
      userContentPreferencesRepository: userContentPreferencesRepository,
      environment: environment,
      adService: adService,
      inlineAdCacheService: inlineAdCacheService,
      localAdRepository: localAdRepository,
      navigatorKey: navigatorKey,
    ),
  );
}
