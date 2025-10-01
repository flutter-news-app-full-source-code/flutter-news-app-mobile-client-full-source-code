//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

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
    this.authContext,
    this.redirectPath,
    super.key,
  });

  /// The main title displayed on the page.
  final String headline;

  /// The descriptive text displayed below the headline.
  final String subHeadline;

  /// Whether to show the "Continue Anonymously" button.
  final bool showAnonymousButton;

  /// The context of the authentication flow (e.g., 'linking', 'limit_reached').
  final String? authContext;

  /// The path to redirect to after successful authentication or cancellation.
  final String? redirectPath;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Determine if this is a linking context based on the authContext
    final isLinkingContext = authContext == 'linking';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Conditionally add the leading close button only in linking context
        leading: (isLinkingContext || redirectPath != null)
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () {
                  // Navigate back to the redirectPath or default to the account page.
                  context.go(redirectPath ?? Routes.account);
                },
              )
            : null,
      ),
      body: SafeArea(
        child: BlocConsumer<AuthenticationBloc, AuthenticationState>(
          listener: (context, state) {
            if (state.status == AuthenticationStatus.failure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.exception!.toFriendlyMessage(context)),
                    backgroundColor: colorScheme.error,
                  ),
                );
            }
          },
          builder: (context, state) {
            final isLoading = state.status == AuthenticationStatus.loading;

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
                                  queryParameters: {
                                    if (authContext != null)
                                      'authContext': authContext,
                                    if (redirectPath != null)
                                      'redirectPath': redirectPath,
                                  },
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
                      if (isLoading) ...[
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
