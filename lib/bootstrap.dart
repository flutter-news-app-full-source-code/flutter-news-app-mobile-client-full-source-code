import 'package:auth_api/auth_api.dart';
import 'package:auth_client/auth_client.dart';
import 'package:auth_inmemory/auth_inmemory.dart';
import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart';
import 'package:data_api/data_api.dart';
import 'package:data_client/data_client.dart';
import 'package:data_inmemory/data_inmemory.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/admob_ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/no_op_ad_provider.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/app.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/config.dart'
    as app_config;
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_initializer_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_migration_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/bloc_observer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/data/clients/country_inmemory_client.dart';
import 'package:http_client/http_client.dart';
import 'package:kv_storage_shared_preferences/kv_storage_shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ui_kit/ui_kit.dart';

Future<Widget> bootstrap(
  app_config.AppConfig appConfig,
  app_config.AppEnvironment environment,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();

  timeago.setLocaleMessages('en', EnTimeagoMessages());
  timeago.setLocaleMessages('ar', ArTimeagoMessages());

  final logger = Logger('bootstrap');

  final kvStorage = await KVStorageSharedPreferences.getInstance();

  late final AuthClient authClient;
  late final AuthRepository authenticationRepository;
  HttpClient? httpClient;

  // Initialize AdProvider and AdService
  // Initialize AdProvider based on platform.
  // On web, use a No-Op provider to prevent MissingPluginException,
  // as Google Mobile Ads SDK does not support native ads on web.
  final adProvider = kIsWeb
      ? NoOpAdProvider(logger: logger)
      : AdMobAdProvider(logger: logger);

  final adService = AdService(adProvider: adProvider, logger: logger);
  await adService.initialize(); // Initialize the selected AdProvider early

  if (appConfig.environment == app_config.AppEnvironment.demo) {
    authClient = AuthInmemory();
    authenticationRepository = AuthRepository(
      authClient: authClient,
      storageService: kvStorage,
    );
  } else {
    // For production and development environments, an HTTP client is needed.
    httpClient = HttpClient(
      baseUrl: appConfig.baseUrl,
      tokenProvider: () => authenticationRepository.getAuthToken(),
      logger: logger,
    );
    authClient = AuthApi(httpClient: httpClient);
    authenticationRepository = AuthRepository(
      authClient: authClient,
      storageService: kvStorage,
    );
  }

  // Fetch the initial user from the authentication repository.
  // This ensures the AppBloc starts with an accurate authentication status.
  final initialUser = await authenticationRepository.getCurrentUser();

  // Conditional data client instantiation based on environment
  DataClient<Headline> headlinesClient;
  DataClient<Topic> topicsClient;
  DataClient<Country> countriesClient;
  DataClient<Source> sourcesClient;
  DataClient<UserContentPreferences> userContentPreferencesClient;
  DataClient<UserAppSettings> userAppSettingsClient;
  DataClient<RemoteConfig> remoteConfigClient;
  DataClient<User> userClient;

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
    countriesClient = DataInMemory<Country>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: countriesFixturesData,
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
      decoratedClient: countriesClient,
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
    remoteConfigClient = DataInMemory<RemoteConfig>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: remoteConfigsFixturesData,
      logger: logger,
    );
    userClient = DataInMemory<User>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      logger: logger,
    );
  } else if (appConfig.environment == app_config.AppEnvironment.development) {
    headlinesClient = DataApi<Headline>(
      httpClient: httpClient!,
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
    remoteConfigClient = DataApi<RemoteConfig>(
      httpClient: httpClient,
      modelName: 'remote_config',
      fromJson: RemoteConfig.fromJson,
      toJson: (config) => config.toJson(),
      logger: logger,
    );
    userClient = DataApi<User>(
      httpClient: httpClient,
      modelName: 'user',
      fromJson: User.fromJson,
      toJson: (user) => user.toJson(),
      logger: logger,
    );
  } else {
    // Default to API clients for production
    headlinesClient = DataApi<Headline>(
      httpClient: httpClient!,
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
    remoteConfigClient = DataApi<RemoteConfig>(
      httpClient: httpClient,
      modelName: 'remote_config',
      fromJson: RemoteConfig.fromJson,
      toJson: (config) => config.toJson(),
      logger: logger,
    );
    userClient = DataApi<User>(
      httpClient: httpClient,
      modelName: 'user',
      fromJson: User.fromJson,
      toJson: (user) => user.toJson(),
      logger: logger,
    );
  }

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
  final userAppSettingsRepository = DataRepository<UserAppSettings>(
    dataClient: userAppSettingsClient,
  );
  final remoteConfigRepository = DataRepository<RemoteConfig>(
    dataClient: remoteConfigClient,
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
  final demoDataInitializerService =
      appConfig.environment == app_config.AppEnvironment.demo
          ? DemoDataInitializerService(
              userAppSettingsRepository: userAppSettingsRepository,
              userContentPreferencesRepository: userContentPreferencesRepository,
              userRepository: userRepository,
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
    initialUser: initialUser,
  );
}
