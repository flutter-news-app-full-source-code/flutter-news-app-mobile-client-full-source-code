// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';
import 'package:ht_main/authentication/bloc/authentication_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/app_spacing.dart'; // Use shared constants

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
    super.key,
  });

  /// The main title displayed on the page.
  final String headline;

  /// The descriptive text displayed below the headline.
  final String subHeadline;

  /// Whether to show the "Continue Anonymously" button.
  final bool showAnonymousButton;

  @override
  Widget build(BuildContext context) {
    // Provide the BLoC here if it's not already provided higher up
    // For this refactor, assuming it's provided by the route or App setup
    return BlocProvider(
      // Ensure BLoC is created only once per instance of this page if needed
      // If BLoC needs to persist across navigations, provide it higher up.
      create: (context) => AuthenticationBloc(
        authenticationRepository: context.read<HtAuthenticationRepository>(),
      ),
      child: _AuthenticationView(
        headline: headline,
        subHeadline: subHeadline,
        showAnonymousButton: showAnonymousButton,
      ),
    );
  }
}

// Renamed from _AuthenticationView to follow convention
class _AuthenticationView extends StatelessWidget {
  const _AuthenticationView({
    required this.headline,
    required this.subHeadline,
    required this.showAnonymousButton,
  });

  final String headline;
  final String subHeadline;
  final bool showAnonymousButton;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Consider adding an AppBar if needed for context/navigation
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
                      state.errorMessage, // Or map specific errors
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
            final isLoading = state is AuthenticationLoading; // Simplified loading check

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.paddingLarge), // Use constant
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Headline and Subheadline ---
                      Text(
                        headline,
                        style: textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm), // Use constant
                      Text(
                        subHeadline,
                        style: textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl), // Use constant

                      // --- Google Sign-In Button ---
                      ElevatedButton.icon(
                        icon: const Icon(Icons.g_mobiledata), // Placeholder icon
                        label: Text(l10n.authenticationGoogleSignInButton),
                        onPressed: isLoading
                            ? null
                            : () => context.read<AuthenticationBloc>().add(
                                  const AuthenticationGoogleSignInRequested(),
                                ),
                        // Style adjustments can be made via ElevatedButtonThemeData
                      ),
                      const SizedBox(height: AppSpacing.lg), // Use constant

                      // --- Email Sign-In Button ---
                      ElevatedButton(
                        // Consider an email icon
                        // icon: const Icon(Icons.email_outlined),
                        child: Text(l10n.authenticationEmailSignInButton), // New l10n key needed
                        onPressed: isLoading
                            ? null
                            : () {
                                // Navigate to the dedicated email sign-in page
                                context.goNamed(Routes.emailSignInName);
                              },
                      ),

                      // --- Anonymous Sign-In Button (Conditional) ---
                      if (showAnonymousButton) ...[
                        const SizedBox(height: AppSpacing.lg), // Use constant
                        OutlinedButton(
                          child: Text(l10n.authenticationAnonymousSignInButton),
                          onPressed: isLoading
                              ? null
                              : () => context.read<AuthenticationBloc>().add(
                                    const AuthenticationAnonymousSignInRequested(),
                                  ),
                        ),
                      ],

                      // --- Loading Indicator (Optional, for general loading state) ---
                      // If needed, show a general loading indicator when state is AuthenticationLoading
                      if (isLoading && state is! AuthenticationLinkSending) ...[
                         const SizedBox(height: AppSpacing.xl),
                         const Center(child: CircularProgressIndicator()),
                      ]
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
