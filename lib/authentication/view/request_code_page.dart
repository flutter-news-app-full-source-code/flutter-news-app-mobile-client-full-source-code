//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/authentication/bloc/authentication_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';

/// {@template request_code_page}
/// Page for initiating the email code sign-in process.
/// Explains the passwordless flow and collects the user's email to send a
/// verification code.
/// {@endtemplate}
class RequestCodePage extends StatelessWidget {
  /// {@macro request_code_page}
  const RequestCodePage({
    required this.isLinkingContext, // Accept the flag
    super.key,
  });

  /// Whether this page is being shown in the account linking context.
  final bool isLinkingContext;

  @override
  Widget build(BuildContext context) {
    // AuthenticationBloc is assumed to be provided by a parent route.
    // Pass the linking context flag down to the view.
    return _RequestCodeView(isLinkingContext: isLinkingContext);
  }
}

class _RequestCodeView extends StatelessWidget {
  // Accept the flag from the parent page.
  const _RequestCodeView({required this.isLinkingContext});

  final bool isLinkingContext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emailSignInPageTitle),
        // Add a custom leading back button to control navigation based on context.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip:
              MaterialLocalizations.of(
                context,
              ).backButtonTooltip, // Accessibility
          onPressed: () {
            // Navigate back differently based on the context.
            if (isLinkingContext) {
              // If linking, go back to Auth page preserving the linking query param.
              context.goNamed(
                Routes.authenticationName,
                queryParameters: {'context': 'linking'},
              );
            } else {
              // If normal sign-in, just go back to the Auth page.
              context.goNamed(Routes.authenticationName);
            }
          },
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<AuthenticationBloc, AuthenticationState>(
          listener: (context, state) {
            if (state is AuthenticationFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage),
                    backgroundColor: colorScheme.error,
                  ),
                );
            } else if (state is AuthenticationCodeSentSuccess) {
              // Navigate to the code verification page on success, passing the email
              context.goNamed(
                Routes.verifyCodeName,
                pathParameters: {'email': state.email},
              );
            }
          },
          // BuildWhen prevents unnecessary rebuilds if only listening
          buildWhen:
              (previous, current) =>
                  current is AuthenticationInitial ||
                  current is AuthenticationRequestCodeLoading ||
                  current
                      is AuthenticationFailure, // Rebuild on failure to re-enable form
          builder: (context, state) {
            final isLoading = state is AuthenticationRequestCodeLoading;

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.paddingLarge),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Hardcoded Icon ---
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.xl,
                        ), // Spacing below icon
                        child: Icon(
                          Icons.email_outlined, // Hardcoded icon
                          size:
                              (Theme.of(context).iconTheme.size ??
                                  AppSpacing.xl) *
                              3.0,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(
                        height: AppSpacing.lg,
                      ), // Space between icon and text
                      // --- Explanation Text ---
                      Text(
                        l10n.emailSignInExplanation,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _EmailLinkForm(isLoading: isLoading),
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

/// --- Reusable Email Form Widget --- ///

class _EmailLinkForm extends StatefulWidget {
  const _EmailLinkForm({required this.isLoading});

  final bool isLoading;

  @override
  State<_EmailLinkForm> createState() => _EmailLinkFormState();
}

class _EmailLinkFormState extends State<_EmailLinkForm> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthenticationBloc>().add(
        AuthenticationRequestSignInCodeRequested(
          email: _emailController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: l10n.authenticationEmailLabel,
              border: const OutlineInputBorder(),
              // Consider adding hint text if needed
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            enabled: !widget.isLoading,
            validator: (value) {
              if (value == null || value.isEmpty || !value.contains('@')) {
                return l10n.accountLinkingEmailValidationError;
              }
              return null;
            },
            onFieldSubmitted:
                (_) => _submitForm(), // Allow submitting from keyboard
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: widget.isLoading ? null : _submitForm,
            child:
                widget.isLoading
                    ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(l10n.authenticationSendLinkButton),
          ),
        ],
      ),
    );
  }
}
