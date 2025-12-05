import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart' hide UiKitLocalizations;

/// {@template content_limitation_bottom_sheet}
/// A bottom sheet that informs the user about content limitations and provides
/// relevant actions based on their status.
/// {@endtemplate}
class ContentLimitationBottomSheet extends StatefulWidget {
  /// {@macro content_limitation_bottom_sheet}
  const ContentLimitationBottomSheet({
    required this.title,
    required this.body,
    required this.buttonText,
    this.onButtonPressed,
    super.key,
  });

  /// The title of the bottom sheet.
  final String title;

  /// The body text of the bottom sheet.
  final String body;

  /// The text for the action button.
  final String buttonText;

  /// The callback executed when the action button is pressed.
  final VoidCallback? onButtonPressed;

  @override
  State<ContentLimitationBottomSheet> createState() =>
      _ContentLimitationBottomSheetState();
}

class _ContentLimitationBottomSheetState
    extends State<ContentLimitationBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.paddingLarge),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              size: AppSpacing.xxl * 1.5,
              color: colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.title,
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.body,
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: widget.onButtonPressed,
              child: Text(widget.buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
