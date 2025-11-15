import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template save_filter_dialog}
/// A dialog for naming or renaming a saved filter.
///
/// Includes a text field for the name and validates for non-empty and
/// max length constraints.
/// {@endtemplate}
class SaveFilterDialog extends StatefulWidget {
  /// {@macro save_filter_dialog}
  const SaveFilterDialog({required this.onSave, this.filterToEdit, super.key});

  /// An optional existing filter passed when in 'edit' mode.
  /// This is used to pre-populate the dialog's fields.
  final SavedHeadlineFilter? filterToEdit;

  /// The callback function executed when the "Save" button is pressed and
  /// the form is valid. It provides the new name, pinned status, and
  /// selected notification delivery types.
  final ValueChanged<
    ({
      String name,
      bool isPinned,
      Set<PushNotificationSubscriptionDeliveryType> deliveryTypes,
    })
  >
  onSave;

  @override
  State<SaveFilterDialog> createState() => _SaveFilterDialogState();
}

class _SaveFilterDialogState extends State<SaveFilterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late bool _isPinned;
  late Set<PushNotificationSubscriptionDeliveryType> _selectedDeliveryTypes;

  // Flags to control the enabled state of UI elements based on limits.
  bool _canPin = true;
  bool _canSubscribe = true;

  static const _maxNameLength = 15;

  @override
  void initState() {
    super.initState();
    final filter = widget.filterToEdit;
    _controller = TextEditingController(text: filter?.name);
    _isPinned = filter?.isPinned ?? false;
    _selectedDeliveryTypes = filter?.deliveryTypes ?? {};

    // Check content limitations when the dialog is initialized.
    // This will be used to disable UI elements if the user has reached a limit.
    // Note: The ContentActions used here will be implemented in a subsequent step.
    final contentLimitationService = context.read<ContentLimitationService>();
    _canPin =
        contentLimitationService.checkAction(
          // This action will be fully implemented in the next step.
          ContentAction.pinHeadlineFilter,
        ) ==
        LimitationStatus.allowed;

    _canSubscribe =
        contentLimitationService.checkAction(
          // This action will be fully implemented in the next step.
          ContentAction.subscribeToHeadlineFilterNotifications,
        ) ==
        LimitationStatus.allowed;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSave((
        name: _controller.text.trim(),
        isPinned: _isPinned,
        deliveryTypes: _selectedDeliveryTypes,
      ));
      // Pop the dialog and return `true` to signal to the caller that the
      // save operation was successfully initiated. This allows the caller
      // to coordinate subsequent navigation actions, preventing race conditions.
      Navigator.of(context).pop(true); // Return true on success.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final isEditing = widget.filterToEdit != null;
    final pushNotificationConfig = context
        .select((AppBloc bloc) => bloc.state.remoteConfig)
        ?.pushNotificationConfig;

    return AlertDialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      title: Text(
        isEditing
            ? l10n.saveFilterDialogTitleRename
            : l10n.saveFilterDialogTitleSave,
      ),
      // Use a SingleChildScrollView to prevent overflow on smaller screens.
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
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
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                title: Text(l10n.saveFilterDialogPinToFeedLabel),
                value: _isPinned,
                onChanged: _canPin
                    ? (value) => setState(() => _isPinned = value)
                    : null,
                contentPadding: EdgeInsets.zero,
              ),
              // Only show the notifications section if the feature is enabled
              // in the remote config.
              if (pushNotificationConfig?.enabled == true) ...[
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.saveFilterDialogNotificationsLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                // Generate a CheckboxListTile for each available delivery type.
                ...PushNotificationSubscriptionDeliveryType.values.map((type) {
                  // Check if this specific delivery type is enabled globally.
                  final isTypeEnabled =
                      pushNotificationConfig?.deliveryConfigs[type] ?? false;

                  if (!isTypeEnabled) {
                    return const SizedBox.shrink();
                  }

                  return CheckboxListTile(
                    title: Text(type.toL10n(l10n)),
                    value: _selectedDeliveryTypes.contains(type),
                    // Disable if the user has reached their subscription limit.
                    onChanged: _canSubscribe
                        ? (isSelected) {
                            setState(() {
                              if (isSelected == true) {
                                _selectedDeliveryTypes.add(type);
                              } else {
                                _selectedDeliveryTypes.remove(type);
                              }
                            });
                          }
                        : null,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ],
          ),
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

/// An extension to provide localized strings for [PushNotificationSubscriptionDeliveryType].
extension on PushNotificationSubscriptionDeliveryType {
  String toL10n(AppLocalizations l10n) {
    switch (this) {
      case PushNotificationSubscriptionDeliveryType.breakingOnly:
        return l10n.notificationDeliveryTypeBreakingOnly;
      case PushNotificationSubscriptionDeliveryType.dailyDigest:
        return l10n.notificationDeliveryTypeDailyDigest;
      case PushNotificationSubscriptionDeliveryType.weeklyRoundup:
        return l10n.notificationDeliveryTypeWeeklyRoundup;
    }
  }
}
