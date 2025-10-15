import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart' hide AppStatus;
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/account_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/manage_followed_items/countries/add_country_to_follow_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/manage_followed_items/countries/followed_countries_list_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/manage_followed_items/manage_followed_items_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/manage_followed_items/sources/add_source_to_follow_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/manage_followed_items/sources/followed_sources_list_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/manage_followed_items/topics/add_topic_to_follow_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/manage_followed_items/topics/followed_topics_list_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/saved_headlines_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/view/app_shell.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/view/account_linking_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/view/authentication_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/view/email_code_verification_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/view/request_code_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/entity_details/bloc/entity_details_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/entity_details/view/entity_details_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headline-details/bloc/headline_details_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headline-details/bloc/similar_headlines_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headline-details/view/headline_details_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/country_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/headlines_feed_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/headlines_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/manage_saved_filters_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/source_list_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/source_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/topic_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-search/bloc/headlines_search_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-search/view/headlines_search_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/go_router_observer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/bloc/settings_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/view/appearance_settings_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/view/feed_settings_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/view/font_settings_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/view/language_settings_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/view/notification_settings_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/view/settings_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/view/theme_settings_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/feed_decorator_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/multi_select_search_page.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

/// Creates and configures the GoRouter instance for the application.
///
/// Requires an [authStatusNotifier] to trigger route re-evaluation when
/// authentication state changes.
///
///
/// With the current App startup architecture, the router is only active
/// when the app is in a stable, running state. The `redirect` function's
/// only responsibility is to handle auth-based route protection.
/// States like `configFetching`, `underMaintenance`, etc., are handled
/// by the root App widget *before* this router is ever built.

