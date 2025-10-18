import 'package:flutter/material.dart';

/// {@template app_hot_restart_wrapper}
/// A widget that wraps the root of the application to provide a mechanism
/// for triggering a "hot restart" of the entire widget tree.
///
/// This is used to allow the user to retry the entire application
/// initialization process from a critical error state.
/// {@endtemplate}
class AppHotRestartWrapper extends StatefulWidget {
  /// {@macro app_hot_restart_wrapper}
  const AppHotRestartWrapper({required this.child, super.key});

  /// The child widget that will be wrapped.
  final Widget child;

  /// Finds the [AppHotRestartWrapper]'s state in the widget tree and calls
  /// its internal restart method.
  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_AppHotRestartWrapperState>()?.restartApp();
  }

  @override
  State<AppHotRestartWrapper> createState() => _AppHotRestartWrapperState();
}

class _AppHotRestartWrapperState extends State<AppHotRestartWrapper> {
  Key _key = UniqueKey();

  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    // By using a KeyedSubtree, we can force Flutter to discard the old
    // widget tree and build a new one from scratch when the key changes.
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
