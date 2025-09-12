import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart' hide AppStatus;
import 'package:data_repository/data_repository.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_status_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_initializer_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_migration_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/router.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/status/view/view.dart';
import 'package:go_router/go_router.dart';
import 'package:kv_storage_service/kv_storage_service.dart';
import 'package:ui_kit/ui_kit.dart';

class App extends StatelessWidget {
  const App({
    required AuthRepository authenticationRepository,
    required DataRepository<Headline> headlinesRepository,
    required DataRepository<Topic> topicsRepository,
    required DataRepository<Country> countriesRepository,
    required DataRepository<Source> sourcesRepository,
    required DataRepository<UserAppSettings> userAppSettingsRepository,
    required DataRepository<UserContentPreferences>
    userContentPreferencesRepository,
    required DataRepository<RemoteConfig> remoteConfigRepository,
    required DataRepository<User> userRepository,
    required KVStorageService kvStorageService,
    required AppEnvironment environment,
    required AdService adService,
    required DataRepository<LocalAd> localAdRepository,
    required GlobalKey<NavigatorState> navigatorKey,
    required InlineAdCacheService inlineAdCacheService,
    this.demoDataMigrationService,
    this.demoDataInitializerService,
    this.initialUser,
    super.key,
  }) : _authenticationRepository = authenticationRepository,
       _headlinesRepository = headlinesRepository,
       _topicsRepository = topicsRepository,
       _countriesRepository = countriesRepository,
       _sourcesRepository = sourcesRepository,
       _userAppSettingsRepository = userAppSettingsRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _appConfigRepository = remoteConfigRepository,
       _userRepository = userRepository,
       _kvStorageService = kvStorageService,
       _environment = environment,
       _adService = adService,
       _localAdRepository = localAdRepository,
       _navigatorKey = navigatorKey,
       _inlineAdCacheService = inlineAdCacheService;

