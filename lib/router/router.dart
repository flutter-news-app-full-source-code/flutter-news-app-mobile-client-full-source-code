import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/app/view/app_scaffold.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const AppScaffold();
      },
    ),
  ],
);
