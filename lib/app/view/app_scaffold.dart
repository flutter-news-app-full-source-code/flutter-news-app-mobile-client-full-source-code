import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/router/routes.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      useDrawer: false,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.view_headline),
          label: 'Headlines',
          selectedIcon: Icon(Icons.view_headline),
        ),
        NavigationDestination(
          icon: Icon(Icons.search),
          label: 'Search',
          selectedIcon: Icon(Icons.search),
        ),
      ],
      smallBody: (_) => child,
      body: (_) => child,
      largeBody: (_) => child,
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
      secondaryBody: AdaptiveScaffold.emptyBuilder,
      largeSecondaryBody: AdaptiveScaffold.emptyBuilder,
      onSelectedIndexChange: (index) {
        if (index == 0) {
          context.go(Routes.headlines);
        } else if (index == 1) {
          context.go(Routes.search);
        }
      },
    );
  }
}
