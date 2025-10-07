import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template account_linking_page}
/// Displays options for an anonymous user to link their account to an email.
///
/// {@endtemplate}
class AccountLinkingPage extends StatelessWidget {
  /// {@macro account_linking_page}
  const AccountLinkingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountLinkingHeadline)),
      body: BlocConsumer<AuthenticationBloc, AuthenticationState>(
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      child: Icon(
                        Icons.sync,
                        size: AppSpacing.xxl * 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      l10n.accountLinkingHeadline,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.accountLinkingBody,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.email_outlined),
                      onPressed: isLoading
                          ? null
                          : () {
                              context.pushNamed(
                                Routes.accountLinkingRequestCodeName,
                              );
                            },
                      label: Text(l10n.accountLinkingSendLinkButton),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        textStyle: textTheme.labelLarge,
                      ),
                    ),
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
    );
  }
}
