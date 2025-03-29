import 'package:flutter/material.dart';
import 'package:ht_main/shared/constants/app_spacing.dart'; // Assuming spacing constants exist

/// A simple splash screen displayed during app initialization.
class SplashPage extends StatelessWidget {
  /// Creates a [SplashPage].
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Center(
        child: Padding(
          // Add horizontal padding for content safety
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
          ), // Corrected constant
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon representing news/articles
              Icon(
                Icons.article_outlined,
                size: 64,
                color: colorScheme.primary, // Use primary theme color
              ),
              const SizedBox(height: AppSpacing.xl), // Use defined spacing
              // App Title
              Text(
                'Headlines Toolkit', // App Name
                style: textTheme.headlineMedium, // Use theme text style
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md), // Use defined spacing
              // Subheadline/Tagline
              Text(
                'Develop News Headlines Apps Rapidly & Reliably.', // Tagline
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.secondary, // Use secondary theme color
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
