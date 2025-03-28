//
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';
import 'package:ht_main/authentication/bloc/authentication_bloc.dart';
import 'package:ht_main/l10n/l10n.dart'; // Added import

class AuthenticationPage extends StatelessWidget {
  const AuthenticationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => AuthenticationBloc(
            authenticationRepository:
                context.read<HtAuthenticationRepository>(),
          ),
      child: _AuthenticationView(),
    );
  }
}

class _AuthenticationView extends StatefulWidget {
  @override
  __AuthenticationViewState createState() => __AuthenticationViewState();
}

class __AuthenticationViewState extends State<_AuthenticationView> {
  final _emailController = TextEditingController();
  // Removed password controller

  @override
  void dispose() {
    _emailController.dispose();
    // Removed password controller disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use BlocConsumer to listen for state changes for side effects (SnackBar)
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthenticationBloc, AuthenticationState>(
          listener: (context, state) {
            if (state is AuthenticationFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
            } else if (state is AuthenticationLinkSentSuccess) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.authenticationEmailSentSuccess),
                  ),
                );
              // Optionally clear email field or navigate
            }
          },
          builder: (context, state) {
            // Determine if loading indicator should be shown
            final isLoading =
                state is AuthenticationLoading ||
                state is AuthenticationLinkSending;
            final l10n = context.l10n; // Added l10n variable

            return Padding(
              padding: const EdgeInsets.all(16), // Use AppSpacing later
              child: Center(
                // Center content vertically
                child: SingleChildScrollView(
                  // Allow scrolling if needed
                  child: Column(
                    // Use CrossAxisAlignment.stretch for full-width buttons
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.authenticationPageTitle,
                        style:
                            Theme.of(
                              context,
                            ).textTheme.headlineMedium, // Use theme typography
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32), // Use AppSpacing later
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: l10n.authenticationEmailLabel,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction:
                            TextInputAction.done, // Improve keyboard action
                        enabled: !isLoading, // Disable field when loading
                      ),
                      // Removed Password Field
                      const SizedBox(height: 32), // Use AppSpacing later
                      // Show loading indicator within the button if sending link
                      ElevatedButton(
                        onPressed:
                            isLoading // Disable button when loading
                                ? null
                                : () {
                                  context.read<AuthenticationBloc>().add(
                                    AuthenticationSendSignInLinkRequested(
                                      email:
                                          _emailController.text
                                              .trim(), // Trim whitespace
                                    ),
                                  );
                                },
                        child:
                            state is AuthenticationLinkSending
                                ? const SizedBox(
                                  // Consistent height loading indicator
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(l10n.authenticationSendLinkButton),
                      ),
                      const SizedBox(height: 16), // Use AppSpacing later
                      // Add divider for clarity
                      Row(
                        // Removed const
                        children: [
                          const Expanded(
                            child: Divider(),
                          ), // Added const back here
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(l10n.authenticationOrDivider),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16), // Use AppSpacing later
                      ElevatedButton(
                        // Removed duplicate onPressed here
                        // Style adjustments for Google button might be needed via Theme
                        onPressed:
                            isLoading // Disable button when loading
                                ? null
                                : () {
                                  context.read<AuthenticationBloc>().add(
                                    const AuthenticationGoogleSignInRequested(),
                                  );
                                },
                        // Consider adding Google icon
                        child: Text(l10n.authenticationGoogleSignInButton),
                      ),
                      const SizedBox(height: 16), // Use AppSpacing later
                      OutlinedButton(
                        // Use OutlinedButton for less emphasis
                        onPressed:
                            isLoading // Disable button when loading
                                ? null
                                : () {
                                  context.read<AuthenticationBloc>().add(
                                    const AuthenticationAnonymousSignInRequested(),
                                  );
                                },
                        child: Text(l10n.authenticationAnonymousSignInButton),
                      ),
                    ],
                  ), // Column
                ), // SingleChildScrollView
              ), // Center
            ); // Padding
          },
        ), // BlocConsumer
      ), // SafeArea
    ); // Scaffold
  }
}
