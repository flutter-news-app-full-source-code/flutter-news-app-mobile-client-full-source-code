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
import 'package:flutter_news_app_mobile_client_full_source_code/app/app.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/config.dart'
    as app_config;
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
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(
    (record) => print(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    ),
  );
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();
  final logger = Logger('bootstrap');
  timeago.setLocaleMessages('en', EnTimeagoMessages());
  timeago.setLocaleMessages('ar', ArTimeagoMessages());

  // 1. Initialize KV Storage Service first, as it's a foundational dependency.
  final kvStorage = await KVStorageSharedPreferences.getInstance();

  // Initialize InlineAdCacheService early as it's a singleton and needs AdService.
  // It will be fully configured once AdService is available.
  InlineAdCacheService? inlineAdCacheService;

  // 2. Initialize HttpClient. Its tokenProvider now directly reads from
  // kvStorage, breaking the circular dependency with AuthRepository.
  // This HttpClient instance is used for all subsequent API calls, including
  // the initial unauthenticated fetch of RemoteConfig.
  final httpClient = HttpClient(
    baseUrl: appConfig.baseUrl,
    tokenProvider: () =>
        kvStorage.readString(key: StorageKey.authToken.stringValue),
    logger: logger,
  );

  // 3. Initialize RemoteConfigClient and Repository, and fetch RemoteConfig.
  // This is done early because RemoteConfig is now publicly accessible (unauthenticated).
  late DataClient<RemoteConfig> remoteConfigClient;
  if (appConfig.environment == app_config.AppEnvironment.demo) {
    remoteConfigClient = DataInMemory<RemoteConfig>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: remoteConfigsFixturesData,
      logger: logger,
    );
  } else {
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

  // Fetch the initial RemoteConfig. This is a critical step to determine
  // the app's global status (e.g., maintenance mode, update required)
  // before proceeding with other initializations.
  RemoteConfig? initialRemoteConfig;
  HttpException? initialRemoteConfigError;

  try {
    initialRemoteConfig = await remoteConfigRepository.read(
      id: kRemoteConfigId,
    );
    logger.info('[bootstrap] Initial RemoteConfig fetched successfully.');
  } on HttpException catch (e) {
    logger.severe(
      '[bootstrap] Failed to fetch initial RemoteConfig (HttpException): $e',
    );
    initialRemoteConfigError = e;
  } catch (e, s) {
    logger.severe(
      '[bootstrap] Unexpected error fetching initial RemoteConfig.',
      e,
      s,
    );
    initialRemoteConfigError = UnknownException(e.toString());
  }

  // 4. Conditionally initialize Auth services based on environment.
  // This is done after RemoteConfig is fetched, as Auth services might depend
  // on configurations defined in RemoteConfig (though not directly in this case).
  late final AuthClient authClient;
  late final AuthRepository authenticationRepository;
  if (appConfig.environment == app_config.AppEnvironment.demo) {
    // In-memory authentication for demo environment.
    authClient = AuthInmemory();
    authenticationRepository = AuthRepository(
      authClient: authClient,
      storageService: kvStorage,
    );
  } else {
    // Now that httpClient is available, initialize AuthApi and AuthRepository.
    authClient = AuthApi(httpClient: httpClient);
    authenticationRepository = AuthRepository(
      authClient: authClient,
      storageService: kvStorage,
    );
  }

  // 5. Initialize AdProvider and AdService.
  late final Map<AdPlatformType, AdProvider> adProviders;

  // Conditionally instantiate ad providers based on the application environment.
  // This ensures that only the relevant ad providers are available for the
  // current environment, preventing unintended usage.
  if (appConfig.environment == app_config.AppEnvironment.demo || kIsWeb) {
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

  // Initialize InlineAdCacheService with the created AdService.
  inlineAdCacheService = InlineAdCacheService(adService: adService);

  // Fetch the initial user from the authentication repository.
  // This ensures the AppBloc starts with an accurate authentication status.
  final initialUser = await authenticationRepository.getCurrentUser();

  // Create a GlobalKey for the NavigatorState to be used by AppBloc
  // and InterstitialAdManager for BuildContext access.
  final navigatorKey = GlobalKey<NavigatorState>();

  // Initialize PackageInfoService
  final packageInfoService = PackageInfoServiceImpl(logger: logger);

  // 6. Initialize all other DataClients and Repositories.
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

  // Conditionally instantiate DemoDataMigrationService
  final demoDataMigrationService =
      appConfig.environment == app_config.AppEnvironment.demo
      ? DemoDataMigrationService(
          userAppSettingsRepository: userAppSettingsRepository,
          userContentPreferencesRepository: userContentPreferencesRepository,
        )
      : null;

  // Conditionally instantiate DemoDataInitializerService
  // This service is responsible for ensuring that essential user-specific data
  // (like UserAppSettings, UserContentPreferences)
  // exists in the data in-memory clients when a user is first encountered
  // in the demo environment.
  final demoDataInitializerService =
      appConfig.environment == app_config.AppEnvironment.demo
      ? DemoDataInitializerService(
          userAppSettingsRepository: userAppSettingsRepository,
          userContentPreferencesRepository: userContentPreferencesRepository,
        )
      : null;

  return App(
    authenticationRepository: authenticationRepository,
    headlinesRepository: headlinesRepository,
    topicsRepository: topicsRepository,
    countriesRepository: countriesRepository,
    sourcesRepository: sourcesRepository,
    userAppSettingsRepository: userAppSettingsRepository,
    userContentPreferencesRepository: userContentPreferencesRepository,
    remoteConfigRepository: remoteConfigRepository,
    userRepository: userRepository,
    kvStorageService: kvStorage,
    environment: environment,
    demoDataMigrationService: demoDataMigrationService,
    demoDataInitializerService: demoDataInitializerService,
    adService: adService,
    inlineAdCacheService: inlineAdCacheService,
    initialUser: initialUser,
    localAdRepository: localAdRepository,
    navigatorKey: navigatorKey,
    initialRemoteConfig: initialRemoteConfig,
    initialRemoteConfigError: initialRemoteConfigError,
    packageInfoService: packageInfoService,
  );
}
