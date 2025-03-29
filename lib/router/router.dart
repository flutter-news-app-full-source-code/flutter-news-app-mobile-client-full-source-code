//
// ignore_for_file: avoid_print, lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/account/view/account_page.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/authentication/view/authentication_page.dart';
import 'package:ht_main/authentication/view/email_link_sent_page.dart';
import 'package:ht_main/authentication/view/email_sign_in_page.dart';
import 'package:ht_main/headline-details/view/headline_details_page.dart';
import 'package:ht_main/headlines-feed/view/headlines_feed_page.dart';
import 'package:ht_main/headlines-search/view/headlines_search_page.dart';
import 'package:ht_main/l10n/l10n.dart';
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
      // --- Get Current State ---
      // Safely read the AppBloc state. refreshListenable ensures this runs
      // within a valid context after AppBloc state changes.
      final appStatus = context.read<AppBloc>().state.status;
      // The matched route pattern (e.g., '/authentication/email-sign-in').
      final currentLocation = state.matchedLocation;
      // The full URI including query parameters (e.g., '/authentication?context=linking').
      final currentUri = state.uri;

      // --- Debug Logging ---
      // Log current state for easier debugging of redirect behavior.
      print(
        'GoRouter Redirect Check:\n'
        '  Current Location (Matched): $currentLocation\n'
        '  Current URI (Full): $currentUri\n'
        '  AppStatus: $appStatus',
      );

      // --- Define Key Paths ---
      // Base paths for major sections.
      const authenticationPath = Routes.authentication; // '/authentication'
      const headlinesFeedPath = Routes.headlinesFeed;   // '/headlines-feed'
      // Specific authentication sub-routes crucial for the email linking flow.
      const emailSignInPath = '$authenticationPath/${Routes.emailSignIn}'; // '/authentication/email-sign-in'
      const emailLinkSentPath = '$authenticationPath/${Routes.emailLinkSent}'; // '/authentication/email-link-sent'

      // --- Helper Booleans ---
      // Check if the navigation target is within the authentication section.
      final isGoingToAuth = currentLocation.startsWith(authenticationPath);
      // Check if the navigation target is within the headlines feed section.
      final isGoingToFeed = currentLocation.startsWith(headlinesFeedPath);
      // Check if the navigation target is the *exact* base authentication path.
      final isGoingToBaseAuthPath = currentLocation == authenticationPath;
      // Check if the 'context=linking' query parameter is present in the URI.
      final isLinkingContext =
          currentUri.queryParameters['context'] == 'linking';

      // --- Redirect Logic based on AppStatus ---

      // --- Case 1: Unauthenticated User ---
      if (appStatus == AppStatus.unauthenticated) {
        print('  Redirect Decision: User is UNauthenticated.');
        // If the user is NOT already going to an authentication path...
        if (!isGoingToAuth) {
          // ...redirect them to the main authentication page to sign in or sign up.
          print('    Action: Redirecting to $authenticationPath');
          return authenticationPath;
        }
        // Otherwise, allow them to stay on the authentication path they are navigating to.
        print('    Action: Allowing navigation within authentication section.');
        return null; // Allow access
      }

      // --- Case 2: Anonymous User ---
      else if (appStatus == AppStatus.anonymous) {
        print('  Redirect Decision: User is ANONYMOUS.');

        // **Sub-Case 2.1: Navigating to the BASE Authentication Path (`/authentication`)**
        if (isGoingToBaseAuthPath) {
          // Allow access ONLY if they are explicitly starting the linking flow
          // (indicated by the 'context=linking' query parameter).
          if (isLinkingContext) {
            print('    Action: Allowing navigation to BASE auth for account linking.');
            return null; // Allow access
          } else {
            // Prevent anonymous users from accessing the initial sign-in screen again.
            // Redirect them to the main content (headlines feed).
            print('    Action: Preventing access to initial sign-in, redirecting to $headlinesFeedPath');
            return headlinesFeedPath; // Redirect to feed
          }
        }

        // **Sub-Case 2.2: Navigating to Specific Email Linking Sub-Routes**
        // Explicitly allow access to the necessary pages for the email linking process,
        // even if the 'context=linking' parameter is lost during navigation between these pages.
        else if (currentLocation == emailSignInPath || currentLocation == emailLinkSentPath) {
           print('    Action: Allowing navigation to email linking sub-route ($currentLocation).');
           return null; // Allow access
        }

        // **Sub-Case 2.3: Navigating Within the Headlines Feed Section**
        // Allow anonymous users to access the main content feed and its sub-routes (like account).
        else if (isGoingToFeed) {
          print('    Action: Allowing navigation within feed section ($currentLocation).');
          return null; // Allow access
        }

        // **Sub-Case 2.4: Fallback for Unexpected Paths**
        // If an anonymous user tries to navigate anywhere else unexpected,
        // redirect them to the main content feed as a safe default.
        else {
          print('    Action: Unexpected path ($currentLocation), redirecting to $headlinesFeedPath');
          return headlinesFeedPath; // Redirect to feed
        }
      }

      // --- Case 3: Authenticated User ---
      else if (appStatus == AppStatus.authenticated) {
        print('  Redirect Decision: User is AUTHENTICATED.');
        // If an authenticated user tries to access any part of the authentication flow...
        if (isGoingToAuth) {
          // ...redirect them away to the main content feed. They don't need to authenticate again.
          print('    Action: Preventing access to authentication section, redirecting to $headlinesFeedPath');
          return headlinesFeedPath; // Redirect to feed
        }
        // Otherwise, allow authenticated users to access any other part of the app (feed, account, settings, etc.).
        print('    Action: Allowing navigation to non-auth section ($currentLocation).');
        return null; // Allow access
      }

      // --- Case 4: Initial/Unknown Status ---
      // This might occur briefly during app startup before the status is determined.
      // Generally, allow navigation during this phase. If specific routes need
      // protection even during startup, add checks here.
      else {
        print('  Redirect Decision: AppStatus is initial/unknown. Allowing navigation.');
        return null; // Allow access
      }

      // --- Default: No Redirect ---
      // If none of the above conditions triggered an explicit redirect, allow navigation.
      // This line should theoretically not be reached if the logic above is exhaustive.
      // print('  Redirect Decision: No specific redirect condition met. Allowing navigation.');
      // return null; // Allow access (already covered by the final return null below)
    },
    // --- Routes ---
    routes: [
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
            showAnonymousButton = false; // Don't show anon button when linking
          } else {
            headline = l10n.authenticationSignInHeadline;
            subHeadline = l10n.authenticationSignInSubheadline;
            showAnonymousButton = true; // Show anon button for initial sign-in
          }

          return AuthenticationPage(
            headline: headline,
            subHeadline: subHeadline,
            showAnonymousButton: showAnonymousButton,
          );
        },
        routes: [
          // --- New Email Flow Sub-routes ---
          GoRoute(
            path: Routes.emailSignIn,
            name: Routes.emailSignInName,
            builder: (context, state) => const EmailSignInPage(),
          ),
          GoRoute(
            path: Routes.emailLinkSent,
            name: Routes.emailLinkSentName,
            builder: (context, state) => const EmailLinkSentPage(),
          ),
          // --- Existing Placeholder Sub-routes (Keep or remove as needed) ---
          GoRoute(
            path: Routes.forgotPassword, // Keep if feature is planned
            name: Routes.forgotPasswordName,
            builder: (BuildContext context, GoRouterState state) {
              // Replace with actual implementation when ready
              return const Placeholder(child: Text('Forgot Password Page'));
            },
          ),
          GoRoute(
            path: Routes.resetPassword, // Keep if feature is planned
            name: Routes.resetPasswordName,
            builder: (BuildContext context, GoRouterState state) {
              // Replace with actual implementation when ready
              return const Placeholder(child: Text('Reset Password Page'));
            },
          ),
          GoRoute(
            path: Routes.confirmEmail, // Keep if feature is planned
            name: Routes.confirmEmailName,
            builder: (BuildContext context, GoRouterState state) {
              // Replace with actual implementation when ready
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
            path: Routes.account, // Keep account page route
            name: Routes.accountName,
            builder: (context, state) => const AccountPage(),
            // No sub-routes needed here anymore for linking
            // routes: [
            //   // Removed AccountLinkingPage route
            // ],
          ),
        ],
      ),
    ],
  );
}
