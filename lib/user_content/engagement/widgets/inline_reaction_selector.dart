import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template inline_reaction_selector}
/// A row of reaction icons designed for inline placement within a feed tile.
///
/// This widget is intentionally subtle to not distract from the main content.
/// {@endtemplate}
class InlineReactionSelector extends StatelessWidget {
  /// {@macro inline_reaction_selector}
  const InlineReactionSelector({
    this.selectedReaction,
    this.onReactionSelected,
    this.onCommentTap,
    this.unselectedColor,
    super.key,
  });

  /// The currently selected reaction, if any.
  final ReactionType? selectedReaction;

  /// The color for unselected reaction icons.
  final Color? unselectedColor;

  /// Callback for when a reaction is selected.
  final ValueChanged<ReactionType?>? onReactionSelected;

  /// Optional callback for when the comment button is tapped.
  /// If provided, a comment icon will be shown at the start of the row.
  final VoidCallback? onCommentTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (onCommentTap != null) ...[
          GestureDetector(
            onTap: onCommentTap,
            child: Icon(
              Icons.chat_bubble,
              color: unselectedColor ?? colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        ...List.generate(ReactionType.values.length, (index) {
          final reaction = ReactionType.values[index];
          final isSelected = selectedReaction == reaction;
          return Padding(
            padding: index != ReactionType.values.length - 1
                ? const EdgeInsets.only(right: AppSpacing.sm)
                : EdgeInsets.zero,
            child: _ReactionIcon(
              reaction: reaction,
              isSelected: isSelected,
              unselectedColor: unselectedColor,
              onTap: () =>
                  onReactionSelected?.call(isSelected ? null : reaction),
            ),
          );
        }),
      ],
    );
  }
}

class _ReactionIcon extends StatelessWidget {
  const _ReactionIcon({
    required this.reaction,
    required this.isSelected,
    required this.onTap,
    this.unselectedColor,
  });

  final ReactionType reaction;
  final bool isSelected;
  final Color? unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final iconData = switch (reaction) {
      ReactionType.like => Icons.thumb_up_outlined,
      ReactionType.insightful => Icons.lightbulb_outline,
      ReactionType.amusing => Icons.sentiment_satisfied_outlined,
      ReactionType.sad => Icons.sentiment_dissatisfied_outlined,
      ReactionType.angry => Icons.local_fire_department_outlined,
      ReactionType.skeptical => Icons.thumb_down_outlined,
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: Icon(
          iconData,
          color: isSelected
              ? colorScheme.primary
              : unselectedColor ?? colorScheme.onSurfaceVariant,
          size: 22,
          semanticLabel: reaction.name,
        ),
      ),
    );
  }
}