  final AuthRepository _authenticationRepository;
  final DataRepository<Headline> _headlinesRepository;
  final DataRepository<Topic> _topicsRepository;
  final DataRepository<Country> _countriesRepository;
  final DataRepository<Source> _sourcesRepository;
  final DataRepository<UserAppSettings> _userAppSettingsRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final DataRepository<RemoteConfig> _appConfigRepository;
  final DataRepository<User> _userRepository;
  final KVStorageService _kvStorageService;
  final AppEnvironment _environment;
  final AdService _adService;
  final DataRepository<LocalAd> _localAdRepository;
  final GlobalKey<NavigatorState> _navigatorKey;
  final InlineAdCacheService _inlineAdCacheService;
  final DemoDataMigrationService? demoDataMigrationService;
  final DemoDataInitializerService? demoDataInitializerService;
  final User? initialUser;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authenticationRepository),
        RepositoryProvider.value(value: _headlinesRepository),
        RepositoryProvider.value(value: _topicsRepository),
        RepositoryProvider.value(value: _countriesRepository),
        RepositoryProvider.value(value: _sourcesRepository),
        RepositoryProvider.value(value: _userAppSettingsRepository),
        RepositoryProvider.value(value: _userContentPreferencesRepository),
        RepositoryProvider.value(value: _appConfigRepository),
        RepositoryProvider.value(value: _userRepository),
        RepositoryProvider.value(value: _kvStorageService),
        RepositoryProvider.value(value: _adService),
        RepositoryProvider.value(value: _localAdRepository),
        RepositoryProvider.value(value: _inlineAdCacheService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AppBloc(
              authenticationRepository: context.read<AuthRepository>(),
              userAppSettingsRepository: context
                  .read<DataRepository<UserAppSettings>>(),
              appConfigRepository: context.read<DataRepository<RemoteConfig>>(),
              userRepository: context.read<DataRepository<User>>(),
              environment: _environment,
              demoDataMigrationService: demoDataMigrationService,
              demoDataInitializerService: demoDataInitializerService,
              initialUser: initialUser,
              navigatorKey: _navigatorKey, // Pass navigatorKey to AppBloc
            ),
          ),
          BlocProvider(
            create: (context) => AuthenticationBloc(
              authenticationRepository: context.read<AuthRepository>(),
            ),
          ),
          // Provide the InterstitialAdManager as a RepositoryProvider
          // it  depends on the state managed by AppBloc. Therefore,
          // so it must be created after AppBloc is available.
          RepositoryProvider(
            create: (context) => InterstitialAdManager(
              appBloc: context.read<AppBloc>(),
              adService: context.read<AdService>(),
            ),
            lazy: false, // Ensure it's created immediately
          ),
        ],
        child: _AppView(
          authenticationRepository: _authenticationRepository,
          headlinesRepository: _headlinesRepository,
          topicRepository: _topicsRepository,
          countriesRepository: _countriesRepository,
          sourcesRepository: _sourcesRepository,
          userAppSettingsRepository: _userAppSettingsRepository,
          userContentPreferencesRepository: _userContentPreferencesRepository,
          appConfigRepository: _appConfigRepository,
          userRepository: _userRepository,
          environment: _environment,
          adService: _adService,
          localAdRepository: _localAdRepository,
          navigatorKey: _navigatorKey, // Pass navigatorKey to _AppView
          inlineAdCacheService: _inlineAdCacheService,
        ),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView({
    required this.authenticationRepository,
    required this.headlinesRepository,
    required this.topicRepository,
    required this.countriesRepository,
    required this.sourcesRepository,
    required this.userAppSettingsRepository,
    required this.userContentPreferencesRepository,
    required this.appConfigRepository,
    required this.userRepository,
    required this.environment,
    required this.adService,
    required this.localAdRepository,
    required this.navigatorKey,
    required this.inlineAdCacheService,
  });

  final AuthRepository authenticationRepository;
  final DataRepository<Headline> headlinesRepository;
  final DataRepository<Topic> topicRepository;
  final DataRepository<Country> countriesRepository;
  final DataRepository<Source> sourcesRepository;
  final DataRepository<UserAppSettings> userAppSettingsRepository;
  final DataRepository<UserContentPreferences> userContentPreferencesRepository;
  final DataRepository<RemoteConfig> appConfigRepository;
  final DataRepository<User> userRepository;
  final AppEnvironment environment;
  final AdService adService;
  final DataRepository<LocalAd> localAdRepository;
  final GlobalKey<NavigatorState> navigatorKey;
  final InlineAdCacheService inlineAdCacheService;

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final GoRouter _router;
  late final ValueNotifier<AppStatus> _statusNotifier;
  AppStatusService? _appStatusService;

  @override
  void initState() {
    super.initState();
    final appBloc = context.read<AppBloc>();
    // Initialize the notifier with the BLoC's current state
    _statusNotifier = ValueNotifier<AppStatus>(appBloc.state.status);

    // Instantiate and initialize the AppStatusService.
    // This service will automatically trigger checks when the app is resumed
    // or at periodic intervals, ensuring the app status is always fresh.
    _appStatusService = AppStatusService(
      context: context,
      checkInterval: const Duration(minutes: 15),
      environment: widget.environment,
    );

    _router = createRouter(
      authStatusNotifier: _statusNotifier,
      authenticationRepository: widget.authenticationRepository,
      headlinesRepository: widget.headlinesRepository,
      topicsRepository: widget.topicRepository,
      countriesRepository: widget.countriesRepository,
      sourcesRepository: widget.sourcesRepository,
      userAppSettingsRepository: widget.userAppSettingsRepository,
      userContentPreferencesRepository: widget.userContentPreferencesRepository,
      remoteConfigRepository: widget.appConfigRepository,
      userRepository: widget.userRepository,
      adService: widget.adService,
      navigatorKey: widget.navigatorKey,
      inlineAdCacheService: widget.inlineAdCacheService,
    );
  }

  @override
  void dispose() {
    _statusNotifier.dispose();
    // Dispose the AppStatusService to cancel timers and remove observers.
    _appStatusService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the part of the tree that needs to react to AppBloc state changes
    // with a BlocListener and a BlocBuilder.
    return BlocListener<AppBloc, AppState>(
      // The BlocListener's primary role here is to keep GoRouter's refresh
      // mechanism informed about authentication status changes.
      // GoRouter's `redirect` logic depends on this notifier to re-evaluate
      // routes when the user logs in or out *while the app is running*.
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        _statusNotifier.value = state.status;
      },
      // The BlocBuilder is the core of the new stable startup architecture.
      // It functions as a "master switch" for the entire application's UI.
      // Based on the AppStatus, it decides whether to show a full-screen
      // status page (like Maintenance or Loading) or to build the main
      // application UI with its nested router. This approach is fundamental
      // to fixing the original race conditions and BuildContext instability.
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          // --- Full-Screen Status Pages ---
          // The following states represent critical, app-wide conditions that
          // must be handled before the main router and UI are displayed.
          // By returning a dedicated widget here, we ensure these pages are
          // full-screen and exist outside the main app's navigation shell.

          if (state.status == AppStatus.underMaintenance) {
            // The app is in maintenance mode. Show the MaintenancePage.
            //
            // WHY A SEPARATE MATERIALAPP?
            // Each status page is wrapped in its own simple MaterialApp to create
            // a self-contained environment. This provides the necessary
            // Directionality, theme, and localization context for the page
            // to render correctly, without needing the main app's router.
            //
            // WHY A DEFAULT THEME?
            // The theme uses hardcoded, sensible defaults (like FlexScheme.material)
            // because at this early stage, we only need a basic visual structure.
            // However, we critically use `state.themeMode` and `state.locale`,
            // which are loaded from user settings *before* the maintenance check,
            // ensuring the page respects the user's chosen light/dark mode and language.
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: lightTheme(
                scheme: FlexScheme.material,
                appTextScaleFactor: AppTextScaleFactor.medium,
                appFontWeight: AppFontWeight.regular,
                fontFamily: null,
              ),
              darkTheme: darkTheme(
                scheme: FlexScheme.material,
                appTextScaleFactor: AppTextScaleFactor.medium,
                appFontWeight: AppFontWeight.regular,
                fontFamily: null,
              ),
              themeMode: state.themeMode,
              localizationsDelegates: const [
                ...AppLocalizations.localizationsDelegates,
                ...UiKitLocalizations.localizationsDelegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: state.locale,
              home: const MaintenancePage(),
            );
          }

          if (state.status == AppStatus.updateRequired) {
            // A mandatory update is required. Show the UpdateRequiredPage.
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: lightTheme(
                scheme: FlexScheme.material,
                appTextScaleFactor: AppTextScaleFactor.medium,
                appFontWeight: AppFontWeight.regular,
                fontFamily: null,
              ),
              darkTheme: darkTheme(
                scheme: FlexScheme.material,
                appTextScaleFactor: AppTextScaleFactor.medium,
                appFontWeight: AppFontWeight.regular,
                fontFamily: null,
              ),
              themeMode: state.themeMode,
              localizationsDelegates: const [
                ...AppLocalizations.localizationsDelegates,
                ...UiKitLocalizations.localizationsDelegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: state.locale,
              home: const UpdateRequiredPage(),
            );
          }

          if (state.status == AppStatus.configFetching ||
              state.status == AppStatus.configFetchFailed) {
            // The app is in the process of fetching its initial remote
            // configuration or has failed to do so. The StatusPage handles
            // both the loading indicator and the retry mechanism.
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: lightTheme(
                scheme: FlexScheme.material,
                appTextScaleFactor: AppTextScaleFactor.medium,
                appFontWeight: AppFontWeight.regular,
                fontFamily: null,
              ),
              darkTheme: darkTheme(
                scheme: FlexScheme.material,
                appTextScaleFactor: AppTextScaleFactor.medium,
                appFontWeight: AppFontWeight.regular,
                fontFamily: null,
              ),
              themeMode: state.themeMode,
              localizationsDelegates: const [
                ...AppLocalizations.localizationsDelegates,
                ...UiKitLocalizations.localizationsDelegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: state.locale,
              home: const StatusPage(),
            );
          }

          // --- Main Application UI ---
          // If none of the critical states above are met, the app is ready
          // to display its main UI. We build the MaterialApp.router here.
          // This is the single, STABLE root widget for the entire main app.
          //
          // WHY IS THIS SO IMPORTANT?
          // Because this widget is now built conditionally inside a single
          // BlocBuilder, it is created only ONCE when the app enters a
          // "running" state (e.g., authenticated, anonymous). It is no longer
          // destroyed and rebuilt during startup, which was the root cause of
          // the `BuildContext` instability and the `l10n` crashes.
          //
          // THEME CONFIGURATION:
          // Unlike the status pages, this MaterialApp is themed using the full,
          // detailed settings loaded into the AppState (e.g., `state.flexScheme`,
          // `state.settings.displaySettings...`), providing the complete,
          // personalized user experience.
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            theme: lightTheme(
              scheme: state.flexScheme,
              appTextScaleFactor:
                  state.settings.displaySettings.textScaleFactor,
              appFontWeight: state.settings.displaySettings.fontWeight,
              fontFamily: state.settings.displaySettings.fontFamily,
            ),
            darkTheme: darkTheme(
              scheme: state.flexScheme,
              appTextScaleFactor:
                  state.settings.displaySettings.textScaleFactor,
              appFontWeight: state.settings.displaySettings.fontWeight,
              fontFamily: state.settings.displaySettings.fontFamily,
            ),
            routerConfig: _router,
            locale: state.locale,
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              ...UiKitLocalizations.localizationsDelegates,
            ],
            supportedLocales: const [
              ...AppLocalizations.supportedLocales,
              ...UiKitLocalizations.supportedLocales,
            ],
          );
        },
      ),
    );
  }
}