GoRouter createRouter({
  required ValueNotifier<AppLifeCycleStatus> authStatusNotifier,
  required AuthRepository authenticationRepository,
  required DataRepository<Headline> headlinesRepository,
  required DataRepository<Topic> topicsRepository,
  required DataRepository<Source> sourcesRepository,
  required DataRepository<Country> countriesRepository,
  required DataRepository<UserAppSettings> userAppSettingsRepository,
  required DataRepository<UserContentPreferences>
  userContentPreferencesRepository,
  required DataRepository<RemoteConfig> remoteConfigRepository,
  required DataRepository<User> userRepository,
  required AdService adService,
  required GlobalKey<NavigatorState> navigatorKey,
  required InlineAdCacheService inlineAdCacheService,
  required Logger logger,
}) {
  // Instantiate FeedDecoratorService once to be shared
  final feedDecoratorService = FeedDecoratorService(
    topicsRepository: topicsRepository,
    sourcesRepository: sourcesRepository,
  );

  return GoRouter(
    refreshListenable: authStatusNotifier,
    // Start at a neutral root path. The redirect logic will immediately
    // determine the correct path (/feed or /authentication), preventing
    // an attempt to build a complex page before the app state is ready.
    initialLocation: '/',
    debugLogDiagnostics: true,
    navigatorKey: navigatorKey,
    observers: [GoRouterObserver(logger: logger)],
    // --- Redirect Logic ---
    // This function is the single source of truth for route protection.
    // It's driven by the AppBloc's AppLifeCycleStatus.
    redirect: (BuildContext context, GoRouterState state) {
      final appStatus = context.read<AppBloc>().state.status;
      final currentLocation = state.matchedLocation;

      logger.info(
        'GoRouter Redirect Check:\n'
        '  Current Location (Matched): $currentLocation\n'
        '  AppStatus: $appStatus',
      );

      const rootPath = '/';
      const authenticationPath = Routes.authentication;
      const accountLinkingPath = Routes.accountLinking;
      const feedPath = Routes.feed;
      final isGoingToAuth = currentLocation.startsWith(authenticationPath);
      final isGoingToLinking = currentLocation.startsWith(accountLinkingPath);

      // --- Case 1: Unauthenticated User ---
      // If the user is unauthenticated, they must be on an auth path.
      // If they try to go anywhere else, they are redirected to the sign-in page.
      if (appStatus == AppLifeCycleStatus.unauthenticated) {
        logger.info('  Redirect: User is unauthenticated.');
        return isGoingToAuth ? null : authenticationPath;
      }

      // --- Case 2: Anonymous User ---
      // An anonymous user is partially authenticated. They can browse the app.
      if (appStatus == AppLifeCycleStatus.anonymous) {
        logger.info('  Redirect: User is anonymous.');
        // Block anonymous users from the main sign-in page.
        if (isGoingToAuth) {
          logger.info(
            '    Action: Anonymous user on auth path. Redirecting to feed.',
          );
          return feedPath;
        }
        // If at the root, send them to the feed.
        if (currentLocation == rootPath) {
          logger.info('    Action: User at root. Redirecting to feed.');
          return feedPath;
        }
        // Allow navigation to other pages, including the new linking page.
        return null;
      }

      // --- Case 3: Authenticated User ---
      // A fully authenticated user should be blocked from all auth/linking pages.
      if (appStatus == AppLifeCycleStatus.authenticated) {
        logger.info('  Redirect: User is authenticated.');
        if (isGoingToAuth || isGoingToLinking) {
          logger.info(
            '    Action: Authenticated user on auth/linking path. Redirecting to feed.',
          );
          return feedPath;
        }
        // If at the root, send them to the feed.
        if (currentLocation == rootPath) {
          logger.info('    Action: User at root. Redirecting to feed.');
          return feedPath;
        }
      }

      // --- Fallback ---
      // For any other case (or if no conditions are met), allow navigation.
      logger.info('  Redirect: No condition met. Allowing navigation.');
      return null;
    },
    // --- Authentication Routes ---
    routes: [
      // A neutral root route that the app starts on. The redirect logic will
      // immediately move the user to the correct location.
      GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),
      GoRoute(
        path: Routes.authentication,
        name: Routes.authenticationName,
        builder: (BuildContext context, GoRouterState state) {
          return BlocProvider(
            create: (context) => AuthenticationBloc(
              authenticationRepository: context.read<AuthRepository>(),
            ),
            child: const AuthenticationPage(),
          );
        },
        routes: [
          // Sub-routes for the standard sign-in flow.
          GoRoute(
            path: Routes.requestCode,
            name: Routes.requestCodeName,
            builder: (context, state) => const RequestCodePage(),
          ),
          GoRoute(
            path: '${Routes.verifyCode}/:email',
            name: Routes.verifyCodeName,
            builder: (context, state) {
              final email = state.pathParameters['email']!;
              return EmailCodeVerificationPage(email: email);
            },
          ),
        ],
      ),
      // --- New Top-Level Modal Route for Account Linking ---
      GoRoute(
        path: Routes.accountLinking,
        name: Routes.accountLinkingName,
        builder: (context, state) {
          return BlocProvider(
            create: (context) => AuthenticationBloc(
              authenticationRepository: context.read<AuthRepository>(),
            ),
            child: const AccountLinkingPage(),
          );
        },
        routes: [
          // Nested routes for the account linking email/code flow.
          GoRoute(
            path: Routes.requestCode,
            name: Routes.accountLinkingRequestCodeName,
            builder: (context, state) => const RequestCodePage(),
          ),
          GoRoute(
            path: '${Routes.verifyCode}/:email',
            name: Routes.accountLinkingVerifyCodeName,
            builder: (context, state) {
              final email = state.pathParameters['email']!;
              return EmailCodeVerificationPage(email: email);
            },
          ),
        ],
      ),

      // --- Entity Details Route (Top Level) ---
      //
      // This route handles displaying details for various content entities
      // (Topic, Source, Country) based on path parameters.
      GoRoute(
        path: Routes.entityDetails,
        name: Routes.entityDetailsName,
        builder: (context, state) {
          final entityTypeString = state.pathParameters['type'];
          final entityId = state.pathParameters['id'];

          if (entityTypeString == null || entityId == null) {
            return const Scaffold(
              body: Center(child: Text('entity Details Missing Arguments')),
            );
          }

          final contentType = ContentType.values.firstWhere(
            (e) => e.name == entityTypeString,
            orElse: () =>
                throw FormatException('Unknown ContentType: $entityTypeString'),
          );

          final args = EntityDetailsPageArguments(
            entityId: entityId,
            contentType: contentType,
          );

          final adThemeStyle = AdThemeStyle.fromTheme(Theme.of(context));
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) =>
                    EntityDetailsBloc(
                      headlinesRepository: context
                          .read<DataRepository<Headline>>(),
                      topicRepository: context.read<DataRepository<Topic>>(),
                      sourceRepository: context.read<DataRepository<Source>>(),
                      countryRepository: context
                          .read<DataRepository<Country>>(),
                      appBloc: context.read<AppBloc>(),
                      feedDecoratorService: feedDecoratorService,
                      inlineAdCacheService: inlineAdCacheService,
                    )..add(
                      EntityDetailsLoadRequested(
                        entityId: args.entityId,
                        contentType: args.contentType,
                        adThemeStyle: adThemeStyle,
                      ),
                    ),
              ),
            ],
            child: EntityDetailsPage(args: args),
          );
        },
      ),

      // --- Global Article Details Route (Top Level) ---
      //
      // This GoRoute provides a top-level, globally accessible way to view the
      // HeadlineDetailsPage.
      //
      // Purpose:
      // It is specifically designed for navigating to article details from contexts
      // that are *outside* the main StatefulShellRoute's branches (e.g., from
      // EntityDetailsPage, which is itself a top-level route, or potentially
      // from other future top-level pages or deep links).
      //
      // Why it's necessary:
      // Attempting to push a route that is deeply nested within a specific shell
      // branch (like '/feed/article/:id') from a BuildContext outside of that
      // shell can lead to navigator context issues and assertion failures.
      // This global route avoids such problems by providing a clean, direct path
      // to the HeadlineDetailsPage.
      //
      // How it differs:
      // This route is distinct from the article detail routes nested within the
      // StatefulShellRoute branches (e.g., Routes.articleDetailsName under /feed,
      // Routes.searchArticleDetailsName under /search). Those nested routes are
      // intended for navigation *within* their respective shell branches,
      // preserving the shell's UI (like the bottom navigation bar).
      // This global route, being top-level, will typically cover the entire screen.
      GoRoute(
        path: Routes.globalArticleDetails,
        name: Routes.globalArticleDetailsName,
        builder: (context, state) {
          final headlineFromExtra = state.extra as Headline?;
          final headlineIdFromPath = state.pathParameters['id'];

          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => HeadlineDetailsBloc(
                  headlinesRepository: context.read<DataRepository<Headline>>(),
                ),
              ),
              BlocProvider(
                create: (context) => SimilarHeadlinesBloc(
                  headlinesRepository: context.read<DataRepository<Headline>>(),
                ),
              ),
            ],
            child: HeadlineDetailsPage(
              initialHeadline: headlineFromExtra,
              headlineId: headlineFromExtra?.id ?? headlineIdFromPath,
            ),
          );
        },
      ),
      // --- Reusable Multi-Select Search Page Route (Top Level) ---
      // This route provides a generic UI for selecting multiple items from a
      // searchable list. It is used by other pages (like the source filter)
      // to offload the complexity of list selection.
      GoRoute(
        path: '/multi-select-search',
        name: Routes.multiSelectSearchName,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final title = extra['title'] as String? ?? 'Select';
          final allItems = extra['allItems'] as List<dynamic>? ?? [];
          final initialSelectedItems =
              extra['initialSelectedItems'] as Set<dynamic>? ?? {};
          // The itemBuilder is passed as a function to display the item name.
          final itemBuilder = extra['itemBuilder'] as String Function(
            dynamic item,
          )? ??
              (item) => item.toString();

          // Since this is a generic page, we pass the dynamic types directly.
          // The calling page is responsible for casting the result.
          return MultiSelectSearchPage<dynamic>(
            title: title,
            allItems: allItems,
            initialSelectedItems: initialSelectedItems,
            itemBuilder: itemBuilder,
          );
        },
      ),
      // --- Main App Shell ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Return the shell widget which contains the AdaptiveScaffold
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) {
                  // Read the AppBloc once to get the initial state.
                  final appBloc = context.read<AppBloc>();

                  return HeadlinesFeedBloc(
                    headlinesRepository: context
                        .read<DataRepository<Headline>>(),
                    feedDecoratorService: feedDecoratorService,
                    appBloc: appBloc,
                    inlineAdCacheService: inlineAdCacheService,
                    // Prime the HeadlinesFeedBloc with the initial user
                    // preferences. This prevents a race condition where the
                    // feed is displayed before the bloc receives the saved
                    // filters from the AppBloc stream.
                    initialUserContentPreferences:
                        appBloc.state.userContentPreferences,
                  );
                },
              ),
              BlocProvider(
                create: (context) {
                  return HeadlinesSearchBloc(
                    headlinesRepository: context
                        .read<DataRepository<Headline>>(),
                    topicRepository: context.read<DataRepository<Topic>>(),
                    sourceRepository: context.read<DataRepository<Source>>(),
                    countryRepository: context.read<DataRepository<Country>>(),
                    appBloc: context.read<AppBloc>(),
                    feedDecoratorService: feedDecoratorService,
                    inlineAdCacheService: inlineAdCacheService,
                  );
                },
              ),
            ],
            child: AppShell(navigationShell: navigationShell),
          );
        },
        branches: [
          // --- Branch 1: Feed ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.feed,
                name: Routes.feedName,
                builder: (context, state) => const HeadlinesFeedPage(),
                routes: [
                  // Sub-route for article details
                  GoRoute(
                    path: 'article/:id',
                    name: Routes.articleDetailsName,
                    builder: (context, state) {
                      final headlineFromExtra = state.extra as Headline?;
                      final headlineIdFromPath = state.pathParameters['id'];

                      return MultiBlocProvider(
                        providers: [
                          BlocProvider(
                            create: (context) => HeadlineDetailsBloc(
                              headlinesRepository: context
                                  .read<DataRepository<Headline>>(),
                            ),
                          ),
                          BlocProvider(
                            create: (context) => SimilarHeadlinesBloc(
                              headlinesRepository: context
                                  .read<DataRepository<Headline>>(),
                            ),
                          ),
                        ],
                        child: HeadlineDetailsPage(
                          initialHeadline: headlineFromExtra,
                          // Ensure headlineId is non-null if initialHeadline is null
                          headlineId:
                              headlineFromExtra?.id ?? headlineIdFromPath,
                        ),
                      );
                    },
                  ),
                  // Sub-route for notifications (placeholder)
                  GoRoute(
                    path: Routes.notifications,
                    name: Routes.notificationsName,
                    builder: (context, state) {
                      // TODO(fulleni): Replace with actual NotificationsPage
                      return const Placeholder(
                        child: Center(child: Text('NOTIFICATIONS PAGE')),
                      );
                    },
                  ),

                  // --- Filter Routes (Nested under Feed) ---
                  GoRoute(
                    path: Routes.feedFilter,
                    name: Routes.feedFilterName,
                    // Use MaterialPage with fullscreenDialog for modal presentation
                    pageBuilder: (context, state) {
                      // Access the HeadlinesFeedBloc from the context
                      BlocProvider.of<HeadlinesFeedBloc>(context);
                      return const MaterialPage(
                        fullscreenDialog: true,
                        child: HeadlinesFilterPage(),
                      );
                    },
                    routes: [
                      // Sub-route for managing saved filters
                      GoRoute(
                        path: Routes.manageSavedFilters,
                        name: Routes.manageSavedFiltersName,
                        builder: (context, state) =>
                            const ManageSavedFiltersPage(),
                      ),
                      // Sub-route for topic selection
                      GoRoute(
                        path: Routes.feedFilterTopics,
                        name: Routes.feedFilterTopicsName,
                        builder: (context, state) {
                          final filterBloc =
                              state.extra! as HeadlinesFilterBloc;
                          return TopicFilterPage(filterBloc: filterBloc);
                        },
                      ),
                      // Sub-route for source selection
                      GoRoute(
                        path: Routes.feedFilterSources,
                        name: Routes.feedFilterSourcesName,
                        builder: (context, state) {
                          final filterBloc =
                              state.extra! as HeadlinesFilterBloc;
                          return SourceFilterPage(filterBloc: filterBloc);
                        },
                        routes: [
                          GoRoute(
                            path: 'source-list-filter',
                            name: Routes.sourceListFilterName,
                            builder: (context, state) {
                              final extra =
                                  state.extra as Map<String, dynamic>? ?? {};
                              final allCountries =
                                  extra['allCountries'] as List<Country>? ?? [];
                              final allSourceTypes =
                                  extra['allSourceTypes'] as List<SourceType>? ??
                                      [];
                              final initialSelectedHeadquarterCountries = extra[
                                      'initialSelectedHeadquarterCountries']
                                  as Set<Country>? ??
                                  {};
                              final initialSelectedSourceTypes =
                                  extra['initialSelectedSourceTypes']
                                      as Set<SourceType>? ??
                                      {};

                              return SourceListFilterPage(
                                allCountries: allCountries,
                                allSourceTypes: allSourceTypes,
                                initialSelectedHeadquarterCountries:
                                    initialSelectedHeadquarterCountries,
                                initialSelectedSourceTypes:
                                    initialSelectedSourceTypes,
                              );
                            },
                          ),
                        ],
                      ),
                      GoRoute(
                        path: Routes.feedFilterEventCountries,
                        name: Routes.feedFilterEventCountriesName,
                        pageBuilder: (context, state) {
                          final l10n = context.l10n;
                          final filterBloc =
                              state.extra! as HeadlinesFilterBloc;
                          return MaterialPage(
                            child: CountryFilterPage(
                              title: l10n.headlinesFeedFilterEventCountryLabel,
                              filterBloc: filterBloc,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // --- Branch 2: Search ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.search,
                name: Routes.searchName,
                builder: (context, state) => const HeadlinesSearchPage(),
                routes: [
                  // Sub-route for article details from search
                  GoRoute(
                    path: 'article/:id',
                    name: Routes.searchArticleDetailsName,
                    builder: (context, state) {
                      final headlineFromExtra = state.extra as Headline?;
                      final headlineIdFromPath = state.pathParameters['id'];
                      return MultiBlocProvider(
                        providers: [
                          BlocProvider(
                            create: (context) => HeadlineDetailsBloc(
                              headlinesRepository: context
                                  .read<DataRepository<Headline>>(),
                            ),
                          ),
                          BlocProvider(
                            create: (context) => SimilarHeadlinesBloc(
                              headlinesRepository: context
                                  .read<DataRepository<Headline>>(),
                            ),
                          ),
                        ],
                        child: HeadlineDetailsPage(
                          initialHeadline: headlineFromExtra,
                          headlineId:
                              headlineFromExtra?.id ?? headlineIdFromPath,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // --- Branch 3: Account ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.account,
                name: Routes.accountName,
                builder: (context, state) => const AccountPage(),
                routes: [
                  // ShellRoute for settings to provide SettingsBloc to children
                  ShellRoute(
                    builder: (BuildContext context, GoRouterState state, Widget child) {
                      // This builder provides SettingsBloc to all routes within this ShellRoute.
                      // 'child' will be SettingsPage, AppearanceSettingsPage, etc.
                      final appBloc = context.read<AppBloc>();
                      final userId = appBloc.state.user?.id;

                      return BlocProvider<SettingsBloc>(
                        create: (context) {
                          final settingsBloc = SettingsBloc(
                            userAppSettingsRepository: context
                                .read<DataRepository<UserAppSettings>>(),
                            inlineAdCacheService: inlineAdCacheService,
                          );
                          // Only load settings if a userId is available
                          if (userId != null) {
                            settingsBloc.add(
                              SettingsLoadRequested(userId: userId),
                            );
                          } else {
                            // Handle case where user is unexpectedly null.
                            logger.warning(
                              'User ID is null when creating SettingsBloc. Settings will not be loaded.',
                            );
                          }
                          return settingsBloc;
                        },
                        // child is the actual page widget (SettingsPage, AppearanceSettingsPage, etc.)
                        child: child,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: Routes.settings,
                        name: Routes.settingsName,
                        builder: (context, state) => const SettingsPage(),
                        // --- Settings Sub-Routes ---
                        routes: [
                          GoRoute(
                            path: Routes.settingsAppearance,
                            name: Routes.settingsAppearanceName,
                            builder: (context, state) =>
                                const AppearanceSettingsPage(),
                            routes: [
                              // Children of AppearanceSettingsPage
                              GoRoute(
                                path: Routes.settingsAppearanceTheme,
                                name: Routes.settingsAppearanceThemeName,
                                builder: (context, state) =>
                                    const ThemeSettingsPage(),
                              ),
                              GoRoute(
                                path: Routes.settingsAppearanceFont,
                                name: Routes.settingsAppearanceFontName,
                                builder: (context, state) =>
                                    const FontSettingsPage(),
                              ),
                            ],
                          ),
                          GoRoute(
                            path: Routes.settingsFeed,
                            name: Routes.settingsFeedName,
                            builder: (context, state) =>
                                const FeedSettingsPage(),
                          ),
                          GoRoute(
                            path: Routes.settingsNotifications,
                            name: Routes.settingsNotificationsName,
                            builder: (context, state) =>
                                const NotificationSettingsPage(),
                          ),
                          GoRoute(
                            path: Routes.settingsLanguage,
                            name: Routes.settingsLanguageName,
                            builder: (context, state) =>
                                const LanguageSettingsPage(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // New routes for Account sub-pages
                  GoRoute(
                    path: Routes.manageFollowedItems,
                    name: Routes.manageFollowedItemsName,
                    builder: (context, state) =>
                        const ManageFollowedItemsPage(),
                    routes: [
                      GoRoute(
                        path: Routes.followedTopicsList,
                        name: Routes.followedTopicsListName,
                        builder: (context, state) =>
                            const FollowedTopicsListPage(),
                        routes: [
                          GoRoute(
                            path: Routes.addTopicToFollow,
                            name: Routes.addTopicToFollowName,
                            builder: (context, state) =>
                                const AddTopicToFollowPage(),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: Routes.followedSourcesList,
                        name: Routes.followedSourcesListName,
                        builder: (context, state) =>
                            const FollowedSourcesListPage(),
                        routes: [
                          GoRoute(
                            path: Routes.addSourceToFollow,
                            name: Routes.addSourceToFollowName,
                            builder: (context, state) =>
                                const AddSourceToFollowPage(),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: Routes.followedCountriesList,
                        name: Routes.followedCountriesListName,
                        builder: (context, state) =>
                            const FollowedCountriesListPage(),
                        routes: [
                          GoRoute(
                            path: Routes.addCountryToFollow,
                            name: Routes.addCountryToFollowName,
                            builder: (context, state) =>
                                const AddCountryToFollowPage(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: Routes.accountSavedHeadlines,
                    name: Routes.accountSavedHeadlinesName,
                    builder: (context, state) {
                      return const SavedHeadlinesPage();
                    },
                    routes: [
                      GoRoute(
                        path: Routes.accountArticleDetails,
                        name: Routes.accountArticleDetailsName,
                        builder: (context, state) {
                          final headlineFromExtra = state.extra as Headline?;
                          final headlineIdFromPath = state.pathParameters['id'];
                          return MultiBlocProvider(
                            providers: [
                              BlocProvider(
                                create: (context) => HeadlineDetailsBloc(
                                  headlinesRepository: context
                                      .read<DataRepository<Headline>>(),
                                ),
                              ),
                              BlocProvider(
                                create: (context) => SimilarHeadlinesBloc(
                                  headlinesRepository: context
                                      .read<DataRepository<Headline>>(),
                                ),
                              ),
                            ],
                            child: HeadlineDetailsPage(
                              initialHeadline: headlineFromExtra,
                              headlineId:
                                  headlineFromExtra?.id ?? headlineIdFromPath,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
