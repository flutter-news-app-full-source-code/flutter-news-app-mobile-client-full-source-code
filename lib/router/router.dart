import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/app/view/app_scaffold.dart';
import 'package:ht_main/headlines/view/headlines_page.dart';
import 'package:ht_main/router/routes.dart';

final appRouter = GoRouter(
  initialLocation: Routes.headlines,
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: Routes.headlines,
          builder: (BuildContext context, GoRouterState state) {
            return const HeadlinesPage();
          },
        ),
        GoRoute(
          path: Routes.search,
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
