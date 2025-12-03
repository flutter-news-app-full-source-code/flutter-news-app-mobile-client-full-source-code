import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/reporting/view/report_content_bottom_sheet.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template headline_actions_bottom_sheet}
/// A modal bottom sheet that displays actions for a given headline, such as
/// reporting the content.
/// {@endtemplate}
class HeadlineActionsBottomSheet extends StatelessWidget {
  /// {@macro headline_actions_bottom_sheet}
  const HeadlineActionsBottomSheet({required this.headline, super.key});

  /// The headline for which to display actions.
  final Headline headline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    return Wrap(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            l10n.headlineActionsModalTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: Text(l10n.reportActionLabel),
          onTap: () {
            Navigator.of(context).pop();
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ReportContentBottomSheet(
                entityId: headline.id,
                reportableEntity: ReportableEntity.headline,
              ),
            );
          },
        ),
      ],
    );
  }
}
