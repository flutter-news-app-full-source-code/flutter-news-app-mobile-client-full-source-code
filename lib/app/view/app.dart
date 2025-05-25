//
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_auth_repository/ht_auth_repository.dart'; // Auth Repository
import 'package:ht_data_repository/ht_data_repository.dart'; // Generic Data Repository
import 'package:ht_kv_storage_service/ht_kv_storage_service.dart'; // KV Storage Interface
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/authentication/bloc/authentication_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/router.dart';
import 'package:ht_main/shared/theme/app_theme.dart';
import 'package:ht_shared/ht_shared.dart'; // Shared models, FromJson, ToJson, etc.

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
    super.key,
  }) : _htAuthenticationRepository = htAuthenticationRepository,
       _htHeadlinesRepository = htHeadlinesRepository,
       _htCategoriesRepository = htCategoriesRepository,
       _htCountriesRepository = htCountriesRepository,
       _htSourcesRepository = htSourcesRepository,
       _htUserAppSettingsRepository = htUserAppSettingsRepository,
       _htUserContentPreferencesRepository = htUserContentPreferencesRepository,
       _htAppConfigRepository = htAppConfigRepository,
       _kvStorageService = kvStorageService;

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
      // Use MultiBlocProvider to provide global BLoCs
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            // AppBloc constructor needs refactoring in Step 4
            create:
                (context) => AppBloc(
                  authenticationRepository: context.read<HtAuthRepository>(),
                  // Pass generic data repositories for preferences
                  userAppSettingsRepository:
                      context.read<HtDataRepository<UserAppSettings>>(),
                ),
          ),
          BlocProvider(
            create:
                (context) => AuthenticationBloc(
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
    );

    // Removed Dynamic Link Initialization
  }

  @override
  void dispose() {
    _statusNotifier.dispose(); // Dispose the correct notifier
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
      // Only listen when the status actually changes
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        // Directly update the ValueNotifier when the AppBloc status changes.
        // This triggers the GoRouter's refreshListenable.
        _statusNotifier.value = state.status;
      },
      child: BlocBuilder<AppBloc, AppState>(
        // Build when theme-related properties change (including text scale factor)
        buildWhen:
            (previous, current) =>
                previous.themeMode != current.themeMode ||
                previous.flexScheme != current.flexScheme ||
                previous.fontFamily != current.fontFamily ||
                previous.appTextScaleFactor !=
                    current.appTextScaleFactor, // Use text scale factor
        builder: (context, state) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            // Pass scheme and font family from state to theme functions
            theme: lightTheme(
              scheme: state.flexScheme,
              appTextScaleFactor:
                  state.settings.displaySettings.textScaleFactor,
              fontFamily: state.settings.displaySettings.fontFamily,
            ),
            darkTheme: darkTheme(
              scheme: state.flexScheme,
              appTextScaleFactor:
                  state.settings.displaySettings.textScaleFactor,
              fontFamily: state.settings.displaySettings.fontFamily,
            ),
            routerConfig: _router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
