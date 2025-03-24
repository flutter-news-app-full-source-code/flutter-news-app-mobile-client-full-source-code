import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppBloc(),
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          return AdaptiveScaffold(
            useDrawer: false,
            smallBody: (_) => child,
            body: (_) => child,
            largeBody: (_) => child,
            smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
            secondaryBody: AdaptiveScaffold.emptyBuilder,
            largeSecondaryBody: AdaptiveScaffold.emptyBuilder,
            selectedIndex: state.selectedBottomNavigationIndex,
            onSelectedIndexChange: (index) {
              context.read<AppBloc>().add(
                    AppNavigationIndexChanged(context, index),
                  );
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.view_headline_outlined),
                selectedIcon: Icon(Icons.view_headline),
                label: 'Headlines',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          );
        },
      ),
    );
  }
}
