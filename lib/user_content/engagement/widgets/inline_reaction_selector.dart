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
    super.key,
  });

  /// The currently selected reaction, if any.
  final ReactionType? selectedReaction;

  /// Callback for when a reaction is selected.
  final ValueChanged<ReactionType?>? onReactionSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(
        ReactionType.values.length,
        (index) {
          final reaction = ReactionType.values[index];
          final isSelected = selectedReaction == reaction;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _ReactionIcon(
              reaction: reaction,
              isSelected: isSelected,
              onTap: () => onReactionSelected?.call(isSelected ? null : reaction),
            ),
          );
        },
      ),
    );
  }
}

class _ReactionIcon extends StatelessWidget {
  const _ReactionIcon({
    required this.reaction,
    required this.isSelected,
    required this.onTap,
  });

  final ReactionType reaction;
  final bool isSelected;
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
              : colorScheme.onSurfaceVariant,
          size: 22,
          semanticLabel: reaction.name,
        ),
      ),
    );
  }
}
