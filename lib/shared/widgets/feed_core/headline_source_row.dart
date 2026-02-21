import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/ads/services/interstitial_ad_manager.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/router/routes.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/headline_actions_bottom_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ui_kit/ui_kit.dart';

/// {@template headline_source_row}
/// A widget to display the source and publish date of a headline.
/// {@endtemplate}
class HeadlineSourceRow extends StatefulWidget {
  /// {@macro headline_source_row}
  const HeadlineSourceRow({required this.headline, super.key});

  /// The headline data to display.
  final Headline headline;

  Future<void> _handleEntityTap(BuildContext context) async {
    await context.read<InterstitialAdManager>().onPotentialAdTrigger();
    if (!context.mounted) return;
    await context.pushNamed(
      Routes.entityDetailsName,
      pathParameters: {
        'type': ContentType.source.name,
        'id': headline.source.id,
      },
    );
  }

  @override
  State<HeadlineSourceRow> createState() => _HeadlineSourceRowState();
}

class _HeadlineSourceRowState extends State<HeadlineSourceRow> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final currentLocale = context.watch<AppBloc>().state.locale;

    final formattedDate = timeago.format(
      widget.headline.createdAt,
      locale: currentLocale.languageCode,
    );

    final sourceTextStyle = textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant.withOpacity(0.8),
      fontWeight: FontWeight.w500,
    );

    final dateTextStyle = textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              InkWell(
                onTap: () => widget._handleEntityTap(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: AppSpacing.md,
                      height: AppSpacing.md,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.xs / 2),
                        child: Image.network(
                          widget.headline.source.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.source_outlined,
                            size: AppSpacing.md,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(widget.headline.source.name, style: sourceTextStyle),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (formattedDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Text(formattedDate, style: dateTextStyle),
              ),
            IconButton(
              icon: Icon(
                Icons.more_vert,
                // Use the same color as the date text for visual consistency.
                color: dateTextStyle?.color,
              ),
              // Adjust icon size to be more harmonious with the text.
              iconSize: AppSpacing.lg,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: context.read<AppBloc>(),
                  child: HeadlineActionsBottomSheet(headline: widget.headline),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
