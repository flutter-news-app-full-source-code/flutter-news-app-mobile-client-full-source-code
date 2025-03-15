import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/app/view/app_scaffold.dart';
import 'package:ht_main/headlines-feed/view/headlines_feed_page.dart';
import 'package:ht_main/router/routes.dart';

final appRouter = GoRouter(
  initialLocation: Routes.headlinesFeed,
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppScaffold(child: child);
      },
      routes: [
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
                return Placeholder(child: Text('Article ID: $id'));
              },
            ),
          ],
        ),
        GoRoute(
          path: Routes.search,
          name: Routes.searchName,
          builder: (BuildContext context, GoRouterState state) {
            return const Placeholder(
              child: Center(
                child: Text('SEARCH PAGE'),
              ),
            );
          },
        ),
        GoRoute(
          path: Routes.account,
          name: Routes.accountName,
          builder: (BuildContext context, GoRouterState state) {
            return const Placeholder(
              child: Center(
                child: Text('ACCOUNT PAGE'),
              ),
            );
          },
        ),
      ],
    ),
  ],
);
