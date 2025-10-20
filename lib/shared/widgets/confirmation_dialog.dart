import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';

/// {@template confirmation_dialog}
/// A reusable dialog for asking the user to confirm an action.
///
/// Returns `true` if the user confirms the action, otherwise returns `false`
/// or `null` if dismissed.
/// {@endtemplate}
class ConfirmationDialog extends StatelessWidget {
  /// {@macro confirmation_dialog}
  const ConfirmationDialog({
    required this.title,
    required this.content,
    required this.confirmButtonText,
    super.key,
  });

  /// The title of the dialog.
  final String title;

  /// The main content/body of the dialog.
  final String content;

  /// The text to display on the confirmation button.
  final String confirmButtonText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;

    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmButtonText),
        ),
      ],
    );
  }
}
