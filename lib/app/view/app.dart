import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart' hide AppStatus;
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_initializer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_status_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/services/feed_decorator_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/services/feed_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/services/push_notification_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/router.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/status/view/view.dart';
import 'package:go_router/go_router.dart';
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
    required DataRepository<InAppNotification>
    inAppNotificationRepository,
    required InlineAdCacheService inlineAdCacheService,
    required AdService adService,
    required FeedDecoratorService feedDecoratorService,
    required FeedCacheService feedCacheService,
    required GlobalKey<NavigatorState> navigatorKey,
    required PushNotificationService pushNotificationService,
    super.key,
  }) : _authenticationRepository = authenticationRepository,
       _headlinesRepository = headlinesRepository,
       _topicsRepository = topicsRepository,
       _countriesRepository = countriesRepository,
       _sourcesRepository = sourcesRepository,
       _userRepository = userRepository,
       _remoteConfigRepository = remoteConfigRepository,
       _userAppSettingsRepository = userAppSettingsRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _pushNotificationService = pushNotificationService,
       _inAppNotificationRepository = inAppNotificationRepository,
       _environment = environment,
       _adService = adService,
       _feedDecoratorService = feedDecoratorService,
       _feedCacheService = feedCacheService,
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
  final DataRepository<InAppNotification> _inAppNotificationRepository;
  final AdService _adService;
  final FeedDecoratorService _feedDecoratorService;
  final FeedCacheService _feedCacheService;
  final GlobalKey<NavigatorState> _navigatorKey;
  final InlineAdCacheService _inlineAdCacheService;

  final PushNotificationService _pushNotificationService;
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
        RepositoryProvider.value(value: _feedDecoratorService),
        RepositoryProvider.value(value: _userRepository),
        RepositoryProvider.value(value: _remoteConfigRepository),
        RepositoryProvider.value(value: _userAppSettingsRepository),
        RepositoryProvider.value(value: _userContentPreferencesRepository),
        RepositoryProvider.value(value: _pushNotificationService),
        RepositoryProvider.value(value: _inAppNotificationRepository),
        RepositoryProvider.value(value: _inlineAdCacheService),
        RepositoryProvider.value(value: _feedCacheService),
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
              logger: context.read<Logger>(),
              pushNotificationService: _pushNotificationService,
              inAppNotificationRepository: _inAppNotificationRepository,
              userRepository: _userRepository,
              inlineAdCacheService: _inlineAdCacheService,
            )..add(const AppStarted()),
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
  StreamSubscription<PushNotificationPayload>? _onMessageOpenedAppSubscription;
  StreamSubscription<PushNotificationPayload>? _onMessageSubscription;
  AppStatusService? _appStatusService;
  InterstitialAdManager? _interstitialAdManager;
  late final ContentLimitationService _contentLimitationService;
  late final GoRouter _router;
  final _routerLogger = Logger('GoRouter');

  @override
  void initState() {
    super.initState();
    final appBloc = context.read<AppBloc>();
    final pushNotificationService = context.read<PushNotificationService>();

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

    // Subscribe to foreground push notifications. When a message is received,
    // dispatch an event to the AppBloc to update the UI state (e.g., show an
    // indicator dot).
    _onMessageSubscription = pushNotificationService.onMessage.listen(
      (_) => context.read<AppBloc>().add(const AppInAppNotificationReceived()),
    );

    // Subscribe to notifications that are tapped and open the app.
    // This is the core of the deep-linking functionality.
    _onMessageOpenedAppSubscription = pushNotificationService.onMessageOpenedApp
        .listen((payload) {
          _routerLogger.fine(
            'Notification opened app with payload: ${payload.data}',
          );
          final contentType =
              payload.data['contentType'] as String?; // e.g., 'headline'
          final id = payload.data['headlineId'] as String?;

          if (contentType == 'headline' && id != null) {
            // Use pushNamed instead of goNamed.
            // goNamed replaces the entire navigation stack, which causes issues
            // when the app is launched from a terminated state. The new page
            // would lack the necessary ancestor widgets (like RepositoryProviders).
            // pushNamed correctly pushes the details page on top of the
            // existing stack (e.g., the feed), ensuring a valid context.
            _router.pushNamed(
              Routes.globalArticleDetailsName,
              pathParameters: {'id': id},
            );
          }
        });
    // Instantiate and initialize the AppStatusService.
    // This service monitors the app's lifecycle (e.g., resuming from
    // background) and periodically triggers remote configuration fetches,
    // ensuring the app status is always fresh.
    _appStatusService = AppStatusService(
      context: context,
      checkInterval: const Duration(minutes: 15),
      environment: widget.environment,
    );

    // Create instances of services that need to be managed by this State's
    // lifecycle. This prevents them from being re-created on every build.
    _interstitialAdManager = InterstitialAdManager(
      appBloc: appBloc,
      adService: context.read<AdService>(),
      navigatorKey: widget.navigatorKey,
    );
    _contentLimitationService = ContentLimitationService(
      appBloc: context.read<AppBloc>(),
    );

    // Create the GoRouter instance once and store it.
    _router = createRouter(
      authStatusNotifier: _statusNotifier,
      navigatorKey: widget.navigatorKey,
      logger: _routerLogger,
    );
  }

  @override
  void dispose() {
    _statusNotifier.dispose();
    _userSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _onMessageSubscription?.cancel();
    _appStatusService?.dispose();
    _interstitialAdManager?.dispose();
    context.read<PushNotificationService>().close();
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
          // crashes seen in the previous architecture. This MultiRepositoryProvider
          // uses the `.value` constructor to provide the service instances that
          // were created and are managed by this State object.
          return MultiRepositoryProvider(
            providers: [
              if (_interstitialAdManager != null)
                RepositoryProvider<InterstitialAdManager>.value(
                  value: _interstitialAdManager!,
                ),
              RepositoryProvider<ContentLimitationService>.value(
                value: _contentLimitationService,
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
            ),
          );
        },
      ),
    );
  }
}
