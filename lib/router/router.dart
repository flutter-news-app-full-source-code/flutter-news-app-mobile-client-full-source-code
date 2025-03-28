//
// ignore_for_file: avoid_print, lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/account/view/account_linking_page.dart';
import 'package:ht_main/account/view/account_page.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/authentication/view/authentication_page.dart';
import 'package:ht_main/headline-details/view/headline_details_page.dart';
import 'package:ht_main/headlines-feed/view/headlines_feed_page.dart';
import 'package:ht_main/headlines-search/view/headlines_search_page.dart';
import 'package:ht_main/router/routes.dart';

/// Creates and configures the GoRouter instance for the application.
///
/// Requires an [authStatusNotifier] to trigger route re-evaluation when
/// authentication state changes.
GoRouter createRouter({required ValueNotifier<AppStatus> authStatusNotifier}) {
  return GoRouter(
    refreshListenable: authStatusNotifier,
    initialLocation: Routes.headlinesFeed,
    debugLogDiagnostics: true, // Enable verbose logging for debugging redirects
    // --- Redirect Logic ---
    redirect: (BuildContext context, GoRouterState state) {
      // Use context.read<AppBloc>() here. It's safe because refreshListenable
      // ensures this runs within a valid context after AppBloc state changes.
      final appStatus = context.read<AppBloc>().state.status;
      final currentLocation = state.matchedLocation;

      print(
        'GoRouter Redirect: Current Location: $currentLocation, AppStatus: $appStatus',
      ); // Debug print (Removed user)

      // Define core paths
      const authenticationPath = Routes.authentication;
      const headlinesFeedPath = Routes.headlinesFeed;
      // No longer need accountPath/backupDataPath here as they become sub-routes

      final isGoingToAuth = currentLocation.startsWith(authenticationPath);
      final isGoingToFeed = currentLocation.startsWith(headlinesFeedPath);

      // If the user is authenticated or anonymous...
      if (appStatus == AppStatus.authenticated ||
          appStatus == AppStatus.anonymous) {
        print('GoRouter Redirect: User is authenticated/anonymous.');
        // ...and they are trying to go to an auth path, redirect to feed
        if (isGoingToAuth) {
          print(
            'GoRouter Redirect: Trying to go to auth, redirecting to $headlinesFeedPath',
          );
          return headlinesFeedPath;
        }
        // If they are somehow not on the feed path or its sub-routes...
        // (e.g., initial load might hit '/', or an invalid top-level path)
        // Note: This assumes feed is the primary destination after login.
        if (!isGoingToFeed) {
          print(
            'GoRouter Redirect: Not on feed path, redirecting to $headlinesFeedPath',
          );
          return headlinesFeedPath;
        }
        print(
          'GoRouter Redirect: Authenticated/anonymous user staying on feed path or sub-route.',
        );
      }
      // If the user is not authenticated...
      else if (appStatus == AppStatus.unauthenticated) {
        print('GoRouter Redirect: User is unauthenticated.');
        // ...and they are NOT trying to go to an auth path, redirect to auth
        if (!isGoingToAuth) {
          print(
            'GoRouter Redirect: Not going to auth, redirecting to $authenticationPath',
          );
          return authenticationPath;
        }
        print(
          'GoRouter Redirect: Unauthenticated user staying on auth path or sub-route.',
        );
      }
      // If AppStatus is initial/unknown, don't redirect yet.
      // Let the initial location or the next state change handle it.
      else {
        print('GoRouter Redirect: AppStatus is initial/unknown, no redirect.');
      }

      // No redirect needed
      print(
        'GoRouter Redirect: No redirect needed for location: $currentLocation',
      );
      return null;
    },
    // --- Routes ---
    routes: [
      GoRoute(
        path: Routes.authentication,
        name: Routes.authenticationName,
        builder: (BuildContext context, GoRouterState state) {
          return const AuthenticationPage();
        },
        routes: [
          GoRoute(
            path: Routes.forgotPassword,
            name: Routes.forgotPasswordName,
            builder: (BuildContext context, GoRouterState state) {
              return const Placeholder(child: Text('Forgot Password Page'));
            },
          ),
          GoRoute(
            path: Routes.resetPassword,
            name: Routes.resetPasswordName,
            builder: (BuildContext context, GoRouterState state) {
              return const Placeholder(child: Text('Reset Password Page'));
            },
          ),
          GoRoute(
            path: Routes.confirmEmail,
            name: Routes.confirmEmailName,
            builder: (BuildContext context, GoRouterState state) {
              return const Placeholder(child: Text('Confirm Email Page'));
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.headlinesFeed,
        name: Routes.headlinesFeedName,
        builder: (BuildContext context, GoRouterState state) {
          return const HeadlinesFeedPage();
        },
        routes: [
          GoRoute(
            path: 'article/:id',
            name: Routes.articleDetailsName,
            builder: (BuildContext context, GoRouterState state) {
              final id = state.pathParameters['id']!;
              return HeadlineDetailsPage(headlineId: id);
            },
          ),
          GoRoute(
            path: 'search',
            name: Routes.searchName,
            builder: (BuildContext context, GoRouterState state) {
              return const HeadlinesSearchPage();
            },
          ),
          GoRoute(
            path: 'settings',
            name: Routes.settingsName,
            builder: (BuildContext context, GoRouterState state) {
              return const Placeholder(
                child: Center(child: Text('SETTINGS PAGE')),
              );
            },
          ),
          // --- Account Sub-Route ---
          GoRoute(
            path: Routes.account,
            name: Routes.accountName,
            builder: (context, state) => const AccountPage(),
            routes: [
              GoRoute(
                path: Routes.accountLinking,
                name: Routes.accountLinkingName,
                builder: (context, state) => const AccountLinkingPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
