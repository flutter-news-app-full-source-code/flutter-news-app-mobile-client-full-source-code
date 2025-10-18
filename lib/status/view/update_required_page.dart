import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart' hide UiKitL10n;
import 'package:url_launcher/url_launcher.dart';

/// {@template update_required_page}
/// A full-screen page displayed when a mandatory application update is required.
///
/// This page informs the user about the need to update and provides links
/// to the appropriate app stores (iOS, Android). On web, it displays a
/// generic message as direct app store links are not applicable.
/// {@endtemplate}
class UpdateRequiredPage extends StatelessWidget {
  /// {@macro update_required_page}
  const UpdateRequiredPage({
    this.iosUpdateUrl,
    this.androidUpdateUrl,
    required this.currentAppVersion,
    required this.latestRequiredVersion,
    super.key,
  });

  /// The URL to open for iOS app updates.
  final String? iosUpdateUrl;

  /// The URL to open for Android app updates.
  final String? androidUpdateUrl;

  /// The current version of the application.
  final String? currentAppVersion;

  /// The latest required version of the application.
  final String? latestRequiredVersion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.system_update_alt,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.updateRequiredHeadline,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.updateRequiredSubheadline,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (currentAppVersion != null &&
                  latestRequiredVersion != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.currentAppVersionLabel(currentAppVersion!),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                Text(
                  l10n.latestRequiredVersionLabel(latestRequiredVersion!),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (!kIsWeb) ...[
                // Show platform-specific update buttons for mobile
                if (Theme.of(context).platform == TargetPlatform.iOS &&
                    (iosUpdateUrl?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(iosUpdateUrl!);
                        if (!await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        )) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(l10n
                                    .couldNotOpenUpdateUrl(iosUpdateUrl!)),
                                ),
                              ),
                            );
                        }
                      },
                      icon: const Icon(Icons.apple),
                      label: Text(l10n.updateRequiredButton),
                    ),
                  ),
                if (Theme.of(context).platform == TargetPlatform.android &&
                    (androidUpdateUrl?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(androidUpdateUrl!);
                        if (!await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        )) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(l10n.couldNotOpenUpdateUrl(
                                  androidUpdateUrl!,
                                ),
                              ),
                            );
                        }
                      },
                      icon: const Icon(Icons.shop),
                      label: Text(l10n.updateRequiredButton),
                    ),
                  ),
              ] else ...[
                // Generic message for web
                Text(
                  l10n.updateRequiredButton,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
