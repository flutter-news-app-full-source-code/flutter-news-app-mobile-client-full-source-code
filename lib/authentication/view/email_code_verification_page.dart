import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_main/app/bloc/app_bloc.dart';
import 'package:ht_main/app/config/config.dart';
import 'package:ht_main/authentication/bloc/authentication_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_ui_kit/ht_ui_kit.dart';

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
    final l10n = AppLocalizationsX(context).l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.emailCodeSentPageTitle)),
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
            }
            // Successful authentication is handled by AppBloc redirecting.
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
                      Icon(
                        Icons.mark_email_read_outlined,
                        size: AppSpacing.xxl * 2,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        l10n.emailCodeSentConfirmation(email),
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.emailCodeSentInstructions,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Display demo code if in demo environment
                      BlocSelector<AppBloc, AppState, AppEnvironment?>(
                        selector: (state) => state.environment,
                        builder: (context, environment) {
                          if (environment == AppEnvironment.demo) {
                            return Column(
                              children: [
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  l10n.demoVerificationCodeMessage('123456'),
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _EmailCodeVerificationForm(
                        email: email,
                        isLoading: isLoading,
                      ),
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

class _EmailCodeVerificationForm extends StatefulWidget {
  const _EmailCodeVerificationForm({
    required this.email,
    required this.isLoading,
  });

  final String email;
  final bool isLoading;

  @override
  State<_EmailCodeVerificationForm> createState() =>
      _EmailCodeVerificationFormState();
}

class _EmailCodeVerificationFormState
    extends State<_EmailCodeVerificationForm> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthenticationBloc>().add(
        AuthenticationVerifyCodeRequested(
          email: widget.email,
          code: _codeController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            // No horizontal padding needed if column is stretched
            // padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            padding: EdgeInsets.zero,
            child: TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: l10n.emailCodeVerificationHint,
                // border: const OutlineInputBorder(),
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
              enabled: !widget.isLoading,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.emailCodeValidationEmptyError;
                }
                if (value.length != 6) {
                  return l10n.emailCodeValidationLengthError;
                }
                return null;
              },
              onFieldSubmitted: widget.isLoading ? null : (_) => _submitForm(),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.lg,
              ),
              textStyle: textTheme.labelLarge,
            ),
            onPressed: widget.isLoading ? null : _submitForm,
            child: widget.isLoading
                ? const SizedBox(
                    height: AppSpacing.xl,
                    width: AppSpacing.xl,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.emailCodeVerificationButtonLabel),
          ),
        ],
      ),
    );
  }
}
