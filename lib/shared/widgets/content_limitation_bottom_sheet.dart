import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart' hide UiKitLocalizations;

/// {@template content_limitation_bottom_sheet}
/// A bottom sheet that informs the user about content limitations and provides
/// relevant actions based on their status.
/// {@endtemplate}
class ContentLimitationBottomSheet extends StatelessWidget {
  /// {@macro content_limitation_bottom_sheet}
  const ContentLimitationBottomSheet({required this.status, super.key});

  /// The limitation status that determines the content of the bottom sheet.
  final LimitationStatus status;

  @override
  Widget build(BuildContext context) {
    // Use a switch to build the appropriate view based on the status.
    // Each case returns a dedicated private widget for clarity.
    switch (status) {
      case LimitationStatus.anonymousLimitReached:
        return const _AnonymousLimitView();
      case LimitationStatus.standardUserLimitReached:
        return const _StandardUserLimitView();
      case LimitationStatus.premiumUserLimitReached:
        return const _PremiumUserLimitView();
      case LimitationStatus.allowed:
        // If the action is allowed, no UI is needed.
        return const SizedBox.shrink();
    }
  }
}

/// A private widget to show when an anonymous user hits a limit.
class _AnonymousLimitView extends StatelessWidget {
  const _AnonymousLimitView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    return _BaseLimitView(
      icon: Icons.person_add_alt_1_outlined,
      title: l10n.anonymousLimitTitle,
      body: l10n.anonymousLimitBody,
      child: ElevatedButton(
        onPressed: () {
          // Pop the bottom sheet first.
          Navigator.of(context).pop();
          // Then navigate to the account linking page.
          context.pushNamed(Routes.accountLinkingName);
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.xxl + AppSpacing.sm),
        ),
        child: Text(l10n.anonymousLimitButton),
      ),
    );
  }
}

/// A private widget to show when a standard (free) user hits a limit.
class _StandardUserLimitView extends StatelessWidget {
  const _StandardUserLimitView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    return _BaseLimitView(
      icon: Icons.workspace_premium_outlined,
      title: l10n.standardLimitTitle,
      body: l10n.standardLimitBody,
      child: ElevatedButton(
        // TODO(fulleni): Implement account upgrade flow.
        // The upgrade flow is not yet implemented, so the button is disabled.
        onPressed: null,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.xxl + AppSpacing.sm),
        ),
        child: Text(l10n.standardLimitButton),
      ),
    );
  }
}

/// A private widget to show when a premium user hits a limit.
class _PremiumUserLimitView extends StatelessWidget {
  const _PremiumUserLimitView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    final theme = Theme.of(context);

    return _BaseLimitView(
      icon: Icons.inventory_2_outlined,
      title: l10n.premiumLimitTitle,
      body: l10n.premiumLimitBody,
      child: ElevatedButton(
        onPressed: () {
          // Pop the bottom sheet first.
          Navigator.of(context).pop();
          // Then navigate to the page for managing followed items.
          context.goNamed(Routes.manageFollowedItemsName);
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.xxl + AppSpacing.sm),
        ),
        child: Text(l10n.premiumLimitButton),
      ),
    );
  }
}

/// A base layout for the content limitation views to reduce duplication.
class _BaseLimitView extends StatelessWidget {
  const _BaseLimitView({
    required this.icon,
    required this.title,
    required this.body,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.paddingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.xxl * 1.5, color: colorScheme.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(body, style: textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
