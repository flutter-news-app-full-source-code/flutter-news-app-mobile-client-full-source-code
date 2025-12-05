import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
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
  bool _isBookmarking = false;

  Future<void> _onBookmarkTapped(bool isBookmarked) async {
    setState(() => _isBookmarking = true);

    final l10n = AppLocalizations.of(context);
    final appBloc = context.read<AppBloc>();
    final userContentPreferences = appBloc.state.userContentPreferences;

    if (userContentPreferences == null) {
      setState(() => _isBookmarking = false);
      return;
    }

    final currentSaved =
        List<Headline>.from(userContentPreferences.savedHeadlines);

    try {
      if (isBookmarked) {
        currentSaved.removeWhere((h) => h.id == widget.headline.id);
      } else {
        final limitationService = context.read<ContentLimitationService>();
        final status =
            limitationService.checkAction(ContentAction.bookmarkHeadline);

        if (status != LimitationStatus.allowed) {
          if (mounted) {
            await showModalBottomSheet<void>(
              context: context,
              builder: (_) => ContentLimitationBottomSheet(
                title: l10n.limitReachedTitle,
                body: l10n.limitReachedBodySave,
                buttonText: l10n.manageMyContentButton,
              ),
            );
          }
          return;
        }
        currentSaved.insert(0, widget.headline);
        if (mounted) {
          appBloc.add(AppPositiveInteractionOcurred(context: context));
        }
      }

      appBloc.add(
        AppUserContentPreferencesChanged(
          preferences: userContentPreferences.copyWith(
            savedHeadlines: currentSaved,
          ),
        ),
      );
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
        setState(() => _isBookmarking = false);
      }
    }
  }

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

    return Wrap(
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
          onTap: _isBookmarking ? null : () => _onBookmarkTapped(isBookmarked),
        ),
        ListTile(
          leading: const Icon(Icons.share_outlined),
          title: Text(l10n.shareActionLabel),
          onTap: () => Share.share(widget.headline.url),
        ),
        ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: Text(l10n.reportActionLabel),
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => ReportContentBottomSheet(
              entityId: widget.headline.id,
              reportableEntity: ReportableEntity.headline,
            ),
          ),
        ),
      ],
    );
  }
}
