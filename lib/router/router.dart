import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/authentication/view/authentication_page.dart';
import 'package:ht_main/headline-details/view/headline_details_page.dart';
import 'package:ht_main/headlines-feed/view/headlines_feed_page.dart';
import 'package:ht_main/headlines-search/view/headlines_search_page.dart';
import 'package:ht_main/router/routes.dart';

final appRouter = GoRouter(
  initialLocation: Routes.headlinesFeed,
  redirect: (BuildContext context, GoRouterState state) {
    final appStatus = context.read<AppBloc>().state.status;
    const authenticationPath = Routes.authentication;
    const headlinesFeedPath = Routes.headlinesFeed;

    // If the user is authenticated or anonymous, redirect to the headlines feed
    // unless they are already on a route within the headlines feed.
    if (appStatus == AppStatus.authenticated ||
        appStatus == AppStatus.anonymous) {
      if (!state.matchedLocation.startsWith(headlinesFeedPath)) {
        return headlinesFeedPath;
      }
    }
    // If the user is not authenticated, redirect to the authentication page
    // unless they are already on a route within the authentication section.
    else if (appStatus == AppStatus.unauthenticated) {
      if (!state.matchedLocation.startsWith(authenticationPath)) {
        return authenticationPath;
      }
    }
    // Otherwise, allow the navigation to proceed.
    return null;
  },
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
          path: Routes.search,
          name: Routes.searchName,
          builder: (BuildContext context, GoRouterState state) {
            return const HeadlinesSearchPage();
          },
        ),
        GoRoute(
          path: Routes.settings,
          name: Routes.settingsName,
          builder: (BuildContext context, GoRouterState state) {
            return const Placeholder(
              child: Center(child: Text('SETTINGS PAGE')),
            );
          },
        ),
      ],
    ),
  ],
);
