import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart' hide AppStatus;
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/account_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/followed_contents/countries/add_country_to_follow_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/followed_contents/countries/followed_countries_list_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/followed_contents/followed_contents_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/followed_contents/sources/add_source_to_follow_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/followed_contents/sources/followed_sources_list_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/followed_contents/topics/add_topic_to_follow_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/followed_contents/topics/followed_topics_list_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/saved_filters_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/saved_headlines_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/view/app_shell.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/view/account_linking_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/view/authentication_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/view/email_code_verification_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/view/request_code_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/discover/bloc/source_list_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/discover/view/discover_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/discover/view/source_list_filter_page.dart'
    as discover_filter;
import 'package:flutter_news_app_mobile_client_full_source_code/discover/view/source_list_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/entity_details/bloc/entity_details_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/entity_details/view/entity_details_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headline-details/bloc/headline_details_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headline-details/bloc/similar_headlines_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headline-details/view/headline_details_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/models/headline_filter.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/country_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/headlines_feed_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/headlines_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/source_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/source_list_filter_page.dart'
    as feed_filter;
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/topic_filter_page.dart';
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

/// Creates and configures the main [GoRouter] for the application.
///
/// This function sets up all the routes, navigation shells, and the crucial
/// redirect logic that governs access to different parts of the app based on
/// the user's authentication status *after* the app has successfully
/// initialized.
GoRouter createRouter({
  required ValueNotifier<AppLifeCycleStatus> authStatusNotifier,
  required GlobalKey<NavigatorState> navigatorKey,
  required Logger logger,
}) {
  return GoRouter(
    refreshListenable: authStatusNotifier,
    initialLocation: '/',
    debugLogDiagnostics: true,
    navigatorKey: navigatorKey,
    observers: [GoRouterObserver(logger: logger)],
    redirect: (BuildContext context, GoRouterState state) {
      // The redirect logic is the gatekeeper for the running app. It runs
      // before any navigation occurs and decides whether to allow the
      // navigation or redirect the user elsewhere.

      // Get the current, stable lifecycle status from the AppBloc.
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

      // Check if the user is trying to go to any part of the auth flow.
      final isGoingToAuth = currentLocation.startsWith(authenticationPath);
      // Check if the user is trying to go to any part of the account linking
      // flow.
      final isGoingToLinking = currentLocation.startsWith(accountLinkingPath);

      // RULE 1: If the user is unauthenticated, they can ONLY be on an
      // authentication path. If they try to go anywhere else, redirect them
      // to the main authentication page.
      if (appStatus == AppLifeCycleStatus.unauthenticated) {
        logger.info(
          '  Redirect Rule 1: User is unauthenticated. '
          'Targeting auth path: $isGoingToAuth.',
        );
        return isGoingToAuth ? null : authenticationPath;
      }

      // RULE 2: If the user is anonymous (guest)...
      if (appStatus == AppLifeCycleStatus.anonymous) {
        logger.info('  Redirect Rule 2: User is anonymous.');
        // ...and they try to go to the main authentication page, redirect
        // them to the feed. They should use the account linking flow instead.
        if (isGoingToAuth) {
          logger.info(
            '    Action: Anonymous user on auth path. Redirecting to feed.',
          );
          return feedPath;
        }
        // ...and they are at the root, send them to the feed.
        if (currentLocation == rootPath) {
          logger.info(
            '    Action: Anonymous user at root. Redirecting to feed.',
          );
          return feedPath;
        }
        // Otherwise, allow navigation (e.g., to account linking).
        return null;
      }

      // RULE 3: If the user is fully authenticated...
      if (appStatus == AppLifeCycleStatus.authenticated) {
        logger.info('  Redirect Rule 3: User is authenticated.');
        // ...and they try to go to any authentication or account linking page,
        // redirect them to the feed. They are already logged in.
        if (isGoingToAuth || isGoingToLinking) {
          logger.info(
            '    Action: Authenticated user on auth/linking path. '
            'Redirecting to feed.',
          );
          return feedPath;
        }
        // ...and they are at the root, send them to the feed.
        if (currentLocation == rootPath) {
          logger.info(
            '    Action: Authenticated user at root. Redirecting to feed.',
          );
          return feedPath;
        }
      }

      // If none of the above rules apply, allow the navigation.
      logger.info('  Redirect: No condition met. Allowing navigation.');
      return null;
    },
    routes: [
      // A placeholder route for the root path. The redirect logic will always
      // move the user away from here to the correct location.
      GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),

      // --- Authentication and Account Linking Flows ---
      // These are top-level routes that exist outside the main app shell.
      GoRoute(
        path: Routes.authentication,
        name: Routes.authenticationName,
        builder: (BuildContext context, GoRouterState state) {
          // Provide the AuthenticationBloc only to this part of the tree.
          return BlocProvider(
            create: (context) => AuthenticationBloc(
              authenticationRepository: context.read<AuthRepository>(),
            ),
            child: const AuthenticationPage(),
          );
        },
        routes: [
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

      // --- Account Modal ---
      // This is a full-screen modal route for managing account settings.
      GoRoute(
        path: Routes.account,
        name: Routes.accountName,
        pageBuilder: (context, state) =>
            const MaterialPage(fullscreenDialog: true, child: AccountPage()),
        routes: [
          // The settings section within the account modal. It uses a
          // ShellRoute to provide a SettingsBloc to all its children.
          ShellRoute(
            builder: (BuildContext context, GoRouterState state, Widget child) {
              final appBloc = context.read<AppBloc>();
              final userId = appBloc.state.user?.id;

              return BlocProvider<SettingsBloc>(
                create: (context) {
                  final settingsBloc = SettingsBloc(
                    userAppSettingsRepository: context
                        .read<DataRepository<UserAppSettings>>(),
                    inlineAdCacheService: context.read<InlineAdCacheService>(),
                  );
                  if (userId != null) {
                    settingsBloc.add(SettingsLoadRequested(userId: userId));
                  } else {
                    logger.warning(
                      'User ID is null when creating SettingsBloc. '
                      'Settings will not be loaded.',
                    );
                  }
                  return settingsBloc;
                },
                child: child,
              );
            },
            routes: [
              GoRoute(
                path: Routes.settings,
                name: Routes.settingsName,
                builder: (context, state) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: Routes.settingsAppearance,
                    name: Routes.settingsAppearanceName,
                    builder: (context, state) => const AppearanceSettingsPage(),
                    routes: [
                      GoRoute(
                        path: Routes.settingsAppearanceTheme,
                        name: Routes.settingsAppearanceThemeName,
                        builder: (context, state) => const ThemeSettingsPage(),
                      ),
                      GoRoute(
                        path: Routes.settingsAppearanceFont,
                        name: Routes.settingsAppearanceFontName,
                        builder: (context, state) => const FontSettingsPage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: Routes.settingsFeed,
                    name: Routes.settingsFeedName,
                    builder: (context, state) => const FeedSettingsPage(),
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
                    builder: (context, state) => const LanguageSettingsPage(),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: Routes.manageFollowedItems,
            name: Routes.manageFollowedItemsName,
            builder: (context, state) => const FollowedContentsPage(),
            routes: [
              GoRoute(
                path: Routes.followedTopicsList,
                name: Routes.followedTopicsListName,
                builder: (context, state) => const FollowedTopicsListPage(),
                routes: [
                  GoRoute(
                    path: Routes.addTopicToFollow,
                    name: Routes.addTopicToFollowName,
                    builder: (context, state) => const AddTopicToFollowPage(),
                  ),
                ],
              ),
              GoRoute(
                path: Routes.followedSourcesList,
                name: Routes.followedSourcesListName,
                builder: (context, state) => const FollowedSourcesListPage(),
                routes: [
                  GoRoute(
                    path: Routes.addSourceToFollow,
                    name: Routes.addSourceToFollowName,
                    builder: (context, state) => const AddSourceToFollowPage(),
                  ),
                ],
              ),
              GoRoute(
                path: Routes.followedCountriesList,
                name: Routes.followedCountriesListName,
                builder: (context, state) => const FollowedCountriesListPage(),
                routes: [
                  GoRoute(
                    path: Routes.addCountryToFollow,
                    name: Routes.addCountryToFollowName,
                    builder: (context, state) => const AddCountryToFollowPage(),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: Routes.accountSavedHeadlines,
            name: Routes.accountSavedHeadlinesName,
            builder: (context, state) => const SavedHeadlinesPage(),
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
                      headlineId: headlineFromExtra?.id ?? headlineIdFromPath,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: Routes.accountSavedFilters,
            name: Routes.accountSavedFiltersName,
            builder: (context, state) => const SavedFiltersPage(),
          ),
        ],
      ),

      // --- Global Routes (can be accessed from anywhere) ---
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
                      feedDecoratorService: FeedDecoratorService(
                        topicsRepository: context.read<DataRepository<Topic>>(),
                        sourcesRepository: context
                            .read<DataRepository<Source>>(),
                      ),
                      inlineAdCacheService: context
                          .read<InlineAdCacheService>(),
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
      GoRoute(
        path: '/multi-select-search',
        name: Routes.multiSelectSearchName,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final title = extra['title'] as String? ?? 'Select';
          final allItems = extra['allItems'] as List<dynamic>? ?? [];
          final initialSelectedItems =
              extra['initialSelectedItems'] as Set<dynamic>? ?? {};
          final itemBuilder =
              extra['itemBuilder'] as Function? ??
              (dynamic item) => item.toString();

          return MultiSelectSearchPage<dynamic>(
            title: title,
            allItems: allItems,
            initialSelectedItems: initialSelectedItems,
            // ignore: avoid_dynamic_calls
            itemBuilder: (dynamic item) => itemBuilder(item) as String,
          );
        },
      ),

      // --- Main App Shell with Bottom Navigation ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // --- Branch 1: Feed ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.feed,
                name: Routes.feedName,
                // The HeadlinesFeedBloc is created here. We pass the initial user
                // content preferences from the AppBloc to ensure the saved filters
                // are immediately available, fixing a state synchronization bug.
                builder: (context, state) => BlocProvider<HeadlinesFeedBloc>(
                  create: (context) {
                    final appBloc = context.read<AppBloc>();
                    final initialUserContentPreferences =
                        appBloc.state.userContentPreferences;
                    return HeadlinesFeedBloc(
                      headlinesRepository: context
                          .read<DataRepository<Headline>>(),
                      feedDecoratorService: FeedDecoratorService(
                        topicsRepository: context.read<DataRepository<Topic>>(),
                        sourcesRepository: context
                            .read<DataRepository<Source>>(),
                      ),
                      appBloc: appBloc,
                      inlineAdCacheService: context
                          .read<InlineAdCacheService>(),
                      initialUserContentPreferences:
                          initialUserContentPreferences,
                    );
                  },
                  child: const HeadlinesFeedPage(),
                ),
                routes: [
                  // Sub-route for article details within the feed context.
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
                          headlineId:
                              headlineFromExtra?.id ?? headlineIdFromPath,
                        ),
                      );
                    },
                  ),
                  // Sub-route for notifications page.
                  GoRoute(
                    path: Routes.notifications,
                    name: Routes.notificationsName,
                    builder: (context, state) {
                      return const Placeholder(
                        child: Center(child: Text('NOTIFICATIONS PAGE')),
                      );
                    },
                  ),
                  // Sub-route for the full-screen filter page.
                  GoRoute(
                    path: Routes.feedFilter,
                    name: Routes.feedFilterName,
                    pageBuilder: (context, state) {
                      // The 'extra' parameter now contains a map with the
                      // initial filter and the HeadlinesFeedBloc instance.
                      final extra = state.extra! as Map<String, dynamic>;
                      final initialFilter =
                          extra['initialFilter'] as HeadlineFilter;
                      final headlinesFeedBloc =
                          extra['headlinesFeedBloc'] as HeadlinesFeedBloc;

                      return MaterialPage(
                        fullscreenDialog: true,
                        // Wrap the HeadlinesFilterPage with a BlocProvider.value.
                        // This is crucial for providing the HeadlinesFeedBloc
                        // instance directly to the filter page's widget tree.
                        // This approach resolves the ProviderNotFoundException
                        // by decoupling the filter page from the main feed
                        // page's context, allowing it to operate correctly
                        // within its own route.
                        child: BlocProvider.value(
                          value: headlinesFeedBloc,
                          child: HeadlinesFilterPage(
                            initialFilter: initialFilter,
                          ),
                        ),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: Routes.feedFilterTopics,
                        name: Routes.feedFilterTopicsName,
                        builder: (context, state) {
                          final filterBloc =
                              state.extra! as HeadlinesFilterBloc;
                          return TopicFilterPage(filterBloc: filterBloc);
                        },
                      ),
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
                                  extra['allSourceTypes']
                                      as List<SourceType>? ??
                                  [];
                              final initialSelectedHeadquarterCountries =
                                  extra['initialSelectedHeadquarterCountries']
                                      as Set<Country>? ??
                                  {};
                              final initialSelectedSourceTypes =
                                  extra['initialSelectedSourceTypes']
                                      as Set<SourceType>? ??
                                  {};

                              return feed_filter.SourceListFilterPage(
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
          // --- Branch 2: Discover ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.discover,
                name: Routes.discoverName,
                builder: (context, state) => const DiscoverPage(),
                routes: [
                  GoRoute(
                    path: Routes.sourceList,
                    name: Routes.sourceListName,
                    builder: (context, state) {
                      final sourceTypeName = state.pathParameters['sourceType'];
                      if (sourceTypeName == null) {
                        return const Scaffold(
                          body: Center(child: Text('Source Type missing')),
                        );
                      }
                      final sourceType = SourceType.values.firstWhere(
                        (e) => e.name == sourceTypeName,
                      );
                      return SourceListPage(sourceType: sourceType);
                    },
                    routes: [
                      GoRoute(
                        path: Routes.sourceListFilter,
                        name: Routes.discoverSourceListFilterName,
                        builder: (context, state) {
                          final sourceListBloc = state.extra! as SourceListBloc;
                          return discover_filter.SourceListFilterPage(
                            sourceListBloc: sourceListBloc,
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
