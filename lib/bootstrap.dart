import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_auth_api/ht_auth_api.dart';
import 'package:ht_auth_client/ht_auth_client.dart';
import 'package:ht_auth_inmemory/ht_auth_inmemory.dart';
import 'package:ht_auth_repository/ht_auth_repository.dart';
import 'package:ht_data_api/ht_data_api.dart';
import 'package:ht_data_client/ht_data_client.dart';
import 'package:ht_data_inmemory/ht_data_inmemory.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_http_client/ht_http_client.dart';
import 'package:ht_kv_storage_shared_preferences/ht_kv_storage_shared_preferences.dart';
import 'package:ht_main/app/app.dart';
import 'package:ht_main/app/config/config.dart' as app_config;
import 'package:ht_main/app/services/demo_data_migration_service.dart';
import 'package:ht_main/bloc_observer.dart';
import 'package:ht_shared/ht_shared.dart';
import 'package:logging/logging.dart';

Future<Widget> bootstrap(
  app_config.AppConfig appConfig,
  app_config.AppEnvironment environment,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();

  final _logger = Logger('bootstrap');

  final kvStorage = await HtKvStorageSharedPreferences.getInstance();

  late final HtAuthClient authClient;
  late final HtAuthRepository authenticationRepository;
  HtHttpClient? httpClient;

  if (appConfig.environment == app_config.AppEnvironment.demo) {
    authClient = HtAuthInmemory();
    authenticationRepository = HtAuthRepository(
      authClient: authClient,
      storageService: kvStorage,
    );
  } else {
    // For production and development environments, an HTTP client is needed.
    httpClient = HtHttpClient(
      baseUrl: appConfig.baseUrl,
      tokenProvider: () => authenticationRepository.getAuthToken(),
      isWeb: kIsWeb,
      logger: _logger,
    );
    authClient = HtAuthApi(httpClient: httpClient);
    authenticationRepository = HtAuthRepository(
      authClient: authClient,
      storageService: kvStorage,
    );
  }

  // Conditional data client instantiation based on environment
  HtDataClient<Headline> headlinesClient;
  HtDataClient<Topic> topicsClient;
  HtDataClient<Country> countriesClient;
  HtDataClient<Source> sourcesClient;
  HtDataClient<UserContentPreferences> userContentPreferencesClient;
  HtDataClient<UserAppSettings> userAppSettingsClient;
  HtDataClient<RemoteConfig> remoteConfigClient;

  if (appConfig.environment == app_config.AppEnvironment.demo) {
    headlinesClient = HtDataInMemory<Headline>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: headlinesFixturesData,
      logger: _logger,
    );
    topicsClient = HtDataInMemory<Topic>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: topicsFixturesData,
      logger: _logger,
    );
    countriesClient = HtDataInMemory<Country>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: countriesFixturesData,
      logger: _logger,
    );
    sourcesClient = HtDataInMemory<Source>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: sourcesFixturesData,
      logger: _logger,
    );
    userContentPreferencesClient = HtDataInMemory<UserContentPreferences>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      logger: _logger,
    );
    userAppSettingsClient = HtDataInMemory<UserAppSettings>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      logger: _logger,
    );
    remoteConfigClient = HtDataInMemory<RemoteConfig>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: remoteConfigsFixturesData,
      logger: _logger,
    );
  } else if (appConfig.environment == app_config.AppEnvironment.development) {
    headlinesClient = HtDataApi<Headline>(
      httpClient: httpClient!,
      modelName: 'headline',
      fromJson: Headline.fromJson,
      toJson: (headline) => headline.toJson(),
      logger: _logger,
    );
    topicsClient = HtDataApi<Topic>(
      httpClient: httpClient,
      modelName: 'topic',
      fromJson: Topic.fromJson,
      toJson: (topic) => topic.toJson(),
      logger: _logger,
    );
    countriesClient = HtDataApi<Country>(
      httpClient: httpClient,
      modelName: 'country',
      fromJson: Country.fromJson,
      toJson: (country) => country.toJson(),
      logger: _logger,
    );
    sourcesClient = HtDataApi<Source>(
      httpClient: httpClient,
      modelName: 'source',
      fromJson: Source.fromJson,
      toJson: (source) => source.toJson(),
      logger: _logger,
    );
    userContentPreferencesClient = HtDataApi<UserContentPreferences>(
      httpClient: httpClient,
      modelName: 'user_content_preferences',
      fromJson: UserContentPreferences.fromJson,
      toJson: (prefs) => prefs.toJson(),
      logger: _logger,
    );
    userAppSettingsClient = HtDataApi<UserAppSettings>(
      httpClient: httpClient,
      modelName: 'user_app_settings',
      fromJson: UserAppSettings.fromJson,
      toJson: (settings) => settings.toJson(),
      logger: _logger,
    );
    remoteConfigClient = HtDataApi<RemoteConfig>(
      httpClient: httpClient,
      modelName: 'remote_config',
      fromJson: RemoteConfig.fromJson,
      toJson: (config) => config.toJson(),
      logger: _logger,
    );
  } else {
    // Default to API clients for production
    headlinesClient = HtDataApi<Headline>(
      httpClient: httpClient!,
      modelName: 'headline',
      fromJson: Headline.fromJson,
      toJson: (headline) => headline.toJson(),
      logger: _logger,
    );
    topicsClient = HtDataApi<Topic>(
      httpClient: httpClient,
      modelName: 'topic',
      fromJson: Topic.fromJson,
      toJson: (topic) => topic.toJson(),
      logger: _logger,
    );
    countriesClient = HtDataApi<Country>(
      httpClient: httpClient,
      modelName: 'country',
      fromJson: Country.fromJson,
      toJson: (country) => country.toJson(),
      logger: _logger,
    );
    sourcesClient = HtDataApi<Source>(
      httpClient: httpClient,
      modelName: 'source',
      fromJson: Source.fromJson,
      toJson: (source) => source.toJson(),
      logger: _logger,
    );
    userContentPreferencesClient = HtDataApi<UserContentPreferences>(
      httpClient: httpClient,
      modelName: 'user_content_preferences',
      fromJson: UserContentPreferences.fromJson,
      toJson: (prefs) => prefs.toJson(),
      logger: _logger,
    );
    userAppSettingsClient = HtDataApi<UserAppSettings>(
      httpClient: httpClient,
      modelName: 'user_app_settings',
      fromJson: UserAppSettings.fromJson,
      toJson: (settings) => settings.toJson(),
      logger: _logger,
    );
    remoteConfigClient = HtDataApi<RemoteConfig>(
      httpClient: httpClient,
      modelName: 'remote_config',
      fromJson: RemoteConfig.fromJson,
      toJson: (config) => config.toJson(),
      logger: _logger,
    );
  }

  final headlinesRepository = HtDataRepository<Headline>(
    dataClient: headlinesClient,
  );
  final topicsRepository = HtDataRepository<Topic>(dataClient: topicsClient);
  final countriesRepository = HtDataRepository<Country>(
    dataClient: countriesClient,
  );
  final sourcesRepository = HtDataRepository<Source>(dataClient: sourcesClient);
  final userContentPreferencesRepository =
      HtDataRepository<UserContentPreferences>(
        dataClient: userContentPreferencesClient,
      );
  final userAppSettingsRepository = HtDataRepository<UserAppSettings>(
    dataClient: userAppSettingsClient,
  );
  final remoteConfigRepository = HtDataRepository<RemoteConfig>(
    dataClient: remoteConfigClient,
  );

  // Conditionally instantiate DemoDataMigrationService
  final demoDataMigrationService =
      appConfig.environment == app_config.AppEnvironment.demo
      ? DemoDataMigrationService(
          userAppSettingsRepository: userAppSettingsRepository,
          userContentPreferencesRepository: userContentPreferencesRepository,
        )
      : null;

  return App(
    htAuthenticationRepository: authenticationRepository,
    htHeadlinesRepository: headlinesRepository,
    htTopicsRepository: topicsRepository,
    htCountriesRepository: countriesRepository,
    htSourcesRepository: sourcesRepository,
    htUserAppSettingsRepository: userAppSettingsRepository,
    htUserContentPreferencesRepository: userContentPreferencesRepository,
    htRemoteConfigRepository: remoteConfigRepository,
    kvStorageService: kvStorage,
    environment: environment,
    demoDataMigrationService: demoDataMigrationService,
  );
}
