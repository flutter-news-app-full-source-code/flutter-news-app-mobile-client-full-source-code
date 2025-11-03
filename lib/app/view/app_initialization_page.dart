import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_initialization_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_initializer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/view/app.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/view/app_hot_restart_wrapper.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/services/feed_decorator_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/services/feed_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/status/view/view.dart';
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template app_initialization_page}
/// A top-level widget that orchestrates the application's initialization
/// process.
///
/// This page is the first UI shown to the user. It hosts the
/// [AppInitializationBloc] and is responsible for displaying the correct UI
/// based on the initialization state:
///
/// - [AppInitializationInProgress]: Shows a loading indicator.
/// - [AppInitializationFailed]: Shows a relevant error page (e.g.,
///   maintenance, update required, or critical error).
/// - [AppInitializationSucceeded]: Transitions to the main [App] widget with all
///   the necessary data.
///
/// This approach creates a robust "master switch" for the app, completely
/// decoupling the complex and potentially fallible startup logic from the main
/// application UI.
/// {@endtemplate}
class AppInitializationPage extends StatelessWidget {
  /// {@macro app_initialization_page}
  const AppInitializationPage({
    required this.authenticationRepository,
    required this.headlinesRepository,
    required this.topicsRepository,
    required this.userRepository,
    required this.countriesRepository,
    required this.sourcesRepository,
    required this.remoteConfigRepository,
    required this.userAppSettingsRepository,
    required this.userContentPreferencesRepository,
    required this.environment,
    required this.adService,
    required this.feedDecoratorService,
    required this.feedCacheService,
    required this.inlineAdCacheService,
    required this.navigatorKey,
    super.key,
  });

  final AuthRepository authenticationRepository;
  final DataRepository<Headline> headlinesRepository;
  final DataRepository<Topic> topicsRepository;
  final DataRepository<Country> countriesRepository;
  final DataRepository<Source> sourcesRepository;
  final DataRepository<User> userRepository;
  final DataRepository<RemoteConfig> remoteConfigRepository;
  final DataRepository<UserAppSettings> userAppSettingsRepository;
  final DataRepository<UserContentPreferences> userContentPreferencesRepository;
  final AppEnvironment environment;
  final AdService adService;
  final FeedDecoratorService feedDecoratorService;
  final FeedCacheService feedCacheService;
  final GlobalKey<NavigatorState> navigatorKey;
  final InlineAdCacheService inlineAdCacheService;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppInitializationBloc(
        appInitializer: context.read<AppInitializer>(),
        logger: context.read<Logger>(),
      )..add(const AppInitializationStarted()),
      child: BlocConsumer<AppInitializationBloc, AppInitializationState>(
        listener: (context, state) {
          // Listener can be used for side-effects if needed in the future,
          // such as logging state transitions.
        },
        builder: (context, state) {
          switch (state) {
            case final AppInitializationSucceeded successState:
              // On success, build the main App widget with the guaranteed
              // successful initialization data.
              final successData = successState.initializationSuccess;
              return App(
                user: successData.user,
                remoteConfig: successData.remoteConfig,
                settings: successData.settings,
                userContentPreferences: successData.userContentPreferences,
                authenticationRepository: authenticationRepository,
                headlinesRepository: headlinesRepository,
                topicsRepository: topicsRepository,
                userRepository: userRepository,
                countriesRepository: countriesRepository,
                sourcesRepository: sourcesRepository,
                remoteConfigRepository: remoteConfigRepository,
                userAppSettingsRepository: userAppSettingsRepository,
                userContentPreferencesRepository:
                    userContentPreferencesRepository,
                environment: environment,
                adService: adService,
                feedDecoratorService: feedDecoratorService,
                feedCacheService: feedCacheService,
                inlineAdCacheService: inlineAdCacheService,
                navigatorKey: navigatorKey,
              );

            case final AppInitializationFailed failureState:
              // On failure, determine which full-screen error page to show.
              final failureData = failureState.initializationFailure;
              // Each status page is wrapped in its own simple MaterialApp to
              // create a self-contained environment with the necessary theme
              // and localization context to render correctly.
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: lightTheme(
                  scheme: FlexScheme.blue,
                  appTextScaleFactor: AppTextScaleFactor.medium,
                  appFontWeight: AppFontWeight.regular,
                ),
                darkTheme: darkTheme(
                  scheme: FlexScheme.blue,
                  appTextScaleFactor: AppTextScaleFactor.medium,
                  appFontWeight: AppFontWeight.regular,
                ),
                themeMode: ThemeMode.system,
                localizationsDelegates: const [
                  ...AppLocalizations.localizationsDelegates,
                  ...UiKitLocalizations.localizationsDelegates,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: switch (failureData.status) {
                  AppLifeCycleStatus.underMaintenance =>
                    const MaintenancePage(),
                  AppLifeCycleStatus.updateRequired => UpdateRequiredPage(
                    currentAppVersion: failureData.currentAppVersion,
                    latestRequiredVersion: failureData.latestAppVersion,
                  ),
                  AppLifeCycleStatus.criticalError => CriticalErrorPage(
                    exception: failureData.error,
                    onRetry: () {
                      // For a critical error, we trigger a full app restart
                      // to ensure a clean state.
                      AppHotRestartWrapper.restartApp(context);
                    },
                  ),
                  // The other AppLifeCycleStatus values are not possible failure
                  // states from the initializer, so we default to a critical
                  // error page as a safe fallback.
                  // ignore: no_default_cases
                  _ => CriticalErrorPage(
                    exception: failureData.error,
                    onRetry: () => AppHotRestartWrapper.restartApp(context),
                  ),
                },
              );

            case AppInitializationInProgress():
              // While initializing, show a simple loading indicator.
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: lightTheme(
                  scheme: FlexScheme.blue,
                  appTextScaleFactor: AppTextScaleFactor.medium,
                  appFontWeight: AppFontWeight.regular,
                ),
                darkTheme: darkTheme(
                  scheme: FlexScheme.blue,
                  appTextScaleFactor: AppTextScaleFactor.medium,
                  appFontWeight: AppFontWeight.regular,
                ),
                themeMode: ThemeMode.system,
                localizationsDelegates: const [
                  ...AppLocalizations.localizationsDelegates,
                  ...UiKitLocalizations.localizationsDelegates,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
          }
        },
      ),
    );
  }
}
