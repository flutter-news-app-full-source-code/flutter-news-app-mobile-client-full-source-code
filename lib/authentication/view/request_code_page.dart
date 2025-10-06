//
// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template request_code_page}
/// Page for initiating the email code sign-in process.
/// Explains the passwordless flow and collects the user's email to send a
/// verification code.
/// {@endtemplate}
class RequestCodePage extends StatelessWidget {
  /// {@macro request_code_page}
  const RequestCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthenticationBloc is assumed to be provided by a parent route.
    return const _RequestCodeView();
  }
}

class _RequestCodeView extends StatelessWidget {
  const _RequestCodeView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emailSignInPageTitle),
        // Add a custom leading back button to control navigation based on context.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            // Navigate back to the previous page in the stack.
            // GoRouter will handle the correct navigation based on the current
            // route's parent.
            context.pop();
          },
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
              // Navigate to the code verification page on success, passing the email.
              // The current route's parent will determine if this is for linking
              // or standard authentication.
              final currentRouteName = GoRouter.of(context).routerDelegate.currentConfiguration.last.route.name;
              if (currentRouteName == Routes.accountLinkingRequestCodeName) {
                context.goNamed(Routes.accountLinkingVerifyCodeName, pathParameters: {'email': state.email!});
              } else {
                context.goNamed(Routes.verifyCodeName, pathParameters: {'email': state.email!});
              }
            }
          },
          // BuildWhen prevents unnecessary rebuilds if only listening
          buildWhen: (previous, current) => previous.status != current.status,
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
                          Icons.email_outlined,
                          size: AppSpacing.xxl * 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      // const SizedBox(height: AppSpacing.lg),
                      // --- Explanation Text ---
                      Text(
                        l10n.requestCodePageHeadline,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.requestCodePageSubheadline,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
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
