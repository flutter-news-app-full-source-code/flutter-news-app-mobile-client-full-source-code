import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      // NAVIGATION
      useDrawer: false,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.view_headline),
          label: 'Headlines',
        ),
        NavigationDestination(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
      ],
      // MAIN BODY
      smallBody: (context) => const Placeholder(),
      body: (context) => const Placeholder(),
      largeBody: (context) => const Placeholder(),

      // SECONDARY BODY
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
      secondaryBody: AdaptiveScaffold.emptyBuilder,
      largeSecondaryBody: AdaptiveScaffold.emptyBuilder,
    );
  }
}
