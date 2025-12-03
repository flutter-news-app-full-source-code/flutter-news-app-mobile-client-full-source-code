import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
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

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final userId = context.read<AppBloc>().state.user?.id;
    if (userId == null || _selectedReason == null) return;

    final limitationService = context.read<ContentLimitationService>();
    final status = limitationService.checkAction(ContentAction.submitReport);

    if (status != LimitationStatus.allowed) {
      await showModalBottomSheet<void>(
        context: context,
        builder: (_) => ContentLimitationBottomSheet(status: status),
      );
      return;
    }

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
      await context.read<DataRepository<Report>>().create(item: report);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(context.l10n.reportSuccessSnackbar)),
          );
        Navigator.of(context).pop();
      }
    } catch (e, s) {
      _logger.severe('Failed to submit report', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(context.l10n.reportFailureSnackbar)),
          );
      }
    }
  }

  Map<String, String> _getReasons(AppLocalizations l10n) {
    switch (widget.reportableEntity) {
      case ReportableEntity.headline:
        return {
          l10n.headlineReportReasonMisinformation:
              HeadlineReportReason.misinformationOrFakeNews.name,
          l10n.headlineReportReasonClickbait:
              HeadlineReportReason.clickbaitTitle.name,
          l10n.headlineReportReasonOffensive:
              HeadlineReportReason.offensiveOrHateSpeech.name,
          l10n.headlineReportReasonSpam: HeadlineReportReason.spamOrScam.name,
          l10n.headlineReportReasonBrokenLink:
              HeadlineReportReason.brokenLink.name,
          l10n.headlineReportReasonPaywalled:
              HeadlineReportReason.paywalled.name,
        };
      case ReportableEntity.source:
      case ReportableEntity.comment:
        // TODO(user_content): Implement reasons for source and comment.
        return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final reasons = _getReasons(l10n);

    return Padding(
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
            Text(l10n.reportReasonSelectionPrompt, style: textTheme.bodyLarge),
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
                    onPressed: _selectedReason != null ? _submitReport : null,
                    child: Text(l10n.reportSubmitButtonLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
