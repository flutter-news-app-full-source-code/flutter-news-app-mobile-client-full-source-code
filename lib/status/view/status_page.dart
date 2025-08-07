import 'package:core/core.dart' hide AppStatus;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart';

/// A page that serves as the root UI during the critical startup sequence.
///
/// This widget is displayed *before* the main application's router and UI
/// shell are built. It is responsible for showing the user a clear status
/// while the remote configuration is being fetched, and it provides a way
/// for the user to retry if the fetch operation fails.
class StatusPage extends StatelessWidget {
  /// {@macro status_page}
  const StatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    // This page is a temporary root widget shown during the critical
    // startup phase before the main app UI (and GoRouter) is built.
    // It handles two key states: fetching the remote configuration and
    // recovering from a failed fetch.
    return Scaffold(
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          final l10n = AppLocalizationsX(context).l10n;

          if (state.status == AppStatus.configFetching) {
            // While fetching configuration, display a clear loading indicator.
            // This uses a shared widget from the UI kit for consistency.
            return LoadingStateWidget(
              icon: Icons.settings_applications_outlined,
              headline: l10n.headlinesFeedLoadingHeadline,
              subheadline: l10n.pleaseWait,
            );
          }

          // If fetching fails, show an error message with a retry option.
          // This allows the user to recover from transient network issues.
          return FailureStateWidget(
            exception: const NetworkException(), // A generic network error
            retryButtonText: 'l10n.retryButtonText', //TODO(fulleni): localize me.
            onRetry: () {
              // Dispatch the event to AppBloc to re-trigger the fetch.
              context.read<AppBloc>().add(const AppConfigFetchRequested());
            },
          );
        },
      ),
    );
  }
}
