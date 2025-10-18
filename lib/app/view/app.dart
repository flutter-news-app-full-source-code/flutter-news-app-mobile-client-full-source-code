import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart' hide AppStatus;
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_initializer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_status_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/router.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/status/view/view.dart';
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template app_widget}
/// The root widget of the main application.
///
/// This widget is built only after a successful startup sequence, as
/// orchestrated by [AppInitializationPage]. It is responsible for setting up
/// the core dependency injection (RepositoryProviders and BlocProviders) for the
/// running application. It receives all pre-fetched data from the
/// initialization phase and uses it to create the main [AppBloc].
/// {@endtemplate}
class App extends StatelessWidget {
  /// {@macro app_widget}
  const App({
    required this.user,
    required this.remoteConfig,
    required this.settings,
    required this.userContentPreferences,
    required AuthRepository authenticationRepository,
    required DataRepository<Headline> headlinesRepository,
    required DataRepository<Topic> topicsRepository,
    required DataRepository<Country> countriesRepository,
    required DataRepository<Source> sourcesRepository,
    required DataRepository<User> userRepository,
    required DataRepository<RemoteConfig> remoteConfigRepository,
    required DataRepository<UserAppSettings> userAppSettingsRepository,
    required DataRepository<UserContentPreferences>
        userContentPreferencesRepository,
    required AppEnvironment environment,
    required InlineAdCacheService inlineAdCacheService,
    required AdService adService,
    required DataRepository<LocalAd> localAdRepository,
    required GlobalKey<NavigatorState> navigatorKey,
    super.key,
  })  : _authenticationRepository = authenticationRepository,
        _headlinesRepository = headlinesRepository,
        _topicsRepository = topicsRepository,
        _countriesRepository = countriesRepository,
        _sourcesRepository = sourcesRepository,
        _userRepository = userRepository,
        _remoteConfigRepository = remoteConfigRepository,
        _userAppSettingsRepository = userAppSettingsRepository,
        _userContentPreferencesRepository = userContentPreferencesRepository,
        _environment = environment,
        _adService = adService,
        _localAdRepository = localAdRepository,
        _navigatorKey = navigatorKey,
        _inlineAdCacheService = inlineAdCacheService;

  /// The initial user, pre-fetched during startup.
  final User? user;

  /// The global remote configuration, pre-fetched during startup.
  final RemoteConfig remoteConfig;

  /// The user's settings, pre-fetched during startup.
  final UserAppSettings? settings;

  /// The user's content preferences, pre-fetched during startup.
  final UserContentPreferences? userContentPreferences;

  final AuthRepository _authenticationRepository;
  final DataRepository<Headline> _headlinesRepository;
  final DataRepository<Topic> _topicsRepository;
  final DataRepository<Country> _countriesRepository;
  final DataRepository<Source> _sourcesRepository;
  final DataRepository<User> _userRepository;
  final DataRepository<RemoteConfig> _remoteConfigRepository;
  final DataRepository<UserAppSettings> _userAppSettingsRepository;
  final DataRepository<UserContentPreferences>
      _userContentPreferencesRepository;
  final AppEnvironment _environment;
  final AdService _adService;
  final DataRepository<LocalAd> _localAdRepository;
  final GlobalKey<NavigatorState> _navigatorKey;
  final InlineAdCacheService _inlineAdCacheService;

  @override
  Widget build(BuildContext context) {
    // The MultiRepositoryProvider makes all essential repositories and services
    // available to the entire widget tree. This is the single source for all
    // app dependencies.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authenticationRepository),
        RepositoryProvider.value(value: _headlinesRepository),
        RepositoryProvider.value(value: _topicsRepository),
        RepositoryProvider.value(value: _countriesRepository),
        RepositoryProvider.value(value: _sourcesRepository),
        RepositoryProvider.value(value: _adService),
        RepositoryProvider.value(value: _userRepository),
        RepositoryProvider.value(value: _remoteConfigRepository),
        RepositoryProvider.value(value: _userAppSettingsRepository),
        RepositoryProvider.value(value: _userContentPreferencesRepository),
        RepositoryProvider.value(value: _localAdRepository),
        RepositoryProvider.value(value: _inlineAdCacheService),
        RepositoryProvider.value(value: _environment),
        // NOTE: The AppInitializer is provided at the root in bootstrap.dart
        // and is accessed via context.read() in the AppBloc.
      ],
      child: MultiBlocProvider(
        providers: [
          // The main AppBloc is created here with all the pre-fetched data.
          BlocProvider(
            create: (context) => AppBloc(
              user: user,
              remoteConfig: remoteConfig,
              settings: settings,
              userContentPreferences: userContentPreferences,
              remoteConfigRepository: _remoteConfigRepository,
              appInitializer: context.read<AppInitializer>(),
              authRepository: context.read<AuthRepository>(),
              userAppSettingsRepository: _userAppSettingsRepository,
              userContentPreferencesRepository:
                  _userContentPreferencesRepository,
              userRepository: _userRepository,
            )..add(const AppStarted()),
          ),
          // The AuthenticationBloc is provided to handle auth UI events.
          BlocProvider(
            create: (context) => AuthenticationBloc(
              authenticationRepository: context.read<AuthRepository>(),
            ),
          ),
        ],
        child: _AppView(environment: _environment, navigatorKey: _navigatorKey),
      ),
    );
  }
}

