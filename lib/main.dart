import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_auth_api/ht_auth_api.dart'; // Concrete Auth Client Impl
import 'package:ht_auth_repository/ht_auth_repository.dart'; // Auth Repository
import 'package:ht_data_api/ht_data_api.dart'; // Concrete Data Client Impl
import 'package:ht_data_repository/ht_data_repository.dart'; // Data Repository
import 'package:ht_http_client/ht_http_client.dart'; // HTTP Client
import 'package:ht_kv_storage_shared_preferences/ht_kv_storage_shared_preferences.dart'; // KV Storage Impl
import 'package:ht_main/app/app.dart'; // The App widget
import 'package:ht_main/bloc_observer.dart'; // App Bloc Observer
import 'package:ht_shared/ht_shared.dart'; // Shared models, FromJson, ToJson, etc.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();

  // 1. Instantiate KV Storage Service
  final kvStorage = await HtKvStorageSharedPreferences.getInstance();

  // 2. Declare Auth Repository (will be initialized after TokenProvider)
  // This is necessary because the TokenProvider needs a reference to the
  // authenticationRepository instance before it's fully initialized.
  late final HtAuthRepository authenticationRepository;

  // 3. Define Token Provider
  // TODO(refactor): This is a temporary workaround. The HtAuthRepository
  // should be refactored to provide a public method/getter to retrieve
  // the current authentication token string. This function should then
  // call that method.
  Future<String?> tokenProvider() async {
    // For now, return null as we don't have a way to get the token
    // from the current HtAuthRepository implementation.
    // The HtHttpClient will make unauthenticated requests by default.
    // The authentication flow will handle obtaining and storing the token
    // via the HtAuthRepository's signIn/verify methods.
    // A future refactor is needed to make the token available here.
    return null;
  }

  // 4. Instantiate HTTP Client
  final httpClient = HtHttpClient(
    baseUrl: 'http://localhost:8080', // Provided base URL for Dart Frog backend
    tokenProvider: tokenProvider,
  );

  // 5. Instantiate Auth Client and Repository
  // Concrete client implementation is HtAuthApi from ht_auth_api
  final authClient = HtAuthApi(httpClient: httpClient);
  // Initialize the authenticationRepository instance
  authenticationRepository = HtAuthRepository(
    authClient: authClient,
    // storageService is not a parameter based on errors.
    // Token persistence must be handled within HtAuthRepository using HtKVStorageService internally.
  );

  // 6. Instantiate Data Clients and Repositories for each model type
  // Concrete client implementation is HtDataApi<T> from ht_data_api
  // Each client needs the httpClient, a modelName string, and fromJson/toJson functions.

  final headlinesClient = HtDataApi<Headline>(
    httpClient: httpClient,
    modelName: 'headline', // Assuming 'headline' is the model name for the API
    fromJson: Headline.fromJson,
    toJson: (headline) => headline.toJson(),
  );
  final headlinesRepository = HtDataRepository<Headline>(
    dataClient: headlinesClient,
  );

  final categoriesClient = HtDataApi<Category>(
    httpClient: httpClient,
    modelName: 'category', // Assuming 'category' is the model name for the API
    fromJson: Category.fromJson,
    toJson: (category) => category.toJson(),
  );
  final categoriesRepository = HtDataRepository<Category>(
    dataClient: categoriesClient,
  );

  final countriesClient = HtDataApi<Country>(
    httpClient: httpClient,
    modelName: 'country', // Assuming 'country' is the model name for the API
    fromJson: Country.fromJson,
    toJson: (country) => country.toJson(),
  );
  final countriesRepository = HtDataRepository<Country>(
    dataClient: countriesClient,
  );

  final sourcesClient = HtDataApi<Source>(
    httpClient: httpClient,
    modelName: 'source', // Assuming 'source' is the model name for the API
    fromJson: Source.fromJson,
    toJson: (source) => source.toJson(),
  );
  final sourcesRepository = HtDataRepository<Source>(dataClient: sourcesClient);

  final userContentPreferencesClient = HtDataApi<UserContentPreferences>(
    httpClient: httpClient,
    modelName: 'user_content_preferences', // Assuming model name
    fromJson: UserContentPreferences.fromJson,
    toJson: (prefs) => prefs.toJson(),
  );
  final userContentPreferencesRepository =
      HtDataRepository<UserContentPreferences>(
        dataClient: userContentPreferencesClient,
      );

  final userAppSettingsClient = HtDataApi<UserAppSettings>(
    httpClient: httpClient,
    modelName: 'user_app_settings', // Assuming model name
    fromJson: UserAppSettings.fromJson,
    toJson: (settings) => settings.toJson(),
  );
  final userAppSettingsRepository = HtDataRepository<UserAppSettings>(
    dataClient: userAppSettingsClient,
  );

  // Assuming AppConfig model exists in ht_shared and has fromJson/toJson
  final appConfigClient = HtDataApi<AppConfig>(
    httpClient: httpClient,
    modelName: 'app_config', // Assuming model name
    fromJson: AppConfig.fromJson,
    toJson: (config) => config.toJson(),
  );
  final appConfigRepository = HtDataRepository<AppConfig>(
    dataClient: appConfigClient,
  );

  // 7. Run the App, injecting repositories
  // NOTE: The App widget constructor currently expects specific repository types.
  // This will cause type errors that will be fixed in the next step (Step 3)
  // when we refactor the App widget and router.
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
