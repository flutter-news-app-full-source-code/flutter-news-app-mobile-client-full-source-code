import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/analytics/services/analytics_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/app_localizations.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/onboarding/app_tour/bloc/app_tour_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/constants/app_layout.dart';
import 'package:kv_storage_service/kv_storage_service.dart';
import 'package:logging/logging.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:ui_kit/ui_kit.dart';

class AppTourPage extends StatelessWidget {
  const AppTourPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppTourBloc(
        appBloc: context.read<AppBloc>(),
        storageService: context.read<KVStorageService>(),
        analyticsService: context.read<AnalyticsService>(),
        logger: context.read<Logger>(),
      ),
      child: const _AppTourView(),
    );
  }
}

class _AppTourView extends StatefulWidget {
  const _AppTourView();

  @override
  State<_AppTourView> createState() => _AppTourViewState();
}

class _AppTourViewState extends State<_AppTourView> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCompleted() {
    context.read<AppTourBloc>().add(AppTourCompleted());
  }

  void _onSkipped() {
    context.read<AnalyticsService>().logEvent(
      AnalyticsEvent.appTourSkipped,
      payload: const AppTourSkippedPayload(),
    );
    _onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final config = context.select(
      (AppBloc bloc) => bloc.state.remoteConfig!.features,
    );

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (config.onboarding.appTour.isSkippable)
            TextButton(
              onPressed: _onSkipped,
              child: Text(l10n.appTourSkipButton),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxDialogContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) => context.read<AppTourBloc>().add(
                        AppTourPageChanged(index),
                      ),
                      children: [
                        _TourStep(
                          icon: Icons.newspaper,
                          title: l10n.appTourStep1Title,
                          body: l10n.appTourStep1Body,
                        ),
                        _TourStep(
                          icon: Icons.filter_list,
                          title: l10n.appTourStep2Title,
                          body: l10n.appTourStep2Body,
                        ),
                        _TourStep(
                          icon: Icons.forum_outlined,
                          title: l10n.appTourStep3Title,
                          body: l10n.appTourStep3Body,
                        ),
                      ],
                    ),
                  ),
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: AppTourState.totalPages,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  BlocBuilder<AppTourBloc, AppTourState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state.isLastPage
                            ? _onCompleted
                            : () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ),
                        child: Text(
                          state.isLastPage
                              ? l10n.appTourGetStartedButton
                              : l10n.appTourNextButton,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TourStep extends StatelessWidget {
  const _TourStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
