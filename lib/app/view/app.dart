import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart' hide AppStatus;
import 'package:data_repository/data_repository.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/app_status_service.dart';
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
    required KVStorageService kvStorageService,
    required AppEnvironment environment,
    this.demoDataMigrationService,
    super.key,
  }) : _authenticationRepository = authenticationRepository,
       _headlinesRepository = headlinesRepository,
       _topicsRepository = topicsRepository,
       _countriesRepository = countriesRepository,
       _sourcesRepository = sourcesRepository,
       _userAppSettingsRepository = userAppSettingsRepository,
       _userContentPreferencesRepository = userContentPreferencesRepository,
       _appConfigRepository = remoteConfigRepository,
       _kvStorageService = kvStorageService,
       _environment = environment;

  final AuthRepository _authenticationRepository;
  final DataRepository<Headline> _headlinesRepository;
  final DataRepository<Topic> _topicsRepository;
  final DataRepository<Country> _countriesRepository;
  final DataRepository<Source> _sourcesRepository;
  final DataRepository<UserAppSettings> _userAppSettingsRepository;
  final DataRepository<UserContentPreferences>
  _userContentPreferencesRepository;
  final DataRepository<RemoteConfig> _appConfigRepository;
  final KVStorageService _kvStorageService;
  final AppEnvironment _environment;
  final DemoDataMigrationService? demoDataMigrationService;

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
        RepositoryProvider.value(value: _kvStorageService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AppBloc(
              authenticationRepository: context.read<AuthRepository>(),
              userAppSettingsRepository: context
                  .read<DataRepository<UserAppSettings>>(),
              appConfigRepository: context.read<DataRepository<RemoteConfig>>(),
              environment: _environment,
              demoDataMigrationService: demoDataMigrationService,
            ),
          ),
          BlocProvider(
            create: (context) => AuthenticationBloc(
              authenticationRepository: context.read<AuthRepository>(),
            ),
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
          environment: _environment,
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
    required this.environment,
  });

  final AuthRepository authenticationRepository;
  final DataRepository<Headline> headlinesRepository;
  final DataRepository<Topic> topicRepository;
  final DataRepository<Country> countriesRepository;
  final DataRepository<Source> sourcesRepository;
  final DataRepository<UserAppSettings> userAppSettingsRepository;
  final DataRepository<UserContentPreferences> userContentPreferencesRepository;
  final DataRepository<RemoteConfig> appConfigRepository;
  final AppEnvironment environment;

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final GoRouter _router;
  // Standard notifier that GoRouter listens to.
  late final ValueNotifier<AppStatus> _statusNotifier;
  // The service responsible for automated status checks.
  AppStatusService? _appStatusService;
  // Removed Dynamic Links subscription

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
      environment: widget.environment,
    );

    // Removed Dynamic Link Initialization
  }

  @override
  void dispose() {
    _statusNotifier.dispose();
    // Dispose the AppStatusService to cancel timers and remove observers.
    _appStatusService?.dispose();
    // Removed Dynamic Links subscription cancellation
    super.dispose();
  }

  // Removed _initDynamicLinks and _handleDynamicLink methods

  @override
  Widget build(BuildContext context) {
    // Wrap the part of the tree that needs to react to AppBloc state changes
    // (specifically for updating the ValueNotifier) with a BlocListener.
    // The BlocBuilder remains for theme changes.
    return BlocListener<AppBloc, AppState>(
      // Listen for status changes to update the GoRouter's ValueNotifier
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        _statusNotifier.value = state.status;
      },
      child: BlocBuilder<AppBloc, AppState>(
        // Rebuild the UI based on AppBloc's state (theme, locale, and critical app statuses)
        builder: (context, state) {
          // Defer l10n access until inside a MaterialApp context

          // Handle critical RemoteConfig loading states globally
          // These checks have the highest priority and will lock the entire UI.
          //
          // Check for Maintenance Mode.
          if (state.status == AppStatus.underMaintenance) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: MaintenancePage(),
            );
          }

          // Check for a Required Update.
          if (state.status == AppStatus.updateRequired) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: UpdateRequiredPage(),
            );
          }

          // Check for Config Fetching state.
          if (state.status == AppStatus.configFetching) {
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
                fontFamily: null, // System default font
              ),
              themeMode: state
                  .themeMode, // Still respect light/dark if available from system
              localizationsDelegates: const [
                ...AppLocalizations.localizationsDelegates,
                ...UiKitLocalizations.localizationsDelegates,
              ],
              supportedLocales: const [
                ...AppLocalizations.supportedLocales,
                ...UiKitLocalizations.supportedLocales,
              ],
              home: Scaffold(
                body: Builder(
                  // Use Builder to get context under MaterialApp
                  builder: (innerContext) {
                    return LoadingStateWidget(
                      icon: Icons.settings_applications_outlined,
                      headline: AppLocalizations.of(
                        innerContext,
                      ).headlinesFeedLoadingHeadline,
                      subheadline: AppLocalizations.of(innerContext).pleaseWait,
                    );
                  },
                ),
              ),
            );
          }

          if (state.status == AppStatus.configFetchFailed) {
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
              supportedLocales: const [
                ...AppLocalizations.supportedLocales,
                ...UiKitLocalizations.supportedLocales,
              ],
              home: Scaffold(
                body: Builder(
                  // Use Builder to get context under MaterialApp
                  builder: (innerContext) {
                    return FailureStateWidget(
                      exception: const NetworkException(),
                      retryButtonText: UiKitLocalizations.of(
                        innerContext,
                      )!.retryButtonText,
                      onRetry: () {
                        // Use outer context for BLoC access
                        context.read<AppBloc>().add(
                          const AppConfigFetchRequested(),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          }

          // If config is loaded (or not in a failed/fetching state for config), proceed with main app UI
          // It's safe to access l10n here if needed for print statements,
          // as this path implies we are about to build the main MaterialApp.router
          // which provides localizations.
          // final l10n = context.l10n;
          print('[_AppViewState] Building MaterialApp.router');
          print('[_AppViewState] state.fontFamily: ${state.fontFamily}');
          print(
            '[_AppViewState] state.settings.displaySettings.fontFamily: ${state.settings.displaySettings.fontFamily}',
          );
          print(
            '[_AppViewState] state.settings.displaySettings.fontWeight: ${state.settings.displaySettings.fontWeight}',
          );
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
