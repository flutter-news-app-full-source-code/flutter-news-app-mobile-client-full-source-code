import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_auth_api/ht_auth_api.dart';
import 'package:ht_auth_repository/ht_auth_repository.dart';
import 'package:ht_data_api/ht_data_api.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_http_client/ht_http_client.dart';
import 'package:ht_kv_storage_shared_preferences/ht_kv_storage_shared_preferences.dart';
import 'package:ht_main/app/app.dart';
import 'package:ht_main/bloc_observer.dart';
import 'package:ht_main/shared/localization/ar_timeago_messages.dart'; // Added
import 'package:ht_shared/ht_shared.dart';
import 'package:timeago/timeago.dart' as timeago; // Added

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();

  // Initialize timeago Arabic messages
  timeago.setLocaleMessages('ar', ArTimeagoMessages());

  // 1. Instantiate KV Storage Service
  final kvStorage = await HtKvStorageSharedPreferences.getInstance();

  // 2. Declare Auth Repository (will be initialized after TokenProvider)
  // This is necessary because the TokenProvider needs a reference to the
  // authenticationRepository instance before it's fully initialized.
  late final HtAuthRepository authenticationRepository;

  // 3. Define Token Provider
  Future<String?> tokenProvider() async {
    return authenticationRepository.getAuthToken();
  }

  // 4. Instantiate HTTP Client
  final httpClient = HtHttpClient(
    baseUrl: 'http://localhost:8080',
    tokenProvider: tokenProvider,
    isWeb: kIsWeb,
  );

  // 5. Instantiate Auth Client and Repository
  // Concrete client implementation is HtAuthApi from ht_auth_api
  final authClient = HtAuthApi(httpClient: httpClient);
  // Initialize the authenticationRepository instance
  authenticationRepository = HtAuthRepository(
    authClient: authClient,
    storageService: kvStorage,
  );

  // 6. Instantiate Data Clients and Repositories for each model type
  // Concrete client implementation is HtDataApi<T> from ht_data_api
  // Each client needs the httpClient, a modelName string, and fromJson/toJson functions.

  final headlinesClient = HtDataApi<Headline>(
    httpClient: httpClient,
    modelName: 'headline',
    fromJson: Headline.fromJson,
    toJson: (headline) => headline.toJson(),
  );
  final headlinesRepository = HtDataRepository<Headline>(
    dataClient: headlinesClient,
  );

  final categoriesClient = HtDataApi<Category>(
    httpClient: httpClient,
    modelName: 'category',
    fromJson: Category.fromJson,
    toJson: (category) => category.toJson(),
  );
  final categoriesRepository = HtDataRepository<Category>(
    dataClient: categoriesClient,
  );

  final countriesClient = HtDataApi<Country>(
    httpClient: httpClient,
    modelName: 'country',
    fromJson: Country.fromJson,
    toJson: (country) => country.toJson(),
  );
  final countriesRepository = HtDataRepository<Country>(
    dataClient: countriesClient,
  );

  final sourcesClient = HtDataApi<Source>(
    httpClient: httpClient,
    modelName: 'source',
    fromJson: Source.fromJson,
    toJson: (source) => source.toJson(),
  );
  final sourcesRepository = HtDataRepository<Source>(dataClient: sourcesClient);

  final userContentPreferencesClient = HtDataApi<UserContentPreferences>(
    httpClient: httpClient,
    modelName: 'user_content_preferences',
    fromJson: UserContentPreferences.fromJson,
    toJson: (prefs) => prefs.toJson(),
  );
  final userContentPreferencesRepository =
      HtDataRepository<UserContentPreferences>(
        dataClient: userContentPreferencesClient,
      );

  final userAppSettingsClient = HtDataApi<UserAppSettings>(
    httpClient: httpClient,
    modelName: 'user_app_settings',
    fromJson: UserAppSettings.fromJson,
    toJson: (settings) => settings.toJson(),
  );
  final userAppSettingsRepository = HtDataRepository<UserAppSettings>(
    dataClient: userAppSettingsClient,
  );

  final appConfigClient = HtDataApi<AppConfig>(
    httpClient: httpClient,
    modelName: 'app_config',
    fromJson: AppConfig.fromJson,
    toJson: (config) => config.toJson(),
  );
  final appConfigRepository = HtDataRepository<AppConfig>(
    dataClient: appConfigClient,
  );

  // 7. Run the App, injecting repositories
  runApp(
    App(
      htAuthenticationRepository: authenticationRepository,
      htHeadlinesRepository: headlinesRepository,
      htCategoriesRepository: categoriesRepository,
      htCountriesRepository: countriesRepository,
      htSourcesRepository: sourcesRepository,
      htUserAppSettingsRepository: userAppSettingsRepository,
      htUserContentPreferencesRepository: userContentPreferencesRepository,
      htAppConfigRepository: appConfigRepository,
      kvStorageService: kvStorage,
    ),
  );
}
