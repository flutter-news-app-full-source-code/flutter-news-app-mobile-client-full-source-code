import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/bloc/engagement_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/user_content/engagement/widgets/reaction_selector.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template engagement_bottom_sheet}
/// A bottom sheet that serves as the main hub for user engagement.
///
/// It displays a list of reactions, a list of comments, and an input field
/// for adding new comments.
/// {@endtemplate}
class EngagementBottomSheet extends StatelessWidget {
  /// {@macro engagement_bottom_sheet}
  const EngagementBottomSheet({required this.headline, super.key});

  /// The headline for which to display engagement.
  final Headline headline;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EngagementBloc(
        entityId: headline.id,
        entityType: EngageableType.headline,
        engagementRepository: context.read<DataRepository<Engagement>>(),
        appBloc: context.read<AppBloc>(),
      )..add(const EngagementStarted()),
      child: const _EngagementBottomSheetView(),
    );
  }
}

class _EngagementBottomSheetView extends StatelessWidget {
  const _EngagementBottomSheetView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final state = context.watch<EngagementBloc>().state;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Text(
                l10n.commentsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              ReactionSelector(
                selectedReaction: state.userEngagement?.reaction.reactionType,
                onReactionSelected: (reaction) => context
                    .read<EngagementBloc>()
                    .add(EngagementReactionUpdated(reaction)),
              ),
              const Divider(height: AppSpacing.lg),
              Expanded(child: _buildContent(context, state, scrollController)),
              _CommentInputField(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    EngagementState state,
    ScrollController scrollController,
  ) {
    if (state.status == EngagementStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == EngagementStatus.failure) {
      return Center(child: Text(context.l10n.errorLabel));
    }

    final comments = state.engagements.where((e) => e.comment != null).toList();

    if (comments.isEmpty) {
      return Center(child: Text(context.l10n.noCommentsYet));
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final engagement = comments[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(engagement.reaction.reactionType.name.substring(0, 2)),
          ),
          title: Text(engagement.comment!.content),
          subtitle: Text('User ${engagement.userId.substring(0, 4)}'),
        );
      },
    );
  }
}

class _CommentInputField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This will be implemented in a subsequent phase.
    return const SizedBox.shrink();
  }
}
