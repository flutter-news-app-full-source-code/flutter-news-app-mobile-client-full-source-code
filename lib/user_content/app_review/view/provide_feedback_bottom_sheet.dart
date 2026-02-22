import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/constants/app_layout.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template provide_feedback_bottom_sheet}
/// A bottom sheet for collecting detailed user feedback after a negative
/// response in the app review funnel.
///
/// It allows users to select from a list of predefined reasons or provide
/// custom text feedback.
/// {@endtemplate}
class ProvideFeedbackBottomSheet extends StatefulWidget {
  /// {@macro provide_feedback_bottom_sheet}
  const ProvideFeedbackBottomSheet({
    required this.onFeedbackSubmitted,
    super.key,
  });

  /// Callback function that is triggered when the user submits their feedback.
  final ValueChanged<String> onFeedbackSubmitted;

  @override
  State<ProvideFeedbackBottomSheet> createState() =>
      _ProvideFeedbackBottomSheetState();
}

class _ProvideFeedbackBottomSheetState
    extends State<ProvideFeedbackBottomSheet> {
  final _textController = TextEditingController();
  String? _selectedReason;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    final feedbackDetails = _selectedReason == 'other'
        ? _textController.text
        : _selectedReason;
    if (feedbackDetails != null && feedbackDetails.isNotEmpty) {
      widget.onFeedbackSubmitted(feedbackDetails);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final reasons = {
      l10n.feedbackPromptReasonUI: 'ui_design',
      l10n.feedbackPromptReasonPerformance: 'performance',
      l10n.feedbackPromptReasonContent: 'content_quality',
      l10n.feedbackPromptReasonOther: 'other',
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppLayout.maxDialogContentWidth,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.feedbackPromptTitle, style: textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.lg),
                ...reasons.entries.map((entry) {
                  return RadioListTile<String>(
                    title: Text(entry.key),
                    value: entry.value,
                    groupValue: _selectedReason,
                    onChanged: (value) =>
                        setState(() => _selectedReason = value),
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                if (_selectedReason == 'other')
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: TextFormField(
                      controller: _textController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: l10n.reportAdditionalCommentsLabel,
                      ),
                      maxLines: 3,
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancelButtonLabel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            (_selectedReason != null &&
                                (_selectedReason != 'other' ||
                                    _textController.text.isNotEmpty))
                            ? _submitFeedback
                            : null,
                        child: Text(l10n.feedbackPromptSubmitButton),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
