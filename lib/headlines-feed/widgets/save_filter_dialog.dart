import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template save_filter_dialog}
/// A dialog for naming or renaming a saved filter.
///
/// Includes a text field for the name and validates for non-empty and
/// max length constraints.
/// {@endtemplate}
class SaveFilterDialog extends StatefulWidget {
  /// {@macro save_filter_dialog}
  const SaveFilterDialog({required this.onSave, this.initialValue, super.key});

  /// The initial value to populate the text field with, used for renaming.
  final String? initialValue;

  /// The callback function executed when the "Save" button is pressed and
  /// the form is valid. It provides the new name.
  final ValueChanged<String> onSave;

  @override
  State<SaveFilterDialog> createState() => _SaveFilterDialogState();
}

class _SaveFilterDialogState extends State<SaveFilterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  static const _maxNameLength = 25;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(_controller.text.trim());
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final isRenaming = widget.initialValue != null;

    return AlertDialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      title: Text(
        isRenaming
            ? l10n.saveFilterDialogTitleRename
            : l10n.saveFilterDialogTitleSave,
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: _maxNameLength,
          decoration: InputDecoration(
            labelText: l10n.saveFilterDialogInputLabel,
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.saveFilterDialogValidationEmpty;
            }
            if (value.length > _maxNameLength) {
              return l10n.saveFilterDialogValidationTooLong;
            }
            return null;
          },
          onFieldSubmitted: (_) => _submitForm(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButtonLabel),
        ),
        FilledButton(onPressed: _submitForm, child: Text(l10n.saveButtonLabel)),
      ],
    );
  }
}
