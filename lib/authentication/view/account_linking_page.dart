import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template account_linking_page}
/// A modal bottom sheet page for anonymous users to link their account
/// to an email address.
///
/// This page provides a less intrusive way for users to upgrade their
/// anonymous session to a permanent, authenticated account.
/// {@endtemplate}
class AccountLinkingPage extends StatelessWidget {
  /// {@macro account_linking_page}
  const AccountLinkingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountLinkingPageTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => context.pop(),
        ),
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
            } else if (state.status ==
                AuthenticationStatus.requestCodeSuccess) {
              // Navigate to the code verification page on success, passing the email
              context.pushNamed(
                Routes.verifyCodeName, // Use the non-linking verify code route
                pathParameters: {'email': state.email!},
              );
            }
          },
          builder: (context, state) {
            final isLoading =
                state.status == AuthenticationStatus.requestCodeInProgress;

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
                          Icons.link_outlined,
                          size: AppSpacing.xxl * 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      // --- Headline and Subheadline ---
                      Text(
                        l10n.accountLinkingPageHeadline,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.accountLinkingPageSubheadline,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // --- Email Link Form ---
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

/// --- Reusable Email Form Widget (Copied from request_code_page.dart) --- ///

class _EmailLinkForm extends StatefulWidget {
  const _EmailLinkForm({required this.isLoading});

  final bool isLoading;

  @override
  State<_EmailLinkForm> createState() => _EmailLinkFormState();
}

class _EmailLinkFormState extends State<_EmailLinkForm> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthenticationBloc>().state;
    if (authState.cooldownEndTime != null &&
        authState.cooldownEndTime!.isAfter(DateTime.now())) {
      _startCooldownTimer(authState.cooldownEndTime!);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer(DateTime endTime) {
    final now = DateTime.now();
    if (now.isBefore(endTime)) {
      setState(() {
        _cooldownSeconds = endTime.difference(now).inSeconds;
      });
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final remaining = endTime.difference(DateTime.now()).inSeconds;
        if (remaining > 0) {
          setState(() {
            _cooldownSeconds = remaining;
          });
        } else {
          timer.cancel();
          setState(() {
            _cooldownSeconds = 0;
          });
        }
      });
    }
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
    final l10n = AppLocalizationsX(context).l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listenWhen: (previous, current) =>
          previous.cooldownEndTime != current.cooldownEndTime,
      listener: (context, state) {
        if (state.cooldownEndTime != null &&
            state.cooldownEndTime!.isAfter(DateTime.now())) {
          _cooldownTimer?.cancel();
          _startCooldownTimer(state.cooldownEndTime!);
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.requestCodeEmailLabel,
                hintText: l10n.requestCodeEmailHint,
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              enabled: !widget.isLoading && _cooldownSeconds == 0,
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return l10n.accountLinkingEmailValidationError;
                }
                return null;
              },
              onFieldSubmitted: widget.isLoading || _cooldownSeconds > 0
                  ? null
                  : (_) => _submitForm(),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: widget.isLoading || _cooldownSeconds > 0
                  ? null
                  : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                textStyle: textTheme.labelLarge,
              ),
              child: widget.isLoading
                  ? SizedBox(
                      height: AppSpacing.xl,
                      width: AppSpacing.xl,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : _cooldownSeconds > 0
                  ? Text(l10n.requestCodeResendButtonCooldown(_cooldownSeconds))
                  : Text(l10n.requestCodeSendCodeButton),
            ),
          ],
        ),
      ),
    );
  }
}
