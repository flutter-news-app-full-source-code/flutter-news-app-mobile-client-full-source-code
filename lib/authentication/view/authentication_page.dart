//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/authentication/bloc/authentication_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';

/// {@template authentication_page}
/// Displays authentication options (Google, Email, Anonymous) based on context.
///
/// This page can be used for both initial sign-in and for connecting an
/// existing anonymous account.
/// {@endtemplate}
class AuthenticationPage extends StatelessWidget {
  /// {@macro authentication_page}
  const AuthenticationPage({
    required this.headline,
    required this.subHeadline,
    required this.showAnonymousButton,
    required this.isLinkingContext,
    super.key,
  });

  /// The main title displayed on the page.
  final String headline;

  /// The descriptive text displayed below the headline.
  final String subHeadline;

  /// Whether to show the "Continue Anonymously" button.
  final bool showAnonymousButton;

  /// Whether this page is being shown in the account linking context.
  final bool isLinkingContext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Conditionally add the leading close button only in linking context
        leading: isLinkingContext
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () {
                  // Navigate back to the account page when close is pressed
                  context.goNamed(Routes.accountName);
                },
              )
            : null,
      ),
      body: SafeArea(
        child: BlocConsumer<AuthenticationBloc, AuthenticationState>(
          // Listener remains crucial for feedback (errors)
          listener: (context, state) {
            if (state is AuthenticationFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      // Provide a more user-friendly error message if possible
                      state.errorMessage,
                    ),
                    backgroundColor: colorScheme.error,
                  ),
                );
            }
            // Success states (Google/Anonymous) are typically handled by
            // the AppBloc listening to repository changes and triggering redirects.
            // Email link success is handled in the dedicated email flow pages.
          },
          builder: (context, state) {
            final isLoading = state is AuthenticationLoading;

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.paddingLarge),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Icon ---
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                        child: Icon(
                          isLinkingContext ? Icons.sync : Icons.newspaper,
                          size: AppSpacing.xxl * 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      // const SizedBox(height: AppSpacing.lg),
                      // --- Headline and Subheadline ---
                      Text(
                        headline,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        subHeadline,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // --- Email Sign-In Button ---
                      ElevatedButton.icon(
                        icon: const Icon(Icons.email_outlined),
                        onPressed: isLoading
                            ? null
                            : () {
                                context.goNamed(
                                  isLinkingContext
                                      ? Routes.linkingRequestCodeName
                                      : Routes.requestCodeName,
                                );
                              },
                        label: Text(l10n.authenticationEmailSignInButton),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          textStyle: textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // --- Anonymous Sign-In Button (Conditional) ---
                      if (showAnonymousButton) ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.person_outline),
                          onPressed: isLoading
                              ? null
                              : () => context.read<AuthenticationBloc>().add(
                                  const AuthenticationAnonymousSignInRequested(),
                                ),
                          label: Text(l10n.authenticationAnonymousSignInButton),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            textStyle: textTheme.labelLarge,
                          ),
                        ),
                      ],

                      // --- Loading Indicator ---
                      if (isLoading &&
                          state is! AuthenticationRequestCodeLoading) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.xl),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
