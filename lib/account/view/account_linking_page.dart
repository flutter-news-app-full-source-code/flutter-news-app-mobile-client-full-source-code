import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';
import 'package:ht_main/account/bloc/account_linking_bloc.dart';
import 'package:ht_main/l10n/l10n.dart'; // Added import

/// {@template account_linking_page} // Renamed template
/// Page widget for the Account Linking feature.
/// Provides the [AccountLinkingBloc] to its descendants.
/// {@endtemplate}
class AccountLinkingPage extends StatelessWidget {
  // Renamed class
  /// {@macro account_linking_page}
  const AccountLinkingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => AccountLinkingBloc(
            authenticationRepository:
                context.read<HtAuthenticationRepository>(),
          ),
      child: const _AccountLinkingView(),
    );
  }
}

/// {@template account_linking_view}
/// Displays information about linking an account
/// and provides options to sign in/link using different methods.
/// {@endtemplate}
class _AccountLinkingView extends StatefulWidget {
  // Renamed class
  /// {@macro account_linking_view}
  const _AccountLinkingView();

  @override
  State<_AccountLinkingView> createState() => _AccountLinkingViewState();
}

class _AccountLinkingViewState extends State<_AccountLinkingView> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountLinkingPageTitle)),
      body: BlocConsumer<AccountLinkingBloc, AccountLinkingState>(
        listener: (context, state) {
          if (state.status == AccountLinkingStatus.failure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage ?? l10n.accountLinkingGenericError,
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
          } else if (state.status == AccountLinkingStatus.emailLinkSent) {
            // Renamed Status enum
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.accountLinkingEmailSentSuccess)),
              );
            // Optionally clear email field or navigate away
            _emailController.clear();
          }
          // Success state is handled by global AppBloc redirect
        },
        builder: (context, state) {
          final isLoading = state.status == AccountLinkingStatus.loading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.accountLinkingHeadline,
                    style: textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.accountLinkingBody,
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // --- Google Sign-In ---
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.g_mobiledata,
                    ), // Placeholder, use a Google icon asset
                    label: Text(l10n.accountLinkingContinueWithGoogleButton),
                    onPressed:
                        isLoading
                            ? null
                            : () => context.read<AccountLinkingBloc>().add(
                              const AccountLinkingGoogleSignInRequested(),
                            ),
                    // Add Google specific styling if desired
                  ),
                  const SizedBox(height: 16),

                  // --- Email Link Sign-In ---
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: l10n.accountLinkingEmailInputLabel,
                      hintText: l10n.accountLinkingEmailInputHint,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return l10n.accountLinkingEmailValidationError;
                      }
                      return null;
                    },
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AccountLinkingBloc>().add(
                                  AccountLinkingEmailLinkSignInRequested(
                                    email: _emailController.text.trim(),
                                  ),
                                );
                              }
                            },
                    child: Text(l10n.accountLinkingSendLinkButton),
                  ),

                  // --- Loading Indicator ---
                  if (isLoading) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],

                  // Add other sign-in methods (Apple, etc.) if needed
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
