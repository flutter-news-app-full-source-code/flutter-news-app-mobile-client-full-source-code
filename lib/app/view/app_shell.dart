//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/l10n/l10n.dart';

/// A responsive scaffold shell for the main application sections.
///
/// Uses [AdaptiveScaffold] to provide appropriate navigation
/// (bottom bar, rail, or drawer) based on screen size.
class AppShell extends StatelessWidget {
  /// Creates an [AppShell].
  ///
  /// Requires a [navigationShell] to manage the nested navigators
  /// for each section.
  const AppShell({required this.navigationShell, super.key});

  /// The [StatefulNavigationShell] provided by [GoRouter] for managing nested
  /// navigators in a stateful way.
  final StatefulNavigationShell navigationShell;

  // Corrected callback signature if needed, though the original looks standard.
  // Let's ensure the AdaptiveScaffold call uses the correct signature.
  // The primary issue was likely the missing import.

  void _goBranch(int index) {
    // Navigate to the corresponding branch using the index.
    // The `saveState` parameter is crucial for preserving the state
    // of each navigation branch (e.g., scroll position).
    navigationShell.goBranch(
      index,
      // Navigate to the initial location of the branch if the user taps
      // the same active destination again. Otherwise, defaults to false.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AdaptiveScaffold(
      // Use the index from the navigationShell to sync the selected destination.
      selectedIndex: navigationShell.currentIndex,
      // Callback when a destination is selected.
      // Ensure the parameter type is explicitly int.
      onSelectedIndexChange: _goBranch,
      // Define the navigation destinations.
      destinations: [
        const NavigationDestination(
          // Make const
          icon: Icon(Icons.article_outlined),
          selectedIcon: Icon(Icons.article),
          label: l10n.bottomNavFeedLabel, // Placeholder until generated
        ),
        const NavigationDestination(
          // Make const
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: l10n.bottomNavSearchLabel, // Placeholder until generated
        ),
        const NavigationDestination(
          // Make const
          icon: Icon(Icons.account_circle_outlined),
          selectedIcon: Icon(Icons.account_circle),
          label: l10n.bottomNavAccountLabel, // Placeholder until generated
        ),
      ],
      // The body displays the widget tree for the currently selected branch.
      // The [NavigationShell] widget handles building the appropriate page.
      body: (_) => navigationShell,

      // Optional: Configure small screen navigation type (defaults to bottomNav)
      // smallBreakpoint: const WidthPlatformBreakpoint(end: 700),
      // smallBuilder: (_, __) => AdaptiveScaffold.standardBottomNavigationBar(
      //   destinations: destinations,
      // ),

      // Optional: Configure medium screen navigation type (defaults to navRail)
      // mediumBreakpoint: const WidthPlatformBreakpoint(begin: 700, end: 1000),
      // mediumBuilder: (_, __, ___) => AdaptiveScaffold.standardNavigationRail(
      //   destinations: destinations,
      //   // leading: const Icon(Icons.menu), // Example leading widget
      // ),

      // Optional: Configure large screen navigation type (defaults to drawer)
      // largeBreakpoint: const WidthPlatformBreakpoint(begin: 1000),
      // largeBuilder: (_, __, ___) => AdaptiveScaffold.standardNavigationDrawer(
      //   destinations: destinations,
      // ),
    );
  }
}
