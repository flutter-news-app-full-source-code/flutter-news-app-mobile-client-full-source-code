import 'package:flutter/material.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';

/// {@template email_code_verification_page}
/// Page where the user enters the 6-digit code sent to their email
/// to complete the sign-in or account linking process.
/// {@endtemplate}
class EmailCodeVerificationPage extends StatelessWidget {
  /// {@macro email_code_verification_page}
  const EmailCodeVerificationPage({required this.email, super.key});

  /// The email address the sign-in code was sent to.
  final String email;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emailCodeSentPageTitle), // Updated l10n key
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
                  l10n.emailCodeSentConfirmation(email), // Pass email to l10n
                  style: textTheme.titleLarge, // Prominent text style
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  l10n.emailCodeSentInstructions, // New l10n key for instructions
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Input field for the 6-digit code
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: TextField(
                    // TODO(cline): Add controller and validation
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: l10n.emailCodeVerificationHint, // Add l10n key
                      border: const OutlineInputBorder(),
                      counterText: '', // Hide the counter
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Verify button
                ElevatedButton(
                  // TODO(cline): Add onPressed logic to dispatch event
                  onPressed: () {
                    // Dispatch event to AuthenticationBloc
                    // context.read<AuthenticationBloc>().add(
                    //       AuthenticationEmailCodeVerificationRequested(
                    //         email: email,
                    //         code: 'entered_code', // Get code from TextField
                    //       ),
                    //     );
                  },
                  child: Text(
                    l10n.emailCodeVerificationButtonLabel,
                  ), // Add l10n key
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
