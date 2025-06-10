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
import 'package:ht_main/bloc_observer.dart';
import 'package:ht_main/shared/localization/ar_timeago_messages.dart';
import 'package:ht_main/shared/localization/en_timeago_messages.dart';
import 'package:ht_shared/ht_shared.dart';
import 'package:timeago/timeago.dart' as timeago;

Future<Widget> bootstrap(app_config.AppConfig appConfig) async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();

  timeago.setLocaleMessages('en', EnTimeagoMessages());
  timeago.setLocaleMessages('ar', ArTimeagoMessages());

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
    );
    authClient = HtAuthApi(httpClient: httpClient);
    authenticationRepository = HtAuthRepository(
      authClient: authClient,
      storageService: kvStorage,
    );
  }

  // Conditional data client instantiation based on environment
  HtDataClient<Headline> headlinesClient;
  HtDataClient<Category> categoriesClient;
  HtDataClient<Country> countriesClient;
  HtDataClient<Source> sourcesClient;
  HtDataClient<UserContentPreferences> userContentPreferencesClient;
  HtDataClient<UserAppSettings> userAppSettingsClient;
  HtDataClient<AppConfig> appConfigClient;

  if (appConfig.environment == app_config.AppEnvironment.demo) {
    headlinesClient = HtDataInMemory<Headline>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: headlinesFixturesData.map(Headline.fromJson).toList(),
    );
    categoriesClient = HtDataInMemory<Category>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: categoriesFixturesData.map(Category.fromJson).toList(),
    );
    countriesClient = HtDataInMemory<Country>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: countriesFixturesData.map(Country.fromJson).toList(),
    );
    sourcesClient = HtDataInMemory<Source>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: sourcesFixturesData.map(Source.fromJson).toList(),
    );
    userContentPreferencesClient = HtDataInMemory<UserContentPreferences>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
    );
    userAppSettingsClient = HtDataInMemory<UserAppSettings>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
    );
    appConfigClient = HtDataInMemory<AppConfig>(
      toJson: (i) => i.toJson(),
      getId: (i) => i.id,
      initialData: [AppConfig.fromJson(appConfigFixtureData)],
    );
  } else if (appConfig.environment == app_config.AppEnvironment.development) {
    headlinesClient = HtDataApi<Headline>(
      httpClient: httpClient!,
      modelName: 'headline',
      fromJson: Headline.fromJson,
      toJson: (headline) => headline.toJson(),
    );
    categoriesClient = HtDataApi<Category>(
      httpClient: httpClient,
      modelName: 'category',
      fromJson: Category.fromJson,
      toJson: (category) => category.toJson(),
    );
    countriesClient = HtDataApi<Country>(
      httpClient: httpClient,
      modelName: 'country',
      fromJson: Country.fromJson,
      toJson: (country) => country.toJson(),
    );
    sourcesClient = HtDataApi<Source>(
      httpClient: httpClient,
      modelName: 'source',
      fromJson: Source.fromJson,
      toJson: (source) => source.toJson(),
    );
    userContentPreferencesClient = HtDataApi<UserContentPreferences>(
      httpClient: httpClient,
      modelName: 'user_content_preferences',
      fromJson: UserContentPreferences.fromJson,
      toJson: (prefs) => prefs.toJson(),
    );
    userAppSettingsClient = HtDataApi<UserAppSettings>(
      httpClient: httpClient,
      modelName: 'user_app_settings',
      fromJson: UserAppSettings.fromJson,
      toJson: (settings) => settings.toJson(),
    );
    appConfigClient = HtDataApi<AppConfig>(
      httpClient: httpClient,
      modelName: 'app_config',
      fromJson: AppConfig.fromJson,
      toJson: (config) => config.toJson(),
    );
  } else {
    // Default to API clients for production
    headlinesClient = HtDataApi<Headline>(
      httpClient: httpClient!,
      modelName: 'headline',
      fromJson: Headline.fromJson,
      toJson: (headline) => headline.toJson(),
    );
    categoriesClient = HtDataApi<Category>(
      httpClient: httpClient,
      modelName: 'category',
      fromJson: Category.fromJson,
      toJson: (category) => category.toJson(),
    );
    countriesClient = HtDataApi<Country>(
      httpClient: httpClient,
      modelName: 'country',
      fromJson: Country.fromJson,
      toJson: (country) => country.toJson(),
    );
    sourcesClient = HtDataApi<Source>(
      httpClient: httpClient,
      modelName: 'source',
      fromJson: Source.fromJson,
      toJson: (source) => source.toJson(),
    );
    userContentPreferencesClient = HtDataApi<UserContentPreferences>(
      httpClient: httpClient,
      modelName: 'user_content_preferences',
      fromJson: UserContentPreferences.fromJson,
      toJson: (prefs) => prefs.toJson(),
    );
    userAppSettingsClient = HtDataApi<UserAppSettings>(
      httpClient: httpClient,
      modelName: 'user_app_settings',
      fromJson: UserAppSettings.fromJson,
      toJson: (settings) => settings.toJson(),
    );
    appConfigClient = HtDataApi<AppConfig>(
      httpClient: httpClient,
      modelName: 'app_config',
      fromJson: AppConfig.fromJson,
      toJson: (config) => config.toJson(),
    );
  }

  final headlinesRepository = HtDataRepository<Headline>(
    dataClient: headlinesClient,
  );
  final categoriesRepository = HtDataRepository<Category>(
    dataClient: categoriesClient,
  );
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
  final appConfigRepository = HtDataRepository<AppConfig>(
    dataClient: appConfigClient,
  );

  return App(
    htAuthenticationRepository: authenticationRepository,
    htHeadlinesRepository: headlinesRepository,
    htCategoriesRepository: categoriesRepository,
    htCountriesRepository: countriesRepository,
    htSourcesRepository: sourcesRepository,
    htUserAppSettingsRepository: userAppSettingsRepository,
    htUserContentPreferencesRepository: userContentPreferencesRepository,
    htAppConfigRepository: appConfigRepository,
    kvStorageService: kvStorage,
  );
}
