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

/// {@template app_widget}
/// The root widget of the application.
///
/// This widget is responsible for setting up the dependency injection
/// (RepositoryProviders and BlocProviders) for the entire application.
/// It also orchestrates the initial application startup flow, passing
/// pre-fetched data and services to the [AppBloc] and [_AppView].
/// {@endtemplate}
class App extends StatelessWidget {
  /// {@macro app_widget}
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
    required AdService adService,
    required DataRepository<LocalAd> localAdRepository,
    required GlobalKey<NavigatorState> navigatorKey,
    required InlineAdCacheService inlineAdCacheService,
    required RemoteConfig? initialRemoteConfig,
    required HttpException? initialRemoteConfigError,
    super.key,
    this.demoDataMigrationService,
    this.demoDataInitializerService,
    this.initialUser,
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
       _adService = adService,
       _localAdRepository = localAdRepository,
       _navigatorKey = navigatorKey,
       _inlineAdCacheService = inlineAdCacheService,
       _initialRemoteConfig = initialRemoteConfig,
       _initialRemoteConfigError = initialRemoteConfigError;

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
  final AdService _adService;
  final DataRepository<LocalAd> _localAdRepository;
  final GlobalKey<NavigatorState> _navigatorKey;
  final InlineAdCacheService _inlineAdCacheService;
  final DemoDataMigrationService? demoDataMigrationService;
  final DemoDataInitializerService? demoDataInitializerService;
  final User? initialUser;

  /// The remote configuration fetched during the app's bootstrap phase.
  /// This is used to initialize the AppBloc with the global app status.
  final RemoteConfig? _initialRemoteConfig;

