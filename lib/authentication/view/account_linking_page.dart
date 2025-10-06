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
/// This page is presented as a modal bottom sheet, allowing the previous
/// page to remain visible underneath and providing a dismissible experience.
/// {@endtemplate}
class AccountLinkingPage extends StatelessWidget {
  /// {@macro account_linking_page}
  const AccountLinkingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // GestureDetector allows dismissing the modal by tapping the scrim.
    return GestureDetector(
      onTap: () => context.pop(),
      child: Scaffold(
        // A transparent background is crucial for the modal effect.
        backgroundColor: Colors.transparent,
        // The DraggableScrollableSheet provides the bottom sheet behavior.
        body: DraggableScrollableSheet(
          // The initial height of the bottom sheet (approx 2/3 of the screen).
          initialChildSize: 0.66,
          // The minimum height the sheet can be dragged down to before dismissing.
          minChildSize: 0.4,
          // The maximum height the sheet can be dragged up to.
          maxChildSize: 0.9,
          expand: false, // Do not expand to full screen by default
          builder: (BuildContext context, ScrollController scrollController) {
            // A second GestureDetector prevents the inner content taps from
            // bubbling up and closing the modal.
            return GestureDetector(
              onTap: () {}, // Absorb taps within the sheet
              child: Container(
                // Apply styling for the bottom sheet container.
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // --- Drag Handle ---
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(
                            child: Container(
                              height: 4,
                              width: 40,
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        // --- Main Content ---
                        Expanded(
                          child: BlocConsumer<AuthenticationBloc,
                              AuthenticationState>(
                            listener: (context, state) {
                              if (state.status ==
                                  AuthenticationStatus.failure) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        state.exception!
                                            .toFriendlyMessage(context),
                                      ),
                                      backgroundColor: colorScheme.error,
                                    ),
                                  );
                              }
                            },
                            builder: (context, state) {
                              final isLoading =
                                  state.status == AuthenticationStatus.loading;

                              return Padding(
                                padding: const EdgeInsets.all(
                                  AppSpacing.paddingLarge,
                                ),
                                child: Center(
                                  child: SingleChildScrollView(
                                    // Link the scroll controller to enable dragging the sheet.
                                    controller: scrollController,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // --- Icon ---
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: AppSpacing.xl,
                                          ),
                                          child: Icon(
                                            Icons.sync,
                                            size: AppSpacing.xxl * 2,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        // --- Headline and Subheadline ---
                                        Text(
                                          l10n.accountLinkingHeadline,
                                          style: textTheme.headlineMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        Text(
                                          l10n.accountLinkingBody,
                                          style: textTheme.bodyLarge?.copyWith(
                                            color:
                                                colorScheme.onSurfaceVariant,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: AppSpacing.xxl),

                                        // --- Email Linking Button ---
                                        ElevatedButton.icon(
                                          icon:
                                              const Icon(Icons.email_outlined),
                                          onPressed: isLoading
                                              ? null
                                              : () {
                                                  // Navigate to the request code page for linking.
                                                  context.goNamed(
                                                    Routes
                                                        .accountLinkingRequestCodeName,
                                                  );
                                                },
                                          label: Text(
                                            l10n.accountLinkingSendLinkButton,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              vertical: AppSpacing.md,
                                            ),
                                            textStyle: textTheme.labelLarge,
                                          ),
                                        ),

                                        // --- Loading Indicator ---
                                        if (isLoading) ...[
                                          const Padding(
                                            padding: EdgeInsets.only(
                                              top: AppSpacing.xl,
                                            ),
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    // --- Close Button ---
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () {
                          // Dismiss the modal bottom sheet.
                          context.pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
