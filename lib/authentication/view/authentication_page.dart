import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template authentication_page}
/// Displays authentication options (Email, Anonymous) for unauthenticated users.
///
/// This page serves as the primary entry point for users who are not
/// currently logged in or have an anonymous session.
/// {@endtemplate}
class AuthenticationPage extends StatelessWidget {
  /// {@macro authentication_page}
  const AuthenticationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                          Icons.newspaper,
                          size: AppSpacing.xxl * 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      // --- Headline and Subheadline ---
                      Text(
                        l10n.authenticationSignInHeadline,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.authenticationSignInSubheadline,
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
                                context.goNamed(Routes.requestCodeName);
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

                      // --- Anonymous Sign-In Button ---
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
