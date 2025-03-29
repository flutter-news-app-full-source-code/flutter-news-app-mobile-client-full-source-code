import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ht_main/authentication/bloc/authentication_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/router/routes.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';

/// {@template email_sign_in_page}
/// Page for initiating the email link sign-in process.
/// Explains the passwordless flow and collects the user's email.
/// {@endtemplate}
class EmailSignInPage extends StatelessWidget {
  /// {@macro email_sign_in_page}
  const EmailSignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming AuthenticationBloc is provided by the parent route (AuthenticationPage)
    // If not, it needs to be provided here or higher up.
    return const _EmailSignInView();
  }
}

class _EmailSignInView extends StatelessWidget {
  const _EmailSignInView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emailSignInPageTitle), // New l10n key needed
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
            } else if (state is AuthenticationLinkSentSuccess) {
              // Navigate to the confirmation page on success
              context.goNamed(Routes.emailLinkSentName);
            }
          },
          // BuildWhen prevents unnecessary rebuilds if only listening
          buildWhen: (previous, current) =>
              current is AuthenticationInitial ||
              current is AuthenticationLinkSending ||
              current is AuthenticationFailure, // Rebuild on failure to re-enable form
          builder: (context, state) {
            final isLoading = state is AuthenticationLinkSending;

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.paddingLarge),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.emailSignInExplanation, // New l10n key needed
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
            AuthenticationSendSignInLinkRequested(
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
              labelText: l10n.authenticationEmailLabel, // Re-use existing key
              border: const OutlineInputBorder(),
              // Consider adding hint text if needed
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            enabled: !widget.isLoading,
            validator: (value) {
              if (value == null || value.isEmpty || !value.contains('@')) {
                // Add a specific validation error message key if needed
                return l10n.accountLinkingEmailValidationError; // Re-use for now
              }
              return null;
            },
            onFieldSubmitted: (_) => _submitForm(), // Allow submitting from keyboard
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: widget.isLoading ? null : _submitForm,
            child: widget.isLoading
                ? const SizedBox(
                    height: 24, // Consistent height
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.authenticationSendLinkButton), // Re-use existing key
          ),
        ],
      ),
    );
  }
}
