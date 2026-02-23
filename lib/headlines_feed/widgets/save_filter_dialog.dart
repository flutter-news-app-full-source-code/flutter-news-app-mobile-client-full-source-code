import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/push_notification/services/push_notification_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
import 'package:logging/logging.dart';
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
    context.read<Logger>().fine('SaveFilterDialog initialized.');
    _checkLimits();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLimits() async {
    final contentLimitationService = context.read<ContentLimitationService>();
    context.read<Logger>().info(
      'Checking user limits for pinning and notification subscriptions.',
    );

    final canPinStatus = await contentLimitationService.checkAction(
      ContentAction.pinFilter,
    );
    if (mounted) {
      setState(() {
        _canPin =
            canPinStatus == LimitationStatus.allowed ||
            (widget.filterToEdit?.isPinned == true);
      });
      context.read<Logger>().finer(
        'Pinning limit check result: $_canPin (status: $canPinStatus)',
      );
    }

    for (final type in PushNotificationSubscriptionDeliveryType.values) {
      final isAlreadySubscribed =
          widget.filterToEdit?.deliveryTypes.contains(type) ?? false;
      final limitationStatus = await contentLimitationService.checkAction(
        ContentAction.subscribeToSavedFilterNotifications,
        deliveryType: type,
      );
      if (mounted) {
        setState(() {
          _canSubscribePerType[type] =
              limitationStatus == LimitationStatus.allowed ||
              isAlreadySubscribed;
        });
        context.read<Logger>().finer(
          'Subscription limit check for type "$type": '
          '${_canSubscribePerType[type]} (status: $limitationStatus)',
        );
      }
    }
  }

  /// Handles the complete form submission logic, including validation,
  /// permission requests, and saving the filter.
  Future<void> _submitForm() async {
    final l10n = AppLocalizationsX(context).l10n;
    final logger = context.read<Logger>();

    if (!_formKey.currentState!.validate()) {
      logger.fine('[_submitForm] Form validation failed.');
      return;
    }

    logger.fine('[_submitForm] Form validated. Starting save process.');
    setState(() => _isSaving = true);

    try {
      final deliveryTypesToSave =
          Set<PushNotificationSubscriptionDeliveryType>.from(
            _selectedDeliveryTypes,
          );

      // If notifications are selected, handle the permission flow.
      if (deliveryTypesToSave.isNotEmpty) {
        logger.fine(
          '[_submitForm] Notification types selected. Checking permissions.',
        );
        final permissionGranted = await _handlePermissionRequest(logger);

        // If permission was ultimately denied, clear the delivery types
        // so the filter is saved without notification subscriptions.
        if (!permissionGranted) {
          logger.warning(
            '[_submitForm] Permission denied. Clearing delivery types before saving.',
          );
          deliveryTypesToSave.clear();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.notificationPermissionDeniedError),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        } else {
          logger.fine(
            '[_submitForm] Permission granted. Proceeding with save.',
          );
        }
      }

      final limitationService = context.read<ContentLimitationService>();
      final status = await limitationService.checkAction(
        ContentAction.saveFilter,
      );

      if (status != LimitationStatus.allowed && widget.filterToEdit == null) {
        logger.warning(
          '[_submitForm] Save filter limit reached. Showing bottom sheet.',
        );
        if (mounted) {
          showContentLimitationBottomSheet(
            context: context,
            status: status,
            action: ContentAction.saveFilter,
          );
        }
        return;
      }

      logger.fine('[_submitForm] Calling onSave callback.');
      widget.onSave((
        name: _controller.text.trim(),
        isPinned: _isPinned,
        deliveryTypes: deliveryTypesToSave,
      ));

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ForbiddenException catch (e, s) {
      logger.severe('[_submitForm] ForbiddenException caught.', e, s);
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
    } catch (e, s) {
      logger.severe('[_submitForm] An unexpected error occurred.', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saveFilterDialogGenericError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        logger.fine('[_submitForm] Finalizing save process.');
        setState(() => _isSaving = false);
      }
    }
  }

  /// A helper to encapsulate the multi-step permission request flow.
  /// Returns `true` if permission is granted, `false` otherwise.
  Future<bool> _handlePermissionRequest(Logger logger) async {
    final notificationService = context.read<PushNotificationService>();
    final l10n = AppLocalizationsX(context).l10n;

    final hasPermission = await notificationService.hasPermission();
    logger.fine('[_handlePermissionRequest] Has permission: $hasPermission');

    if (hasPermission) {
      return true;
    }

    logger.fine('[_handlePermissionRequest] Showing pre-permission dialog.');
    // Guard against using context across async gaps.
    if (!mounted) return false;
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

    logger.fine(
      '[_handlePermissionRequest] Pre-permission dialog result: $wantsToAllow',
    );
    if (wantsToAllow != true) {
      return false;
    }

    logger.fine('[_handlePermissionRequest] Requesting OS permission.');
    final permissionGranted = await notificationService.requestPermission();
    logger.fine(
      '[_handlePermissionRequest] OS permission result: $permissionGranted',
    );

    return permissionGranted;
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
                Builder(
                  builder: (context) {
                    const type =
                        PushNotificationSubscriptionDeliveryType.breakingOnly;
                    final isGloballyEnabled =
                        pushNotificationConfig?.deliveryConfigs[type] ?? false;
                    final isAlreadySubscribed = _selectedDeliveryTypes.contains(
                      type,
                    );
                    final canInteract =
                        isGloballyEnabled &&
                        (_canSubscribePerType[type] ?? false);

                    return SwitchListTile(
                      title: Text(type.toL10n(l10n)),
                      value: isAlreadySubscribed,
                      onChanged: canInteract
                          ? (value) {
                              setState(() {
                                if (value) {
                                  _selectedDeliveryTypes.add(type);
                                } else {
                                  _selectedDeliveryTypes.remove(type);
                                }
                              });
                            }
                          : null,
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
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
                  dimension: 24,
                  child: CircularProgressIndicator(),
                )
              : Text(l10n.saveButtonLabel),
        ),
      ],
    );
  }
}

/// An extension to provide localized strings for
/// [PushNotificationSubscriptionDeliveryType].
extension on PushNotificationSubscriptionDeliveryType {
  String toL10n(AppLocalizations l10n) {
    switch (this) {
      case PushNotificationSubscriptionDeliveryType.breakingOnly:
        return l10n.notificationDeliveryTypeBreakingOnly;
    }
  }
}
