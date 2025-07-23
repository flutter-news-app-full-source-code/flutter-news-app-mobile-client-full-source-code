import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart' hide AppStatus;
import 'package:data_repository/data_repository.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/app_environment.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/services/demo_data_migration_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/router.dart';
import 'package:go_router/go_router.dart';
import 'package:kv_storage_service/kv_storage_service.dart';
import 'package:ui_kit/ui_kit.dart';

class App extends StatelessWidget {
  const App({
    required AuthRepository authenticationRepository,
    required DataRepository<Headline> htHeadlinesRepository,
    required DataRepository<Topic> htTopicsRepository,
    required DataRepository<Country> htCountriesRepository,
    required DataRepository<Source> htSourcesRepository,
    required DataRepository<UserAppSettings> htUserAppSettingsRepository,
    required DataRepository<UserContentPreferences>
    htUserContentPreferencesRepository,
    required DataRepository<RemoteConfig> htRemoteConfigRepository,
    required KVStorageService kvStorageService,
    required AppEnvironment environment,
    this.demoDataMigrationService,
    super.key,
  }) : _authenticationRepository = authenticationRepository,
       _htHeadlinesRepository = htHeadlinesRepository,
       _htTopicsRepository = htTopicsRepository,
       _htCountriesRepository = htCountriesRepository,
       _htSourcesRepository = htSourcesRepository,
       _htUserAppSettingsRepository = htUserAppSettingsRepository,
       _htUserContentPreferencesRepository = htUserContentPreferencesRepository,
       _htAppConfigRepository = htRemoteConfigRepository,
       _kvStorageService = kvStorageService,
       _environment = environment;

  final AuthRepository _authenticationRepository;
  final DataRepository<Headline> _htHeadlinesRepository;
  final DataRepository<Topic> _htTopicsRepository;
  final DataRepository<Country> _htCountriesRepository;
  final DataRepository<Source> _htSourcesRepository;
  final DataRepository<UserAppSettings> _htUserAppSettingsRepository;
  final DataRepository<UserContentPreferences>
  _htUserContentPreferencesRepository;
  final DataRepository<RemoteConfig> _htAppConfigRepository;
  final KVStorageService _kvStorageService;
  final AppEnvironment _environment;
  final DemoDataMigrationService? demoDataMigrationService;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authenticationRepository),
        RepositoryProvider.value(value: _htHeadlinesRepository),
        RepositoryProvider.value(value: _htTopicsRepository),
        RepositoryProvider.value(value: _htCountriesRepository),
        RepositoryProvider.value(value: _htSourcesRepository),
        RepositoryProvider.value(value: _htUserAppSettingsRepository),
        RepositoryProvider.value(value: _htUserContentPreferencesRepository),
        RepositoryProvider.value(value: _htAppConfigRepository),
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
          htHeadlinesRepository: _htHeadlinesRepository,
          htTopicRepository: _htTopicsRepository,
          htCountriesRepository: _htCountriesRepository,
          htSourcesRepository: _htSourcesRepository,
          htUserAppSettingsRepository: _htUserAppSettingsRepository,
          htUserContentPreferencesRepository:
              _htUserContentPreferencesRepository,
          htAppConfigRepository: _htAppConfigRepository,
          environment: _environment,
        ),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView({
    required this.authenticationRepository,
    required this.htHeadlinesRepository,
    required this.htTopicRepository,
    required this.htCountriesRepository,
    required this.htSourcesRepository,
    required this.htUserAppSettingsRepository,
    required this.htUserContentPreferencesRepository,
    required this.htAppConfigRepository,
    required this.environment,
  });

  final AuthRepository authenticationRepository;
  final DataRepository<Headline> htHeadlinesRepository;
  final DataRepository<Topic> htTopicRepository;
  final DataRepository<Country> htCountriesRepository;
  final DataRepository<Source> htSourcesRepository;
  final DataRepository<UserAppSettings> htUserAppSettingsRepository;
  final DataRepository<UserContentPreferences>
  htUserContentPreferencesRepository;
  final DataRepository<RemoteConfig> htAppConfigRepository;
  final AppEnvironment environment;

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final GoRouter _router;
  // Standard notifier that GoRouter listens to.
  late final ValueNotifier<AppStatus> _statusNotifier;
  // Removed Dynamic Links subscription

  @override
  void initState() {
    super.initState();
    final appBloc = context.read<AppBloc>();
    // Initialize the notifier with the BLoC's current state
    _statusNotifier = ValueNotifier<AppStatus>(appBloc.state.status);
    _router = createRouter(
      authStatusNotifier: _statusNotifier,
      authenticationRepository: widget.authenticationRepository,
      htHeadlinesRepository: widget.htHeadlinesRepository,
      htTopicsRepository: widget.htTopicRepository,
      htCountriesRepository: widget.htCountriesRepository,
      htSourcesRepository: widget.htSourcesRepository,
      htUserAppSettingsRepository: widget.htUserAppSettingsRepository,
      htUserContentPreferencesRepository:
          widget.htUserContentPreferencesRepository,
      htRemoteConfigRepository: widget.htAppConfigRepository,
      environment: widget.environment,
    );

    // Removed Dynamic Link Initialization
  }

  @override
  void dispose() {
    _statusNotifier.dispose();
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