/// The core view of the application, which builds the UI based on the
/// [AppBloc]'s state.
class _AppView extends StatefulWidget {
  const _AppView({required this.environment, required this.navigatorKey});

  final AppEnvironment environment;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final ValueNotifier<AppLifeCycleStatus> _statusNotifier;
  StreamSubscription<User?>? _userSubscription;
  AppStatusService? _appStatusService;
  final _routerLogger = Logger('GoRouter');

  @override
  void initState() {
    super.initState();
    final appBloc = context.read<AppBloc>();

    // This notifier is used by GoRouter's refreshListenable to trigger
    // route re-evaluation when the app's lifecycle status changes (e.g.,
    // login/logout), ensuring the correct routes are accessible.
    _statusNotifier = ValueNotifier<AppLifeCycleStatus>(appBloc.state.status);

    // Subscribe to the authentication repository's authStateChanges stream.
    // This stream is the single source of truth for the user's auth state
    // and drives the entire app lifecycle by dispatching AppUserChanged events.
    _userSubscription = context.read<AuthRepository>().authStateChanges.listen(
          (user) => context.read<AppBloc>().add(AppUserChanged(user)),
        );

    // Instantiate and initialize the AppStatusService.
    // This service monitors the app's lifecycle (e.g., resuming from
    // background) and periodically triggers remote configuration fetches,
    // ensuring the app status is always fresh.
    _appStatusService = AppStatusService(
      context: context,
      checkInterval: const Duration(minutes: 15),
      environment: widget.environment,
    );
  }

  @override
  void dispose() {
    _statusNotifier.dispose();
    _userSubscription?.cancel();
    _appStatusService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This BlocListener keeps GoRouter's refresh mechanism informed about
    // authentication status changes. GoRouter's `redirect` logic depends on
    // this notifier to re-evaluate routes when the user logs in or out
    // *while the app is running*.
    return BlocListener<AppBloc, AppState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        _statusNotifier.value = state.status;
      },
      // This BlocBuilder is the "master switch" for the entire application's
      // UI. Based on the AppStatus, it decides whether to show a full-screen
      // status page (like Maintenance) or to build the main application UI
      // with its nested router. This is fundamental to the new, stable
      // startup architecture.
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          // --- Full-Screen Status Pages ---
          // The following states represent critical, app-wide conditions that
          // must be handled before the main router and UI are displayed.

          if (state.status == AppLifeCycleStatus.underMaintenance) {
            // The app is in maintenance mode. Show the MaintenancePage.
            // Each status page is wrapped in its own simple MaterialApp to
            // create a self-contained environment with the necessary theme
            // and localization context to render correctly.
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
                iosUpdateUrl: state.remoteConfig?.appStatus.iosUpdateUrl,
                androidUpdateUrl:
                    state.remoteConfig?.appStatus.androidUpdateUrl,
                currentAppVersion: state.currentAppVersion,
                latestRequiredVersion: state.latestAppVersion,
              ),
            );
          }

          // --- Loading User Data State ---
          // Display a loading screen ONLY if the app is actively trying to
          // load user-specific data (e.g., after a login transition).
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
          // If none of the critical states above are met, the app is ready
          // to display its main UI. We build the MaterialApp.router here.
          // This is the single, STABLE root widget for the entire main app,
          // which prevents the `BuildContext` instability and `l10n`
          // crashes seen in the previous architecture.
          return MultiRepositoryProvider(
            // By placing these providers here, we ensure they are only
            // created when the app is in a stable, running state. This
            // guarantees that any dependencies they have on the AppBloc's
            // state (like remoteConfig) are available and non-null.
            providers: [
              // Provide the InterstitialAdManager.
              RepositoryProvider(
                create: (context) => InterstitialAdManager(
                  appBloc: context.read<AppBloc>(),
                  adService: context.read<AdService>(),
                  navigatorKey: widget.navigatorKey,
                ),
                lazy: false,
              ),
              // Provide the ContentLimitationService.
              RepositoryProvider(
                create: (context) =>
                    ContentLimitationService(appBloc: context.read<AppBloc>()),
              ),
            ],
            child: MaterialApp.router(
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
            ),
          );
        },
      ),
    );
  }
}
