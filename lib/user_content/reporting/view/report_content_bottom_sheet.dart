import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:logging/logging.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:uuid/uuid.dart';

/// {@template report_content_bottom_sheet}
/// A bottom sheet for reporting content such as headlines, sources, or comments.
///
/// This widget implements a multi-step process:
/// 1. User selects a reason for the report.
/// 2. User can add optional comments.
/// 3. The report is submitted to the backend.
/// {@endtemplate}
class ReportContentBottomSheet extends StatefulWidget {
  /// {@macro report_content_bottom_sheet}
  const ReportContentBottomSheet({
    required this.entityId,
    required this.reportableEntity,
    super.key,
  });

  /// The ID of the entity being reported.
  final String entityId;

  /// The type of entity being reported.
  final ReportableEntity reportableEntity;

  @override
  State<ReportContentBottomSheet> createState() =>
      _ReportContentBottomSheetState();
}

class _ReportContentBottomSheetState extends State<ReportContentBottomSheet> {
  final _logger = Logger('ReportContentBottomSheet');
  final _textController = TextEditingController();
  String? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final userId = context.read<AppBloc>().state.user?.id;
    if (userId == null || _selectedReason == null) return;

    final report = Report(
      id: const Uuid().v4(),
      reporterUserId: userId,
      entityId: widget.entityId,
      entityType: widget.reportableEntity,
      reason: _selectedReason!,
      additionalComments: _textController.text.isNotEmpty
          ? _textController.text
          : null,
      status: ModerationStatus.pendingReview,
      createdAt: DateTime.now(),
    );

    try {
      setState(() => _isSubmitting = true);
      context.read<AppBloc>().add(AppContentReported(report: report));

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).reportSuccessSnackbar),
            ),
          );
        Navigator.of(context).pop();
      }
    } on Exception catch (e, s) {
      _logger.severe('Failed to submit report', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizationsX(context).l10n.reportFailureSnackbar,
              ),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Map<String, String> _getReasons(AppLocalizations l10n) {
    switch (widget.reportableEntity) {
      case ReportableEntity.headline:
        return HeadlineReportReason.values.asNameMap().map(
          (key, value) => MapEntry(value.toL10n(l10n), key),
        );
      case ReportableEntity.source:
        return SourceReportReason.values.asNameMap().map(
          (key, value) => MapEntry(value.toL10n(l10n), key),
        );
      case ReportableEntity.comment:
        return CommentReportReason.values.asNameMap().map(
          (key, value) => MapEntry(value.toL10n(l10n), key),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final reasons = _getReasons(l10n);

    return SafeArea(
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
              Text(l10n.reportContentTitle, style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.reportReasonSelectionPrompt,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              ...reasons.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.key),
                  value: entry.value,
                  groupValue: _selectedReason,
                  onChanged: (value) => setState(() => _selectedReason = value),
                  contentPadding: EdgeInsets.zero,
                );
              }),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: l10n.reportAdditionalCommentsLabel,
                ),
                maxLines: 3,
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
                      onPressed: _selectedReason != null && !_isSubmitting
                          ? _submitReport
                          : null,
                      child: _isSubmitting
                          ? const SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(),
                            )
                          : Text(l10n.reportSubmitButtonLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on HeadlineReportReason {
  String toL10n(AppLocalizations l10n) {
    switch (this) {
      case HeadlineReportReason.misinformationOrFakeNews:
        return l10n.headlineReportReasonMisinformation;
      case HeadlineReportReason.clickbaitTitle:
        return l10n.headlineReportReasonClickbait;
      case HeadlineReportReason.offensiveOrHateSpeech:
        return l10n.headlineReportReasonOffensive;
      case HeadlineReportReason.spamOrScam:
        return l10n.headlineReportReasonSpam;
      case HeadlineReportReason.brokenLink:
        return l10n.headlineReportReasonBrokenLink;
      case HeadlineReportReason.paywalled:
        return l10n.headlineReportReasonPaywalled;
    }
  }
}

extension on SourceReportReason {
  String toL10n(AppLocalizations l10n) {
    switch (this) {
      case SourceReportReason.lowQualityJournalism:
        return l10n.sourceReportReasonLowQuality;
      case SourceReportReason.highAdDensity:
        return l10n.sourceReportReasonHighAdDensity;
      case SourceReportReason.frequentPaywalls:
        return l10n.sourceReportReasonFrequentPaywalls;
      case SourceReportReason.impersonation:
        return l10n.sourceReportReasonImpersonation;
      case SourceReportReason.spreadsMisinformation:
        return l10n.sourceReportReasonMisinformation;
    }
  }
}

extension on CommentReportReason {
  String toL10n(AppLocalizations l10n) {
    switch (this) {
      case CommentReportReason.spamOrAdvertising:
        return l10n.commentReportReasonSpam;
      case CommentReportReason.harassmentOrBullying:
        return l10n.commentReportReasonHarassment;
      case CommentReportReason.hateSpeech:
        return l10n.commentReportReasonHateSpeech;
    }
  }
}
