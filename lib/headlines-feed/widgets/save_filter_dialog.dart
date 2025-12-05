import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/notifications/services/push_notification_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
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

  bool _isSaving = false;
  bool _canPin = true;
  late final Map<PushNotificationSubscriptionDeliveryType, bool>
  _canSubscribePerType;

  static const _maxNameLength = 15;

  @override
  void initState() {
    super.initState();
    final filter = widget.filterToEdit;
    _controller = TextEditingController(text: filter?.name);
    _isPinned = filter?.isPinned ?? false;
    // Initialize with a new modifiable Set to prevent "Cannot modify
    // unmodifiable Set" errors when editing an existing filter.
    _selectedDeliveryTypes = Set.from(filter?.deliveryTypes ?? {});
    _canSubscribePerType = {};
    _checkLimits();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLimits() async {
    final contentLimitationService = context.read<ContentLimitationService>();
    final l10n = AppLocalizations.of(context);

    final canPinStatus =
        await contentLimitationService.checkAction(ContentAction.pinHeadlineFilter);
    if (mounted) {
      setState(() {
        _canPin = canPinStatus == LimitationStatus.allowed ||
            (widget.filterToEdit?.isPinned ?? false);
      });
    }

    for (final type in PushNotificationSubscriptionDeliveryType.values) {
      final isAlreadySubscribed =
          widget.filterToEdit?.deliveryTypes.contains(type) ?? false;
      final limitationStatus = await contentLimitationService.checkAction(
        ContentAction.subscribeToHeadlineFilterNotifications,
      );
      if (mounted) {
        setState(() {
          _canSubscribePerType[type] =
              limitationStatus == LimitationStatus.allowed || isAlreadySubscribed;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // If the user has selected any notification types but permission has
      // not been granted, we initiate the lazy permission request flow.
      if (_selectedDeliveryTypes.isNotEmpty) {
        final notificationService = context.read<PushNotificationService>();
        final hasPermission = await notificationService.hasPermission();

        if (!hasPermission) {
          // Show a pre-permission dialog to explain why we need notifications.
          final l10n = AppLocalizationsX(context).l10n;
          final wantsToAllow = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.prePermissionDialogTitle),
              content: Text(l10n.prePermissionDialogBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.prePermissionDialogDenyButton),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.prePermissionDialogAllowButton),
                ),
              ],
            ),
          );

          // If the user declines the pre-dialog, stop the process.
          if (wantsToAllow != true) return;

          // Request permission via the OS dialog.
          final permissionGranted = await notificationService
              .requestPermission();

          // If the user denies permission at the OS level, stop.
          if (!permissionGranted) {
            // Provide UI feedback to the user.
            // Guard against using context across async gaps.
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.notificationPermissionDeniedError),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            return;
          }
        }
      }

      setState(() => _isSaving = true);
      try {
        final limitationService = context.read<ContentLimitationService>();
        final status =
            await limitationService.checkAction(ContentAction.saveHeadlineFilter);

        if (status != LimitationStatus.allowed && widget.filterToEdit == null) {
          if (mounted) {
            await showModalBottomSheet<void>(
              context: context,
              builder: (_) => ContentLimitationBottomSheet(
                title: l10n.limitReachedTitle,
                body: l10n.limitReachedBodySaveFilters,
                buttonText: l10n.manageMyContentButton,
              ),
            );
          }
          return;
        }

        widget.onSave((
          name: _controller.text.trim(),
          isPinned: _isPinned,
          deliveryTypes: _selectedDeliveryTypes,
        ));

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } on ForbiddenException catch (e) {
        if (mounted) {
          await showModalBottomSheet<void>(
            context: context,
            builder: (_) => ContentLimitationBottomSheet(
              title: l10n.limitReachedTitle,
              body: e.message,
              buttonText: l10n.gotItButton,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }

      // Pop the dialog and return `true` to signal to the caller that the
      // save operation was successfully initiated. This allows the caller
      // to coordinate subsequent navigation actions, preventing race conditions.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final isEditing = widget.filterToEdit != null;
    final pushNotificationConfig = context
        .select((AppBloc bloc) => bloc.state.remoteConfig)
        ?.features
        .pushNotifications;

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
                onFieldSubmitted: (_) async => _submitForm(),
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
                const SizedBox(height: AppSpacing.md),
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
                  final isGloballyEnabled =
                      pushNotificationConfig?.deliveryConfigs[type] ?? false;
                  final isAlreadySubscribed = _selectedDeliveryTypes.contains(
                    type,
                  );

                  // The checkbox is interactable if it's globally enabled AND
                  // the user has permission for this specific type OR if they
                  // are already subscribed (which allows them to unsubscribe).
                  final canInteract =
                      isGloballyEnabled &&
                      (_canSubscribePerType[type] ?? false);

                  return CheckboxListTile(
                    title: Text(type.toL10n(l10n)),
                    value: isAlreadySubscribed,
                    // The checkbox is disabled if it's not globally enabled or
                    // if the user has hit their limit (and isn't already
                    // subscribed). This preserves the checked state for users
                    // who had a subscription before a limit was imposed.
                    onChanged: canInteract
                        ? (bool? isSelected) {
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
        FilledButton(
          onPressed: _isSaving ? null : _submitForm,
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 24, child: CircularProgressIndicator())
              : Text(l10n.saveButtonLabel),
        ),
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
