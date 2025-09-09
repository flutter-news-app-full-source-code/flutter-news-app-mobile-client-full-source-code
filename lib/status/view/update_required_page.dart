import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// A page displayed to the user when a mandatory app update is required.
///
/// This page informs the user that they must update the application to the
/// latest version to continue using it. It provides a button that links
/// directly to the appropriate app store page by fetching the URL from the
/// remote configuration.
class UpdateRequiredPage extends StatelessWidget {
  /// {@macro update_required_page}
  const UpdateRequiredPage({super.key});

  /// Attempts to launch the given URL in an external application (e.g., browser
  /// or app store).
  ///
  /// Shows a [SnackBar] with an error message if the URL cannot be launched.
  Future<void> _launchUrl(BuildContext context, String url) async {
    // Ensure the URL is not empty before attempting to parse.
    if (url.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          // TODO(fulleni): localize later.
          const SnackBar(content: Text('Update URL is not available.')),
        );
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      // Launch the URL externally. This will open the App Store, Play Store,
      // or a browser.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // If the URL can't be launched, inform the user.
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not open update URL: $url')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // This is the robust, production-ready way to get the update URL.
    // It uses BlocProvider.of(context) to access the AppBloc instance and
    // determines the correct URL based on the current platform (iOS/Android).
    // It falls back to an empty string if the remote config is not available.
    final appBloc = BlocProvider.of<AppBloc>(context);
    final updateUrl = Theme.of(context).platform == TargetPlatform.android
        ? appBloc.state.remoteConfig?.appStatus.androidUpdateUrl
        : appBloc.state.remoteConfig?.appStatus.iosUpdateUrl;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reusing the InitialStateWidget for a consistent UI.
            InitialStateWidget(
              icon: Icons.system_update_alt,
              headline: l10n.updateRequiredHeadline,
              subheadline: l10n.updateRequiredSubheadline,
            ),
            const SizedBox(height: AppSpacing.lg),
            // The button to direct the user to the app store.
            // It's disabled if the update URL is not available.
            ElevatedButton(
              onPressed: updateUrl != null && updateUrl.isNotEmpty
                  ? () => _launchUrl(context, updateUrl)
                  : null,
              child: Text(l10n.updateRequiredButton),
            ),
          ],
        ),
      ),
    );
  }
}
