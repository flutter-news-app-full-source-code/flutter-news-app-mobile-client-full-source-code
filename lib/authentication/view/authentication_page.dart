import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';
import 'package:ht_main/authentication/bloc/authentication_bloc.dart';

class AuthenticationPage extends StatelessWidget {
  const AuthenticationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthenticationBloc(
        authenticationRepository: context.read<HtAuthenticationRepository>(),
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
                  const SnackBar(
                    content: Text('Check your email for the sign-in link.'),
                  ),
                );
              // Optionally clear email field or navigate
            }
          },
          builder: (context, state) {
            // Determine if loading indicator should be shown
            final isLoading = state is AuthenticationLoading ||
                state is AuthenticationLinkSending;

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
                        'Sign In / Register', // Updated title
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium, // Use theme typography
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32), // Use AppSpacing later
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email', // Needs localization
                          border: OutlineInputBorder(),
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
                        onPressed: isLoading // Disable button when loading
                            ? null
                            : () {
                                context.read<AuthenticationBloc>().add(
                                      AuthenticationSendSignInLinkRequested(
                                        email: _emailController.text
                                            .trim(), // Trim whitespace
                                      ),
                                    );
                              },
                        child: state is AuthenticationLinkSending
                            ? const SizedBox(
                                // Consistent height loading indicator
                                height: 24,
                                width: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Send Sign-In Link'), // Needs localization
                      ),
                      const SizedBox(height: 16), // Use AppSpacing later
                      // Add divider for clarity
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('OR'), // Needs localization
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16), // Use AppSpacing later
                      ElevatedButton(
                        // Removed duplicate onPressed here
                        // Style adjustments for Google button might be needed via Theme
                        onPressed: isLoading // Disable button when loading
                            ? null
                            : () {
                                context.read<AuthenticationBloc>().add(
                                    const AuthenticationGoogleSignInRequested());
                              },
                        // Consider adding Google icon
                        child: const Text(
                            'Sign In with Google'), // Needs localization
                      ),
                      const SizedBox(height: 16), // Use AppSpacing later
                      OutlinedButton(
                        // Use OutlinedButton for less emphasis
                        onPressed: isLoading // Disable button when loading
                            ? null
                            : () {
                                context.read<AuthenticationBloc>().add(
                                      const AuthenticationAnonymousSignInRequested(),
                                    );
                              },
                        child: const Text(
                            'Continue Anonymously'), // Needs localization
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
