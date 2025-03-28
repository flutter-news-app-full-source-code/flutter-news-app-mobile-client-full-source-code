import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';
import 'package:ht_main/account/bloc/account_linking_bloc.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Link Your Account')),
      body: BlocConsumer<AccountLinkingBloc, AccountLinkingState>(
        // Renamed Bloc and State
        listener: (context, state) {
          if (state.status == AccountLinkingStatus.failure) {
            // Renamed Status enum
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'An error occurred'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
          } else if (state.status == AccountLinkingStatus.emailLinkSent) {
            // Renamed Status enum
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Check your email for the sign-in link!'),
                ),
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
                    'Create or Link Account to Save Progress',
                    style: textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    """
                      Signing up or linking allows you to access your information 
                      across multiple devices and ensures your progress isn't lost.
                    """, // Updated text
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // --- Google Sign-In ---
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.g_mobiledata,
                    ), // Placeholder, use a Google icon asset
                    label: const Text('Continue with Google'),
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
                    decoration: const InputDecoration(
                      labelText: 'Enter your email',
                      hintText: 'you@example.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return 'Please enter a valid email address';
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
                    child: const Text('Send Sign-In Link'),
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