  /// Any error that occurred during the initial remote config fetch.
  final HttpException? _initialRemoteConfigError;

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
            create: (context) =>
                AppBloc(
                  authenticationRepository: context.read<AuthRepository>(),
                  userAppSettingsRepository: context
                      .read<DataRepository<UserAppSettings>>(),
                  userContentPreferencesRepository: context
                      .read<DataRepository<UserContentPreferences>>(),
                  appConfigRepository: context
                      .read<DataRepository<RemoteConfig>>(),
                  userRepository: context.read<DataRepository<User>>(),
                  navigatorKey: _navigatorKey, // Pass navigatorKey to AppBloc
                  initialRemoteConfig:
                      _initialRemoteConfig, // Pass initialRemoteConfig
                  initialRemoteConfigError:
                      _initialRemoteConfigError, // Pass initialRemoteConfigError
                  demoDataMigrationService: demoDataMigrationService,
                  demoDataInitializerService: demoDataInitializerService,
                  initialUser: initialUser,
                )..add(
                  AppStarted(initialUser: initialUser),
                ), // Dispatch AppStarted event
          ),
          BlocProvider(
            create: (context) => AuthenticationBloc(
              authenticationRepository: context.read<AuthRepository>(),
            ),
          ),
          // Provide the InterstitialAdManager as a RepositoryProvider.
          // It depends on the state managed by AppBloc, so it must be created
          // after AppBloc is available.
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
  final AdService adService;
  final DataRepository<LocalAd> localAdRepository;
  final GlobalKey<NavigatorState> navigatorKey;
  final InlineAdCacheService inlineAdCacheService;

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final GoRouter _router;
  late final ValueNotifier<AppLifeCycleStatus> _statusNotifier;
  AppStatusService? _appStatusService;

  @override
  void initState() {
    super.initState();
    final appBloc = context.read<AppBloc>();
    // Initialize the notifier with the BLoC's current state.
    // This notifier is used by GoRouter's refreshListenable to trigger
    // route re-evaluation when the app's lifecycle status changes.
    _statusNotifier = ValueNotifier<AppLifeCycleStatus>(appBloc.state.status);

    // Instantiate and initialize the AppStatusService.
    // This service monitors the app's lifecycle and periodically triggers
    // remote configuration fetches via the AppBloc, ensuring the app status
    // is always fresh (e.g., detecting maintenance mode or forced updates).
    _appStatusService = AppStatusService(
      context: context,
      checkInterval: const Duration(minutes: 15),
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

          if (state.status == AppLifeCycleStatus.criticalError) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: lightTheme(
                scheme: FlexScheme.material,
                appTextScaleFactor: state.appTextScaleFactor,
                appFontWeight: state.appFontWeight,
                fontFamily: state.fontFamily,
              ),
              darkTheme: darkTheme(
                scheme: FlexScheme.material,
                appTextScaleFactor: state.appTextScaleFactor,
                appFontWeight: state.appFontWeight,
                fontFamily: state.fontFamily,
              ),
              themeMode: state.themeMode,
              localizationsDelegates: const [
                ...AppLocalizations.localizationsDelegates,
                ...UiKitLocalizations.localizationsDelegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: state.locale,
              home: CriticalErrorPage(
                exception:
                    state.initialRemoteConfigError ??
                    state.initialUserPreferencesError ??
                    const UnknownException(
                      'An unknown critical error occurred.',
                    ),
                onRetry: () {
                  // If remote config failed, retry remote config.
                  // If user preferences failed, retry AppStarted.
                  if (state.initialRemoteConfigError != null) {
                    context.read<AppBloc>().add(
                      const AppPeriodicConfigFetchRequested(
                        isBackgroundCheck: false,
                      ),
                    );
                  } else if (state.initialUserPreferencesError != null) {
                    context.read<AppBloc>().add(
                      AppStarted(initialUser: state.user),
                    );
                  } else {
                    // Fallback for unknown critical error
                    context.read<AppBloc>().add(
                      AppStarted(initialUser: state.user),
                    );
                  }
                },
              ),
            );
          }

          if (state.status == AppLifeCycleStatus.underMaintenance) {
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
                appTextScaleFactor: state.appTextScaleFactor,
                appFontWeight: state.appFontWeight,
                fontFamily: state.fontFamily,
              ),
              darkTheme: darkTheme(
                scheme: FlexScheme.material,
                appTextScaleFactor: state.appTextScaleFactor,
                appFontWeight: state.appFontWeight,
                fontFamily: state.fontFamily,
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

          if (state.status == AppLifeCycleStatus.updateRequired) {
            // A mandatory update is required. Show the UpdateRequiredPage.
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: lightTheme(
                scheme: FlexScheme.material,
                appTextScaleFactor: state.appTextScaleFactor,
                appFontWeight: state.appFontWeight,
                fontFamily: state.fontFamily,
              ),
              darkTheme: darkTheme(
                scheme: FlexScheme.material,
                appTextScaleFactor: state.appTextScaleFactor,
                appFontWeight: state.appFontWeight,
                fontFamily: state.fontFamily,
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

          // --- Loading User Data State ---
          // --- Loading User Data State ---
          // Display a loading screen ONLY if the app is actively trying to load
          // user-specific data (settings or preferences) for an authenticated/anonymous user.
          // If the status is unauthenticated, it means there's no user data to load,
          // and the app should proceed to the router to show the authentication page.
          if (state.status == AppLifeCycleStatus.loadingUserData) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: lightTheme(
                scheme: FlexScheme.material,
                appTextScaleFactor: state.appTextScaleFactor,
                appFontWeight: state.appFontWeight,
                fontFamily: state.fontFamily,
              ),
              darkTheme: darkTheme(
                scheme: FlexScheme.material,
                appTextScaleFactor: state.appTextScaleFactor,
                appFontWeight: state.appFontWeight,
                fontFamily: state.fontFamily,
              ),
              themeMode: state.themeMode,
              localizationsDelegates: const [
                ...AppLocalizations.localizationsDelegates,
                ...UiKitLocalizations.localizationsDelegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: state.locale,
              home: Builder(
                builder: (context) {
                  return LoadingStateWidget(
                    icon: Icons.sync,
                    headline: AppLocalizations.of(
                      context,
                    ).settingsLoadingHeadline,
                    subheadline: AppLocalizations.of(
                      context,
                    ).settingsLoadingSubheadline,
                  );
                },
              ),
            );
          }

          // --- Main Application UI ---
          // If none of the critical states above are met, and user settings
          // are loaded, the app is ready to display its main UI.
          // We build the MaterialApp.router here.
          // This is the single, STABLE root widget for the entire main app.
          //
          // WHY IS THIS SO IMPORTANT?
          // Because this widget is now built conditionally inside a single
          // BlocBuilder, it is created only ONCE when the app enters a
          // "running" state (e.g., authenticated, anonymous) with all
          // necessary data. It is no longer destroyed and rebuilt during
          // startup, which was the root cause of the `BuildContext` instability
          // and the `l10n` crashes.
          //
          // THEME CONFIGURATION:
          // This MaterialApp is themed using the full, detailed settings
          // loaded into the AppState (e.g., `state.flexScheme`,
          // `state.settings.displaySettings...`), providing the complete,
          // personalized user experience.
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            theme: lightTheme(
              scheme: state.flexScheme,
              appTextScaleFactor: state.appTextScaleFactor,
              appFontWeight: state.appFontWeight,
              fontFamily: state.fontFamily,
            ),
            darkTheme: darkTheme(
              scheme: state.flexScheme,
              appTextScaleFactor: state.appTextScaleFactor,
              appFontWeight: state.appFontWeight,
              fontFamily: state.fontFamily,
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
