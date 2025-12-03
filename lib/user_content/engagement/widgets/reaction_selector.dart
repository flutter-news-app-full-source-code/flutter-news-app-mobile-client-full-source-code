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
    // TODO(fulleni): Replace with actual icons/emojis.
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        child: Text(reaction.name.substring(0, 2)),
      ),
    );
  }
}
