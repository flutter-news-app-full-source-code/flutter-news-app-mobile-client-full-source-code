import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/constants/app_layout.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/reporting/view/report_content_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';

/// {@template headline_actions_bottom_sheet}
/// A modal bottom sheet that displays secondary actions for a given headline,
/// such as saving, sharing, and reporting.
/// {@endtemplate}
class HeadlineActionsBottomSheet extends StatefulWidget {
  /// {@macro headline_actions_bottom_sheet}
  const HeadlineActionsBottomSheet({required this.headline, super.key});

  /// The headline for which to display actions.
  final Headline headline;

  @override
  State<HeadlineActionsBottomSheet> createState() =>
      _HeadlineActionsBottomSheetState();
}

class _HeadlineActionsBottomSheetState
    extends State<HeadlineActionsBottomSheet> {
  final bool _isBookmarking = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final isBookmarked = context.select<AppBloc, bool>(
      (bloc) =>
          bloc.state.userContentPreferences?.savedHeadlines.any(
            (h) => h.id == widget.headline.id,
          ) ??
          false,
    );

    final remoteConfig = context.watch<AppBloc>().state.remoteConfig;
    final communityConfig = remoteConfig?.features.community;
    final isHeadlineReportingEnabled =
        (communityConfig?.enabled ?? false) &&
        (communityConfig?.reporting.headlineReportingEnabled ?? false);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppLayout.maxDialogContentWidth,
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: _isBookmarking
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
              title: Text(
                isBookmarked
                    ? l10n.removeBookmarkActionLabel
                    : l10n.bookmarkActionLabel,
              ),
              onTap: () {
                context.read<AppBloc>().add(
                  AppBookmarkToggled(
                    headline: widget.headline,
                    isBookmarked: isBookmarked,
                    context: context,
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(l10n.shareActionLabel),
              onTap: () {
                // Pop the sheet before sharing to avoid it being open in the background.
                Navigator.of(context).pop();
                Share.share(widget.headline.url);
                context.read<AnalyticsService>().logEvent(
                  AnalyticsEvent.contentShared,
                  payload: ContentSharedPayload(
                    contentId: widget.headline.id,
                    contentType: ContentType.headline.name,
                    // TODO(fulleni): We assume system share for now as we can't easily detect the
                    // specific app chosen by the user in the native sheet.
                    shareMedium: 'system',
                  ),
                );
              },
            ),
            if (isHeadlineReportingEnabled)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(l10n.reportActionLabel),
                onTap: () async {
                  // Pop the current sheet before showing the new one.
                  Navigator.of(context).pop();
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ReportContentBottomSheet(
                      entityId: widget.headline.id,
                      reportableEntity: ReportableEntity.headline,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
