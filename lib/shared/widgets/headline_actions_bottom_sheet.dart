import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/reporting/view/report_content_bottom_sheet.dart';
import 'package:go_router/go_router.dart';
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

    final currentSaved = List<Headline>.from(
      userContentPreferences.savedHeadlines,
    );

    try {
      if (isBookmarked) {
        currentSaved.removeWhere((h) => h.id == widget.headline.id);
      } else {
        final limitationService = context.read<ContentLimitationService>();
        final status = await limitationService.checkAction(
          ContentAction.bookmarkHeadline,
        );

        if (status != LimitationStatus.allowed) {
          if (mounted) {
            final userRole = context.read<AppBloc>().state.user?.appRole;
            final content = _getBottomSheetContent(
              context: context,
              l10n: l10n,
              status: status,
              userRole: userRole,
              action: ContentAction.bookmarkHeadline,
            );

            await showModalBottomSheet<void>(
              context: context,
              builder: (_) => ContentLimitationBottomSheet(
                title: content.title,
                body: content.body,
                buttonText: content.buttonText,
                onButtonPressed: content.onPressed,
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
      // Close the bottom sheet after the action is dispatched.
      // The UI will update reactively based on the AppBloc's state change.
      if (mounted) {
        Navigator.of(context).pop();
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
          onTap: () {
            // Pop the sheet before sharing to avoid it being open in the background.
            Navigator.of(context).pop();
            Share.share(widget.headline.url);
          },
        ),
        ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: Text(l10n.reportActionLabel),
          onTap: () async {
            final limitationService = context.read<ContentLimitationService>();
            final status = await limitationService.checkAction(
              ContentAction.submitReport,
            );

            if (!mounted) return;

            if (status != LimitationStatus.allowed) {
              final userRole = context.read<AppBloc>().state.user?.appRole;
              final content = _getBottomSheetContent(
                context: context,
                l10n: l10n,
                status: status,
                userRole: userRole,
                action: ContentAction.submitReport,
              );
              await showModalBottomSheet<void>(
                context: context,
                builder: (_) => ContentLimitationBottomSheet(
                  title: content.title,
                  body: content.body,
                  buttonText: content.buttonText,
                  onButtonPressed: content.onPressed,
                ),
              );
            } else {
              Navigator.of(context).pop();
              await showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => ReportContentBottomSheet(
                  entityId: widget.headline.id,
                  reportableEntity: ReportableEntity.headline,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

/// Determines the content for the [ContentLimitationBottomSheet] based on
/// the user's role and the limitation status.
({String title, String body, String buttonText, VoidCallback? onPressed})
_getBottomSheetContent({
  required BuildContext context,
  required AppLocalizations l10n,
  required LimitationStatus status,
  required AppUserRole? userRole,
  required ContentAction action,
}) {
  switch (status) {
    case LimitationStatus.anonymousLimitReached:
      return (
        title: l10n.anonymousLimitTitle,
        body: l10n.anonymousLimitBody,
        buttonText: l10n.anonymousLimitButton,
        onPressed: () {
          Navigator.of(context).pop();
          context.pushNamed(Routes.accountLinkingName);
        },
      );
    case LimitationStatus.standardUserLimitReached:
      // TODO(fulleni): Implement upgrade flow.
      return (
        title: l10n.standardLimitTitle,
        body: l10n.standardLimitBody,
        buttonText: l10n.standardLimitButton,
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
    case LimitationStatus.premiumUserLimitReached:
      final body = switch (action) {
        ContentAction.bookmarkHeadline => l10n.limitReachedBodySave,
        ContentAction.submitReport => l10n.limitReachedBodyReports,
        _ => l10n.premiumLimitBody,
      };
      final destinationRoute = action == ContentAction.bookmarkHeadline
          ? Routes.accountSavedHeadlinesName
          : Routes.accountName;
      return (
        title: l10n.premiumLimitTitle,
        body: body,
        buttonText: l10n.premiumLimitButton,
        onPressed: () {
          Navigator.of(context).pop();
          context.goNamed(destinationRoute);
        },
      );
    case LimitationStatus.allowed:
      return (title: '', body: '', buttonText: '', onPressed: null);
  }
}
