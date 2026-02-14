import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/onboarding/initial_personalization/bloc/initial_personalization_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/multi_select_search_page.dart';
import 'package:ui_kit/ui_kit.dart';

class InitialPersonalizationPage extends StatelessWidget {
  const InitialPersonalizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InitialPersonalizationView();
  }
}

class _InitialPersonalizationView extends StatelessWidget {
  const _InitialPersonalizationView();

  void _onCompleted(BuildContext context) {
    context.read<InitialPersonalizationBloc>().add(
      InitialPersonalizationCompleted(),
    );
  }

  void _onSkipped(BuildContext context) {
    context.read<InitialPersonalizationBloc>().add(
      InitialPersonalizationSkipped(),
    );
  }

  Future<void> _selectTopics(BuildContext context) async {
    final bloc = context.read<InitialPersonalizationBloc>();
    final l10n = AppLocalizations.of(context);
    final result = await Navigator.of(context).push<Set<Topic>>(
      MaterialPageRoute(
        builder: (_) => MultiSelectSearchPage<Topic>(
          title: l10n.initialPersonalizationStepTopicsTitle,
          repository: context.read<DataRepository<Topic>>(),
          initialSelectedItems: bloc.state.selectedTopics,
          maxSelectionCount: bloc.state.maxSelectionsPerCategory,
          itemBuilder: (topic) => topic.name,
        ),
      ),
    );
    if (result != null) {
      bloc.add(InitialPersonalizationItemsSelected<Topic>(items: result));
    }
  }

  Future<void> _selectSources(BuildContext context) async {
    final bloc = context.read<InitialPersonalizationBloc>();
    final l10n = AppLocalizations.of(context);
    final result = await Navigator.of(context).push<Set<Source>>(
      MaterialPageRoute(
        builder: (_) => MultiSelectSearchPage<Source>(
          title: l10n.initialPersonalizationStepSourcesTitle,
          repository: context.read<DataRepository<Source>>(),
          initialSelectedItems: bloc.state.selectedSources,
          maxSelectionCount: bloc.state.maxSelectionsPerCategory,
          itemBuilder: (source) => source.name,
        ),
      ),
    );
    if (result != null) {
      bloc.add(InitialPersonalizationItemsSelected<Source>(items: result));
    }
  }

  Future<void> _selectCountries(BuildContext context) async {
    final bloc = context.read<InitialPersonalizationBloc>();
    final l10n = AppLocalizations.of(context);
    final result = await Navigator.of(context).push<Set<Country>>(
      MaterialPageRoute(
        builder: (_) => MultiSelectSearchPage<Country>(
          title: l10n.initialPersonalizationStepCountriesTitle,
          repository: context.read<DataRepository<Country>>(),
          initialSelectedItems: bloc.state.selectedCountries,
          maxSelectionCount: bloc.state.maxSelectionsPerCategory,
          itemBuilder: (country) => country.name,
        ),
      ),
    );
    if (result != null) {
      bloc.add(InitialPersonalizationItemsSelected<Country>(items: result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = context
        .select((AppBloc bloc) => bloc.state.remoteConfig!)
        .features
        .onboarding
        .initialPersonalization;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.initialPersonalizationTitle),
        actions: [
          if (config.isSkippable)
            TextButton(
              onPressed: () => _onSkipped(context),
              child: Text(l10n.appTourSkipButton),
            ),
        ],
      ),
      body:
          BlocConsumer<InitialPersonalizationBloc, InitialPersonalizationState>(
            listener: (context, state) {
              // Listener can handle side effects if needed.
            },
            builder: (context, state) {
              if (state.status == InitialPersonalizationStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == InitialPersonalizationStatus.failure) {
                return FailureStateWidget(
                  exception:
                      state.error ??
                      const UnknownException(
                        'An unknown error occurred during personalization.',
                      ),
                  onRetry: () => context.read<InitialPersonalizationBloc>().add(
                    InitialPersonalizationDataRequested(),
                  ),
                );
              }

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Text(
                        l10n.initialPersonalizationSubtitle,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(
                        child: ListView(
                          children: [
                            if (config.isTopicSelectionEnabled)
                              _StepCard(
                                title:
                                    l10n.initialPersonalizationStepTopicsTitle,
                                selectedCount: state.selectedTopics.length,
                                onTap: () => _selectTopics(context),
                              ),
                            if (config.isSourceSelectionEnabled)
                              _StepCard(
                                title:
                                    l10n.initialPersonalizationStepSourcesTitle,
                                selectedCount: state.selectedSources.length,
                                onTap: () => _selectSources(context),
                              ),
                            if (config.isCountrySelectionEnabled)
                              _StepCard(
                                title: l10n
                                    .initialPersonalizationStepCountriesTitle,
                                selectedCount: state.selectedCountries.length,
                                onTap: () => _selectCountries(context),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        l10n.initialPersonalizationTotalSelectionCountLabel(
                          state.totalSelectedCount,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () => _onCompleted(context),
                        child: Text(l10n.initialPersonalizationFinishButton),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.selectedCount,
    required this.onTap,
  });

  final String title;
  final int selectedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedCount > 0)
              Text(
                '$selectedCount',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
