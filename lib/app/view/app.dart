//
// ignore_for_file: deprecated_member_use

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_auth_repository/ht_auth_repository.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_kv_storage_service/ht_kv_storage_service.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/app/config/app_environment.dart';
import 'package:ht_main/authentication/bloc/authentication_bloc.dart';
import 'package:ht_main/l10n/app_localizations.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/router.dart';
import 'package:ht_main/shared/services/demo_data_migration_service.dart';
import 'package:ht_main/shared/theme/app_theme.dart';
import 'package:ht_main/shared/widgets/failure_state_widget.dart';
import 'package:ht_main/shared/widgets/loading_state_widget.dart';
import 'package:ht_shared/ht_shared.dart';

class App extends StatelessWidget {
  const App({
    required HtAuthRepository htAuthenticationRepository,
    required HtDataRepository<Headline> htHeadlinesRepository,
    required HtDataRepository<Category> htCategoriesRepository,
    required HtDataRepository<Country> htCountriesRepository,
    required HtDataRepository<Source> htSourcesRepository,
    required HtDataRepository<UserAppSettings> htUserAppSettingsRepository,
    required HtDataRepository<UserContentPreferences>
    htUserContentPreferencesRepository,
    required HtDataRepository<AppConfig> htAppConfigRepository,
    required HtKVStorageService kvStorageService,
    required AppEnvironment environment,
    this.demoDataMigrationService,
    super.key,
  }) : _htAuthenticationRepository = htAuthenticationRepository,
       _htHeadlinesRepository = htHeadlinesRepository,
       _htCategoriesRepository = htCategoriesRepository,
       _htCountriesRepository = htCountriesRepository,
       _htSourcesRepository = htSourcesRepository,
       _htUserAppSettingsRepository = htUserAppSettingsRepository,
       _htUserContentPreferencesRepository = htUserContentPreferencesRepository,
       _htAppConfigRepository = htAppConfigRepository,
       _kvStorageService = kvStorageService,
       _environment = environment;

  final HtAuthRepository _htAuthenticationRepository;
  final HtDataRepository<Headline> _htHeadlinesRepository;
  final HtDataRepository<Category> _htCategoriesRepository;
  final HtDataRepository<Country> _htCountriesRepository;
  final HtDataRepository<Source> _htSourcesRepository;
  final HtDataRepository<UserAppSettings> _htUserAppSettingsRepository;
  final HtDataRepository<UserContentPreferences>
  _htUserContentPreferencesRepository;
  final HtDataRepository<AppConfig> _htAppConfigRepository;
  final HtKVStorageService _kvStorageService;
  final AppEnvironment _environment;
  final DemoDataMigrationService? demoDataMigrationService;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _htAuthenticationRepository),
        RepositoryProvider.value(value: _htHeadlinesRepository),
        RepositoryProvider.value(value: _htCategoriesRepository),
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
              authenticationRepository: context.read<HtAuthRepository>(),
              userAppSettingsRepository: context
                  .read<HtDataRepository<UserAppSettings>>(),
              appConfigRepository: context.read<HtDataRepository<AppConfig>>(),
              environment: _environment,
              demoDataMigrationService: demoDataMigrationService,
            ),
          ),
          BlocProvider(
            create: (context) => AuthenticationBloc(
              authenticationRepository: context.read<HtAuthRepository>(),
            ),
          ),
        ],
        child: _AppView(
          htAuthenticationRepository: _htAuthenticationRepository,
          htHeadlinesRepository: _htHeadlinesRepository,
          htCategoriesRepository: _htCategoriesRepository,
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
    required this.htAuthenticationRepository,
    required this.htHeadlinesRepository,
    required this.htCategoriesRepository,
    required this.htCountriesRepository,
    required this.htSourcesRepository,
    required this.htUserAppSettingsRepository,
    required this.htUserContentPreferencesRepository,
    required this.htAppConfigRepository,
    required this.environment,
  });

  final HtAuthRepository htAuthenticationRepository;
  final HtDataRepository<Headline> htHeadlinesRepository;
  final HtDataRepository<Category> htCategoriesRepository;
  final HtDataRepository<Country> htCountriesRepository;
  final HtDataRepository<Source> htSourcesRepository;
  final HtDataRepository<UserAppSettings> htUserAppSettingsRepository;
  final HtDataRepository<UserContentPreferences>
  htUserContentPreferencesRepository;
  final HtDataRepository<AppConfig> htAppConfigRepository;
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
      htAuthenticationRepository: widget.htAuthenticationRepository,
      htHeadlinesRepository: widget.htHeadlinesRepository,
      htCategoriesRepository: widget.htCategoriesRepository,
      htCountriesRepository: widget.htCountriesRepository,
      htSourcesRepository: widget.htSourcesRepository,
      htUserAppSettingsRepository: widget.htUserAppSettingsRepository,
      htUserContentPreferencesRepository:
          widget.htUserContentPreferencesRepository,
      htAppConfigRepository: widget.htAppConfigRepository,
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

          // Handle critical AppConfig loading states globally
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
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Builder(
                  // Use Builder to get context under MaterialApp
                  builder: (innerContext) {
                    final l10n = innerContext.l10n;
                    return LoadingStateWidget(
                      icon: Icons.settings_applications_outlined,
                      headline: l10n.headlinesFeedLoadingHeadline,
                      subheadline: l10n.pleaseWait,
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
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Builder(
                  // Use Builder to get context under MaterialApp
                  builder: (innerContext) {
                    final l10n = innerContext.l10n;
                    return FailureStateWidget(
                      message: l10n.unknownError,
                      retryButtonText: 'Retry',
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
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
