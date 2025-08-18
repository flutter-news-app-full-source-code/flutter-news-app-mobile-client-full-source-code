import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart' hide AppStatus;
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/account_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/account_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/manage_followed_items/manage_followed_items_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/manage_followed_items/sources/add_source_to_follow_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/manage_followed_items/sources/followed_sources_list_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/manage_followed_items/topics/add_topic_to_follow_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/manage_followed_items/topics/followed_topics_list_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/saved_headlines_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/config/config.dart'
    as local_config;
import 'package:flutter_news_app_mobile_client_full_source_code/app/view/app_shell.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/view/authentication_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/view/email_code_verification_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/view/request_code_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/entity_details/view/entity_details_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headline-details/bloc/headline_details_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headline-details/bloc/similar_headlines_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headline-details/view/headline_details_page.dart';
// import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/countries_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/sources_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/bloc/topics_filter_bloc.dart';
// import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/country_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/headlines_feed_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/headlines_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/source_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-feed/view/topic_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-search/bloc/headlines_search_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines-search/view/headlines_search_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
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
import 'package:go_router/go_router.dart';

/// Creates and configures the GoRouter instance for the application.
///
/// Requires an [authStatusNotifier] to trigger route re-evaluation when
/// authentication state changes.
GoRouter createRouter({
  required ValueNotifier<AppStatus> authStatusNotifier,
  required AuthRepository authenticationRepository,
  required DataRepository<Headline> headlinesRepository,
  required DataRepository<Topic> topicsRepository,
  required DataRepository<Country> countriesRepository,
  required DataRepository<Source> sourcesRepository,
  required DataRepository<UserAppSettings> userAppSettingsRepository,
  required DataRepository<UserContentPreferences>
  userContentPreferencesRepository,
  required DataRepository<RemoteConfig> remoteConfigRepository,
  required DataRepository<User> userRepository,
  required local_config.AppEnvironment environment,
  required AdService adService,
}) {
  // Instantiate AccountBloc once to be shared
  final accountBloc = AccountBloc(
    authenticationRepository: authenticationRepository,
    userContentPreferencesRepository: userContentPreferencesRepository,
    environment: environment,
  );

  // Instantiate FeedDecoratorService once to be shared
  final feedDecoratorService = FeedDecoratorService(
    topicsRepository: topicsRepository,
    sourcesRepository: sourcesRepository,
    adService: adService,
  );

  return GoRouter(
    refreshListenable: authStatusNotifier,
    // Start at a neutral root path. The redirect logic will immediately
    // determine the correct path (/feed or /authentication), preventing
    // an attempt to build a complex page before the app state is ready.
    initialLocation: '/',
    debugLogDiagnostics: true,
    // --- Redirect Logic ---
    redirect: (BuildContext context, GoRouterState state) {
      final appStatus = context.read<AppBloc>().state.status;
      final currentLocation = state.matchedLocation;

      print(
        'GoRouter Redirect Check:\n'
        '  Current Location (Matched): $currentLocation\n'
        '  AppStatus: $appStatus',
      );

      const rootPath = '/';
      const authenticationPath = Routes.authentication;
      const feedPath = Routes.feed;
      final isGoingToAuth = currentLocation.startsWith(authenticationPath);

      // --- Workaround for Demo Environment ---
      // In the demo environment, the initial auth state from the in-memory
      // client might not be emitted before the first redirect check. If the app
      // is still in the `initial` state, we explicitly redirect to the
      // authentication page to begin the demo flow, avoiding the black screen.
      if (appStatus == AppStatus.initial &&
          environment == local_config.AppEnvironment.demo) {
        print(
          '  Redirect (Workaround): In demo mode with initial status. Forcing to authentication.',
        );
        return authenticationPath;
      }

      // With the new App startup architecture, the router is only active when
      // the app is in a stable, running state. The `redirect` function's
      // only responsibility is to handle auth-based route protection.
      // States like `configFetching`, `underMaintenance`, etc., are now
      // handled by the root App widget *before* this router is ever built.

      // --- Case 1: Unauthenticated User ---
      // If the user is unauthenticated, they should be on an auth path.
      // If they are trying to access any other part of the app, redirect them.
      if (appStatus == AppStatus.unauthenticated) {
        print('  Redirect: User is unauthenticated.');
        // If they are already on an auth path, allow it. Otherwise, redirect.
        return isGoingToAuth ? null : authenticationPath;
      }

      // --- Case 2: Anonymous or Authenticated User ---
      // If a user is anonymous or authenticated, they should not be able to
      // access the main authentication flows, with an exception for account
      // linking for anonymous users.
      if (appStatus == AppStatus.anonymous ||
          appStatus == AppStatus.authenticated) {
        print('  Redirect: User is $appStatus.');

        // If the user is trying to access an authentication path:
        if (isGoingToAuth) {
          // A fully authenticated user should never see auth pages.
          if (appStatus == AppStatus.authenticated) {
            print(
              '    Action: Authenticated user on auth path. Redirecting to feed.',
            );
            return feedPath;
          }

          // An anonymous user is only allowed on auth paths for account linking.
          final isLinking =
              state.uri.queryParameters['context'] == 'linking' ||
              currentLocation.contains('/linking/');

          if (isLinking) {
            print('    Action: Anonymous user on linking path. Allowing.');
            return null;
          } else {
            print(
              '    Action: Anonymous user on non-linking auth path. Redirecting to feed.',
            );
            return feedPath;
          }
        }

        // If the user is at the root path, they should be sent to the feed.
        if (currentLocation == rootPath) {
          print('    Action: User at root. Redirecting to feed.');
          return feedPath;
        }
      }

      // --- Fallback ---
      // For any other case, allow navigation.
      print('  Redirect: No condition met. Allowing navigation.');
      return null;
    },
    // --- Authentication Routes ---
    routes: [
      // A neutral root route that the app starts on. The redirect logic will
      // immediately move the user to the correct location. This route's
      // builder will never be called in practice.
      GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),
      GoRoute(
        path: Routes.authentication,
        name: Routes.authenticationName,
        builder: (BuildContext context, GoRouterState state) {
          final l10n = context.l10n;
          // Determine context from query parameter
          final isLinkingContext =
              state.uri.queryParameters['context'] == 'linking';

          // Define content based on context
          final String headline;
          final String subHeadline;
          final bool showAnonymousButton;

          if (isLinkingContext) {
            headline = l10n.authenticationLinkingHeadline;
            subHeadline = l10n.authenticationLinkingSubheadline;
            showAnonymousButton = false;
          } else {
            headline = l10n.authenticationSignInHeadline;
            subHeadline = l10n.authenticationSignInSubheadline;
            showAnonymousButton = true;
          }

          return BlocProvider(
            create: (context) => AuthenticationBloc(
              authenticationRepository: context.read<AuthRepository>(),
            ),
            child: AuthenticationPage(
              headline: headline,
              subHeadline: subHeadline,
              showAnonymousButton: showAnonymousButton,
              isLinkingContext: isLinkingContext,
            ),
          );
        },
        routes: [
          // Nested route for account linking flow (defined first for priority)
          GoRoute(
            path: Routes.accountLinking,
            name: Routes.accountLinkingName,
            builder: (context, state) => const SizedBox.shrink(),
            routes: [
              GoRoute(
                path: Routes.requestCode,
                name: Routes.linkingRequestCodeName,
                builder: (context, state) =>
                    const RequestCodePage(isLinkingContext: true),
              ),
              GoRoute(
                path: '${Routes.verifyCode}/:email',
                name: Routes.linkingVerifyCodeName,
                builder: (context, state) {
                  final email = state.pathParameters['email']!;
                  return EmailCodeVerificationPage(email: email);
                },
              ),
            ],
          ),
          // Non-linking authentication routes (defined after linking routes)
          GoRoute(
            path: Routes.requestCode,
            name: Routes.requestCodeName,
            builder: (context, state) =>
                const RequestCodePage(isLinkingContext: false),
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
      // --- Entity Details Routes (Top Level) ---
      GoRoute(
        path: Routes.topicDetails,
        name: Routes.topicDetailsName,
        builder: (context, state) {
          final args = state.extra as EntityDetailsPageArguments?;
          if (args == null) {
            return const Scaffold(
              body: Center(
                child: Text('Error: Missing topic details arguments'),
              ),
            );
          }
          return BlocProvider.value(
            value: accountBloc,
            child: EntityDetailsPage(args: args),
          );
        },
      ),
      GoRoute(
        path: Routes.sourceDetails,
        name: Routes.sourceDetailsName,
        builder: (context, state) {
          final args = state.extra as EntityDetailsPageArguments?;
          if (args == null) {
            return const Scaffold(
              body: Center(
                child: Text('Error: Missing source details arguments'),
              ),
            );
          }
          return BlocProvider.value(
            value: accountBloc,
            child: EntityDetailsPage(args: args),
          );
        },
      ),
      // --- Global Article Details Route (Top Level) ---
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

          // Ensure accountBloc is available if needed by HeadlineDetailsPage
          // or its descendants for actions like saving.
          // If AccountBloc is already provided higher up (e.g., in AppShell or App),
          // this specific BlocProvider.value might not be strictly necessary here,
          // but it's safer to ensure it's available for this top-level route.
          // We are using the `accountBloc` instance created at the top of `createRouter`.
          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: accountBloc),
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
      // --- Main App Shell ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Return the shell widget which contains the AdaptiveScaffold
          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: accountBloc),
              BlocProvider(
                create: (context) {
                  return HeadlinesFeedBloc(
                    headlinesRepository: context
                        .read<DataRepository<Headline>>(),
                    userContentPreferencesRepository: context
                        .read<DataRepository<UserContentPreferences>>(),
                    feedDecoratorService: feedDecoratorService,
                    appBloc: context.read<AppBloc>(),
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
                    appBloc: context.read<AppBloc>(),
                    feedDecoratorService: feedDecoratorService,
                  );
                },
              ),
              // Removed separate AccountBloc creation here
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
                          BlocProvider.value(value: accountBloc),
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
                  // Sub-route for notifications (placeholder) - MOVED HERE
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
                      // Sub-route for topic selection
                      GoRoute(
                        path: Routes.feedFilterTopics,
                        name: Routes.feedFilterTopicsName,
                        // Wrap with BlocProvider
                        builder: (context, state) => BlocProvider(
                          create: (context) => TopicsFilterBloc(
                            topicsRepository: context
                                .read<DataRepository<Topic>>(),
                          ),
                          child: const TopicFilterPage(),
                        ),
                      ),
                      // Sub-route for source selection
                      GoRoute(
                        path: Routes.feedFilterSources,
                        name: Routes.feedFilterSourcesName,
                        // Wrap with BlocProvider
                        builder: (context, state) => BlocProvider(
                          create: (context) => SourcesFilterBloc(
                            sourcesRepository: context
                                .read<DataRepository<Source>>(),
                            countriesRepository: // Added missing repository
                            context
                                .read<DataRepository<Country>>(),
                          ),
                          // Pass initialSelectedSources, country ISO codes, and source types from state.extra
                          child: Builder(
                            builder: (context) {
                              final extraData =
                                  state.extra as Map<String, dynamic>? ??
                                  const {};
                              final initialSources =
                                  extraData[keySelectedSources]
                                      as List<Source>? ??
                                  const [];
                              final initialCountryIsoCodes =
                                  extraData[keySelectedCountryIsoCodes]
                                      as Set<String>? ??
                                  const {};
                              final initialSourceTypes =
                                  extraData[keySelectedSourceTypes]
                                      as Set<SourceType>? ??
                                  const {};

                              return SourceFilterPage(
                                initialSelectedSources: initialSources,
                                initialSelectedCountryIsoCodes:
                                    initialCountryIsoCodes,
                                initialSelectedSourceTypes: initialSourceTypes,
                              );
                            },
                          ),
                        ),
                      ),
                      // Sub-route for country selection REMOVED
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
                          BlocProvider.value(value: accountBloc),
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
                          );
                          // Only load settings if a userId is available
                          if (userId != null) {
                            settingsBloc.add(
                              SettingsLoadRequested(userId: userId),
                            );
                          } else {
                            // Handle case where user is unexpectedly null.
                            print(
                              'ShellRoute/SettingsBloc: User ID is null when creating SettingsBloc. Settings will not be loaded.',
                            );
                          }
                          return settingsBloc;
                        },
                        child:
                            child, // child is the actual page widget (SettingsPage, AppearanceSettingsPage, etc.)
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
                      // GoRoute for followedCountriesList removed
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
                              BlocProvider.value(value: accountBloc),
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
