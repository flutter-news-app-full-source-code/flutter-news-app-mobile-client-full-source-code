import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template reaction_selector}
/// A horizontally scrollable list of reaction icons.
/// {@endtemplate}
class ReactionSelector extends StatelessWidget {
  /// {@macro reaction_selector}
  const ReactionSelector({
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
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ReactionType.values.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final reaction = ReactionType.values[index];
          final isSelected = selectedReaction == reaction;

          return _ReactionIcon(
            reaction: reaction,
            isSelected: isSelected,
            onTap: () => onReactionSelected?.call(isSelected ? null : reaction),
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : null,
          shape: BoxShape.circle,
        ),
        child: Icon(
          iconData,
          color: isSelected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          size: 28,
        ),
      ),
    );
  }
}
