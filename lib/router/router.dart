import 'package:auth_repository/auth_repository.dart';
import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/in_app_notification_center_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/account_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/followed_contents/followed_content_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/in_app_notification_center_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/profile/edit_profile_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/view/saved_headlines_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/models/ad_theme_style.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/ad_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/inline_ad_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/rewarded_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/models/app_life_cycle_status.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/view/account_linking_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/view/authentication_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/view/email_code_verification_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/view/request_code_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/entity_details/bloc/entity_details_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/entity_details/view/entity_details_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/feed_decorators/services/feed_decorator_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_feed_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/bloc/headlines_filter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/services/feed_cache_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/view/headlines_feed_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/view/headlines_filter_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/headlines_feed/view/saved_headlines_filters_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/onboarding/app_tour/view/app_tour_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/onboarding/initial_personalization/bloc/initial_personalization_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/onboarding/initial_personalization/view/initial_personalization_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/rewards/view/rewards_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/go_router_observer.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/view/feed_settings_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/view/settings_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/settings/view/theme_and_font_settings_page.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
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
      final appState = context.read<AppBloc>().state;
      final appStatus = appState.status;
      final remoteConfig = appState.remoteConfig;
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
      const rewardsPath = '/${Routes.account}/${Routes.rewards}';
      const appTourPath = Routes.appTour;
      const initialPersonalizationPath = Routes.initialPersonalization;

      // RULE 0: Onboarding flows are inescapable.
      if (appStatus == AppLifeCycleStatus.preAuthOnboardingRequired) {
        logger.info('  Redirect Rule 0: Pre-auth tour required.');
        return currentLocation != appTourPath ? appTourPath : null;
      }

      if (appStatus == AppLifeCycleStatus.postAuthOnboardingRequired) {
        logger.info('  Redirect Rule 0: Post-auth personalization required.');
        return currentLocation != initialPersonalizationPath
            ? initialPersonalizationPath
            : null;
      }

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
        // This rule handles the completion of the post-auth personalization for
        // an anonymous user. When they finish, their status becomes `anonymous`,
        // but they are still on the `/initial-personalization` location. This
        // rule correctly redirects them to the feed.
        if (currentLocation == initialPersonalizationPath) {
          logger.info(
            '    Action: Anonymous user on personalization path. '
            'Redirecting to feed.',
          );
          return feedPath;
        }

        // Guard Rewards Page for Anonymous Users
        if (currentLocation == rewardsPath) {
          logger.info(
            '    Action: Anonymous user on rewards path. Redirecting to account linking.',
          );
          return accountLinkingPath;
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
        // This rule handles the completion of the post-auth personalization.
        // When the user finishes, their status becomes `authenticated`, but
        // they are still on the `/initial-personalization` location. This
        // rule correctly redirects them to the feed. It also acts as a
        // safeguard for any other case where an authenticated user might
        // land on this page.
        if (currentLocation == initialPersonalizationPath) {
          logger.info(
            '    Action: Authenticated user on personalization path. Redirecting to feed.',
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

      // RULE 4: Feature Gating - Rewards
      // If the user tries to access rewards but the feature is disabled,
      // redirect them to the account page.
      if (currentLocation == rewardsPath &&
          (remoteConfig?.features.rewards.enabled == false)) {
        logger.info('    Action: Rewards disabled. Redirecting to account.');
        return '/${Routes.account}';
      }

      // If none of the above rules apply, allow the navigation.
      logger.info('  Redirect: No condition met. Allowing navigation.');
      return null;
    },
    routes: [
      // A placeholder route for the root path. The redirect logic will always
      // move the user away from here to the correct location.
      GoRoute(
        path: Routes.appTour,
        name: Routes.appTourName,
        builder: (context, state) => const AppTourPage(),
      ),
      GoRoute(
        path: Routes.initialPersonalization,
        name: Routes.initialPersonalizationName,
        builder: (context, state) {
          return BlocProvider(
            create: (context) => InitialPersonalizationBloc(
              appBloc: context.read<AppBloc>(),
              userContentPreferencesRepository: context
                  .read<DataRepository<UserContentPreferences>>(),
              userContextRepository: context
                  .read<DataRepository<UserContext>>(),
              analyticsService: context.read<AnalyticsService>(),
              logger: context.read<Logger>(),
            )..add(InitialPersonalizationDataRequested()),
            child: const InitialPersonalizationPage(),
          );
        },
      ),

      GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),

      // --- Authentication and Account Linking Flows ---
      // These are top-level routes that exist outside the main app shell. They
      // use ShellRoutes to provide the AuthenticationBloc to all child routes.
      ShellRoute(
        builder: (context, state, child) {
          return BlocProvider(
            create: (context) => AuthenticationBloc(
              authenticationRepository: context.read<AuthRepository>(),
              analyticsService: context.read<AnalyticsService>(),
            ),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: Routes.authentication,
            name: Routes.authenticationName,
            builder: (BuildContext context, GoRouterState state) =>
                const AuthenticationPage(),
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
            builder: (context, state) => const AccountLinkingPage(),
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
          GoRoute(
            path: Routes.rewards,
            name: Routes.rewardsName,
            pageBuilder: (context, state) => MaterialPage(
              fullscreenDialog: true,
              child: RepositoryProvider<RewardedAdManager>(
                create: (context) => RewardedAdManager(
                  appBloc: context.read<AppBloc>(),
                  adService: context.read<AdService>(),
                  analyticsService: context.read<AnalyticsService>(),
                  logger: context.read<Logger>(),
                ),
                child: const RewardsPage(),
              ),
            ),
          ),
          GoRoute(
            path: Routes.editProfile,
            name: Routes.editProfileName,
            builder: (context, state) => const EditProfilePage(),
          ),
          GoRoute(
            path: Routes.notificationsCenter,
            name: Routes.notificationsCenterName,
            builder: (context, state) {
              // Provide the InAppNotificationCenterBloc here so it's available
              // in the BuildContext when InAppNotificationCenterPage's
              // initState runs.
              return BlocProvider(
                create: (context) => InAppNotificationCenterBloc(
                  inAppNotificationRepository: context
                      .read<DataRepository<InAppNotification>>(),
                  appBloc: context.read<AppBloc>(),
                  logger: context.read<Logger>(),
                )..add(const InAppNotificationCenterSubscriptionRequested()),
                child: const InAppNotificationCenterPage(),
              );
            },
          ),
          GoRoute(
            path: Routes.settings,
            name: Routes.settingsName,
            builder: (context, state) => const SettingsPage(),
            routes: [
              GoRoute(
                path: Routes.settingsAccentColorAndFonts,
                name: Routes.settingsAccentColorAndFontsName,
                builder: (context, state) => const ThemeAndFontSettingsPage(),
              ),
              GoRoute(
                path: Routes.settingsFeed,
                name: Routes.settingsFeedName,
                builder: (context, state) => const FeedSettingsPage(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.manageFollowedItems,
            name: Routes.manageFollowedItemsName,
            builder: (context, state) => const FollowedContentPage(),
          ),
          GoRoute(
            path: Routes.accountSavedHeadlines,
            name: Routes.accountSavedHeadlinesName,
            builder: (context, state) => BlocProvider<HeadlinesFeedBloc>(
              create: (context) {
                final appBloc = context.read<AppBloc>();
                final initialUserContentPreferences =
                    appBloc.state.userContentPreferences;
                return HeadlinesFeedBloc(
                  headlinesRepository: context.read<DataRepository<Headline>>(),
                  feedDecoratorService: FeedDecoratorService(),
                  adService: context.read<AdService>(),
                  appBloc: appBloc,
                  inlineAdCacheService: context.read<InlineAdCacheService>(),
                  feedCacheService: context.read<FeedCacheService>(),
                  initialUserContentPreferences: initialUserContentPreferences,
                  engagementRepository: context
                      .read<DataRepository<Engagement>>(),
                  contentLimitationService: context
                      .read<ContentLimitationService>(),
                  analyticsService: context.read<AnalyticsService>(),
                );
              },
              child: const SavedHeadlinesPage(),
            ),
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
                      adService: context.read<AdService>(),
                      inlineAdCacheService: context
                          .read<InlineAdCacheService>(),
                      analyticsService: context.read<AnalyticsService>(),
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

      // --- Feed Route ---
      // The HeadlinesFeedPage itself now provides the HeadlinesFeedBloc.
      // Child routes like 'filter' can access the BLoC because HeadlinesFeedPage
      // remains in the widget tree when they are pushed on top.
      ShellRoute(
        builder: (context, state, child) {
          // This ShellRoute provides the HeadlinesFeedBloc to the feed page
          // and all its sub-routes, ensuring consistent access.
          return BlocProvider<HeadlinesFeedBloc>(
            create: (context) {
              final appBloc = context.read<AppBloc>();
              final initialUserContentPreferences =
                  appBloc.state.userContentPreferences;
              return HeadlinesFeedBloc(
                headlinesRepository: context.read<DataRepository<Headline>>(),
                feedDecoratorService: FeedDecoratorService(),
                adService: context.read<AdService>(),
                appBloc: appBloc,
                inlineAdCacheService: context.read<InlineAdCacheService>(),
                feedCacheService: context.read<FeedCacheService>(),
                initialUserContentPreferences: initialUserContentPreferences,
                engagementRepository: context
                    .read<DataRepository<Engagement>>(),
                contentLimitationService: context
                    .read<ContentLimitationService>(),
                analyticsService: context.read<AnalyticsService>(),
              );
            },
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: Routes.feed,
            name: Routes.feedName,
            builder: (context, state) => const HeadlinesFeedPage(),
            routes: [
              GoRoute(
                path: Routes.savedHeadlineFilters,
                name: Routes.savedHeadlineFiltersName,
                pageBuilder: (context, state) {
                  return const MaterialPage(
                    fullscreenDialog: true,
                    child: SavedHeadlinesFiltersPage(),
                  );
                },
              ),
              GoRoute(
                path: Routes.feedFilter,
                name: Routes.feedFilterName,
                pageBuilder: (context, state) {
                  final extra = state.extra! as Map<String, dynamic>;
                  final initialFilter =
                      extra['initialFilter'] as HeadlineFilterCriteria;
                  final filterToEdit =
                      extra['filterToEdit'] as SavedHeadlineFilter?;

                  return MaterialPage(
                    fullscreenDialog: true,
                    child: BlocProvider(
                      create: (context) =>
                          HeadlinesFilterBloc(
                            topicsRepository: context
                                .read<DataRepository<Topic>>(),
                            sourcesRepository: context
                                .read<DataRepository<Source>>(),
                            countriesRepository: context
                                .read<DataRepository<Country>>(),
                          )..add(
                            FilterDataLoaded(
                              initialSelectedTopics: initialFilter.topics,
                              initialSelectedSources: initialFilter.sources,
                              initialSelectedCountries: initialFilter.countries,
                            ),
                          ),
                      child: HeadlinesFilterPage(
                        initialFilter: initialFilter,
                        filterToEdit: filterToEdit,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
