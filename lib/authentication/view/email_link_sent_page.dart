import 'package:flutter/material.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';

/// {@template email_link_sent_page}
/// Confirmation page shown after a sign-in link has been sent to
/// the user's email. Instructs the user to check their inbox.
/// {@endtemplate}
class EmailLinkSentPage extends StatelessWidget {
  /// {@macro email_link_sent_page}
  const EmailLinkSentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emailLinkSentPageTitle), // New l10n key needed
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingLarge),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined, // Suggestive icon
                  size: 80,
                  // Consider using theme color
                  // color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.emailLinkSentConfirmation, // New l10n key needed
                  style: textTheme.titleLarge, // Prominent text style
                  textAlign: TextAlign.center,
                ),
                // Optional: Add a button to go back if needed,
                // but AppBar back button might suffice.
                // const SizedBox(height: AppSpacing.xxl),
                // OutlinedButton(
                //   onPressed: () => context.pop(), // Or navigate elsewhere
                //   child: Text(l10n.backButtonLabel), // New l10n key
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
