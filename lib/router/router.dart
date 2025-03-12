import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/app/view/app_scaffold.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/search/search.dart';

final appRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: Routes.headlines,
          builder: (BuildContext context, GoRouterState state) {
            return const Placeholder(); // Use Placeholder for Headlines
          },
        ),
        GoRoute(
          path: Routes.search,
          builder: (BuildContext context, GoRouterState state) {
            return const SearchPage();
          },
        ),
      ],
    ),
  ],
);
