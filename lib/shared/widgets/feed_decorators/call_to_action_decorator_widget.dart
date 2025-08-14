import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template call_to_action_decorator_widget}
/// A widget to display a call-to-action feed decorator.
///
/// This widget presents a card with a title, description, and a call-to-action
/// button. It also includes a dismiss option via a [PopupMenuButton].
/// {@endtemplate}
class CallToActionDecoratorWidget extends StatelessWidget {
  /// {@macro call_to_action_decorator_widget}
  const CallToActionDecoratorWidget({
    required this.item,
    required this.onCallToAction,
    required this.onDismiss,
    super.key,
  });

  /// The [CallToActionItem] to display.
  final CallToActionItem item;

  /// Callback function when the call-to-action button is pressed.
  final ValueSetter<String> onCallToAction;

  /// Callback function when the dismiss option is selected.
  final ValueSetter<FeedDecoratorType> onDismiss;

  @override
  Widget build(BuildContext context) {
    // final l10n = context.l10n;
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: theme.textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'dismiss') {
                      onDismiss(item.decoratorType);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'dismiss',
                      child: Text(l10n.neverShowAgain),
                    ),
                  ],
                ),
              ],
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
    );
  }
}
