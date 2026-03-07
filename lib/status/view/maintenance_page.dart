import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:verity_mobile/l10n/app_localizations.dart';
import 'package:verity_mobile/shared/constants/app_layout.dart';

/// A page displayed to the user when the application is in maintenance mode.
///
/// This is a simple, static page that informs the user that the app is
/// temporarily unavailable and asks them to check back later. It's designed
/// to be displayed globally, blocking access to all other app features.
class MaintenancePage extends StatelessWidget {
  /// {@macro maintenance_page}
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // The Scaffold provides the basic Material Design visual layout structure.
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxDialogContentWidth,
          ),
          child: Padding(
            // Use consistent padding from the UI kit.
            padding: const EdgeInsets.all(AppSpacing.lg),
            // The InitialStateWidget from the UI kit is reused here to provide a
            // consistent look and feel for full-screen informational states.
            child: InitialStateWidget(
              icon: Icons.build_circle_outlined,
              headline: l10n.maintenanceHeadline,
              subheadline: l10n.maintenanceSubheadline,
            ),
          ),
        ),
      ),
    );
  }
}
