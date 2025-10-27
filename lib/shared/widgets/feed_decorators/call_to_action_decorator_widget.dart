import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template call_to_action_decorator_widget}
/// A widget to display a call-to-action feed decorator.
///
/// This widget presents a card with a title, description, and a call-to-action
/// button.
/// It now includes a dismiss option in a popup menu.
/// {@endtemplate}
class CallToActionDecoratorWidget extends StatelessWidget {
  /// {@macro call_to_action_decorator_widget}
  const CallToActionDecoratorWidget({
    required this.item,
    required this.onCallToAction,
    this.onDismiss,
    super.key,
  });

  /// The [CallToActionItem] to display.
  final CallToActionItem item;

  /// Callback function when the call-to-action button is pressed.
  final ValueSetter<String> onCallToAction;

  /// An optional callback that is triggered when the user dismisses the
  /// decorator.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.description,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () => onCallToAction(item.callToActionUrl),
                    child: Text(item.callToActionText),
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: PopupMenuButton<void>(
                icon: const Icon(Icons.more_vert),
                tooltip: l10n.manageFiltersDeleteTooltip,
                onSelected: (_) => onDismiss!(),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<void>(
                    value: null,
                    // TODO(fulleni): Replace with a localized string.
                    child: Text(l10n.savedFiltersMenuDelete),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
