import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart' hide AppStatus;
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_initializer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_status_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_initializer_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_migration_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/package_info_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/router.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/status/view/view.dart';
import 'package:kv_storage_service/kv_storage_service.dart';
import 'package:logging/logging.dart';
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
    required InitializationResult initializationResult,
    required AuthRepository authenticationRepository,
    required DataRepository<Headline> headlinesRepository,
    required DataRepository<Topic> topicsRepository,
    required DataRepository<Country> countriesRepository,
    required DataRepository<Source> sourcesRepository,
    required DataRepository<UserAppSettings>
    userAppSettingsRepository, // Will be removed
    required DataRepository<UserContentPreferences>
    userContentPreferencesRepository, // Will be removed
    required DataRepository<RemoteConfig>
    remoteConfigRepository, // Will be removed
    required DataRepository<User> userRepository, // Will be removed
    required KVStorageService kvStorageService, // Will be removed
    required AppEnvironment environment, // Will be removed
    required InlineAdCacheService inlineAdCacheService,
    required AdService adService,
    required DataRepository<LocalAd> localAdRepository,
    required GlobalKey<NavigatorState> navigatorKey,
    super.key,
  }) : _initializationResult = initializationResult,
       _authenticationRepository = authenticationRepository,
       _headlinesRepository = headlinesRepository,
       _topicsRepository = topicsRepository,
       _countriesRepository = countriesRepository,
       _sourcesRepository = sourcesRepository,
       _userAppSettingsRepository =
           userAppSettingsRepository, // Will be removed
       _userContentPreferencesRepository =
           userContentPreferencesRepository, // Will be removed
       _appConfigRepository = remoteConfigRepository, // Will be removed
       _userRepository = userRepository, // Will be removed
       _kvStorageService = kvStorageService, // Will be removed
       _environment = environment, // Will be removed
       _adService = adService,
       _localAdRepository = localAdRepository,
       _navigatorKey = navigatorKey,
       _inlineAdCacheService = inlineAdCacheService; // Will be removed

  final InitializationResult _initializationResult;
  final AuthRepository _authenticationRepository;
  final DataRepository<Headline> _headlinesRepository;
  final DataRepository<Topic> _topicsRepository;
  final DataRepository<Country> _countriesRepository;
  final DataRepository<Source> _sourcesRepository;
  final DataRepository<UserAppSettings>
  _userAppSettingsRepository; // Will be removed
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository; // Will be removed
  final DataRepository<RemoteConfig> _appConfigRepository; // Will be removed
  final DataRepository<User> _userRepository; // Will be removed
  final KVStorageService _kvStorageService; // Will be removed
  final AppEnvironment _environment; // Will be removed
  final AdService _adService;
  final DataRepository<LocalAd> _localAdRepository;
  final GlobalKey<NavigatorState> _navigatorKey;
  final InlineAdCacheService _inlineAdCacheService; // Will be removed

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authenticationRepository),
        RepositoryProvider.value(value: _headlinesRepository),
        RepositoryProvider.value(value: _topicsRepository),
        RepositoryProvider.value(value: _countriesRepository),
        RepositoryProvider.value(value: _sourcesRepository),
        RepositoryProvider.value(
          value: _userAppSettingsRepository,
        ), // Will be removed
        RepositoryProvider.value(
          value: _userContentPreferencesRepository,
        ), // Will be removed
        RepositoryProvider.value(
          value: _appConfigRepository,
        ), // Will be removed
        RepositoryProvider.value(value: _userRepository), // Will be removed
        RepositoryProvider.value(value: _kvStorageService), // Will be removed
        RepositoryProvider.value(value: _adService),
        RepositoryProvider.value(value: _localAdRepository),
        RepositoryProvider.value(
          value: _inlineAdCacheService,
        ), // Will be removed
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AppBloc(
              initializationResult: _initializationResult,
              navigatorKey: _navigatorKey,
            )..add(const AppStarted()),
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
            // Ensure it's created immediately
            lazy: false,
          ),
          // Provide the ContentLimitationService.
          // It depends on AppBloc, so it is created here.
          RepositoryProvider(
            create: (context) =>
                ContentLimitationService(appBloc: context.read<AppBloc>()),
          ),
        ],
        child: _AppView(
          authenticationRepository: _authenticationRepository,
          headlinesRepository: _headlinesRepository,
          topicRepository: _topicsRepository,
          countriesRepository: _countriesRepository, // Will be removed
          sourcesRepository: _sourcesRepository, // Will be removed
          userAppSettingsRepository:
              _userAppSettingsRepository, // Will be removed
          userContentPreferencesRepository:
              _userContentPreferencesRepository, // Will be removed
          appConfigRepository: _appConfigRepository, // Will be removed
          userRepository: _userRepository, // Will be removed
          environment: _environment, // Will be removed
          adService: _adService,
          localAdRepository: _localAdRepository,
          navigatorKey: _navigatorKey,
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
    required this.countriesRepository, // Will be removed
    required this.sourcesRepository, // Will be removed
    required this.userAppSettingsRepository, // Will be removed
    required this.userContentPreferencesRepository, // Will be removed
    required this.appConfigRepository, // Will be removed
    required this.userRepository, // Will be removed
    required this.environment, // Will be removed
    required this.adService,
    required this.localAdRepository,
    required this.navigatorKey,
  });

  final AuthRepository authenticationRepository;
  final DataRepository<Headline> headlinesRepository;
  final DataRepository<Topic> topicRepository;
  final DataRepository<Country> countriesRepository; // Will be removed
  final DataRepository<Source> sourcesRepository; // Will be removed
  final DataRepository<UserAppSettings>
  userAppSettingsRepository; // Will be removed
  final DataRepository<UserContentPreferences>
  userContentPreferencesRepository; // Will be removed
  final DataRepository<RemoteConfig> appConfigRepository; // Will be removed
  final DataRepository<User> userRepository; // Will be removed
  final AppEnvironment environment; // Will be removed
  final AdService adService;
  final DataRepository<LocalAd> localAdRepository;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final ValueNotifier<AppLifeCycleStatus> _statusNotifier;
  AppStatusService? _appStatusService;
  final _routerLogger = Logger('GoRouter');

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
      environment: widget.environment,
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
              themeMode: state.themeMode,
              localizationsDelegates: const [
                ...AppLocalizations.localizationsDelegates,
                ...UiKitLocalizations.localizationsDelegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: state.locale,
              home: CriticalErrorPage(
                exception:
                    state.error ?? // This will be fixed in the next step
                    const UnknownException(
                      'An unknown critical error occurred.',
                    ),
                onRetry: () {
                  // Retrying a critical error requires a full app restart.
                  // For now, we can just re-trigger the AppStarted event.
                  context.read<AppBloc>().add(const AppStarted());
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
              themeMode: state.themeMode,
              localizationsDelegates: const [
                ...AppLocalizations.localizationsDelegates,
                ...UiKitLocalizations.localizationsDelegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: state.locale,
              home: UpdateRequiredPage(
                iosUpdateUrl: state.remoteConfig!.appStatus.iosUpdateUrl,
                androidUpdateUrl:
                    state.remoteConfig!.appStatus.androidUpdateUrl,
                currentAppVersion: state.currentAppVersion,
                latestRequiredVersion: state.latestAppVersion,
              ),
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
            routerConfig: createRouter(
              authStatusNotifier: _statusNotifier,
              authenticationRepository: widget.authenticationRepository,
              headlinesRepository: widget.headlinesRepository,
              topicsRepository: widget.topicRepository,
              countriesRepository: widget.countriesRepository,
              sourcesRepository: widget.sourcesRepository,
              adService: widget.adService,
              navigatorKey: widget.navigatorKey,
              logger: _routerLogger,
            ),
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
