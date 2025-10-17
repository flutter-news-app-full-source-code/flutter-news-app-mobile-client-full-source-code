import 'package:core/core.dart';
import 'package:data_repository/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/account/bloc/available_countries_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/l10n/l10n.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/shared/widgets/content_limitation_bottom_sheet.dart';
import 'package:ui_kit/ui_kit.dart';

/// {@template add_country_to_follow_page}
/// A page that allows users to browse and select countries to follow.
/// {@endtemplate}
class AddCountryToFollowPage extends StatelessWidget {
  /// {@macro add_country_to_follow_page}
  const AddCountryToFollowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsX(context).l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return BlocProvider(
      create: (context) => AvailableCountriesBloc(
        countriesRepository: context.read<DataRepository<Country>>(),
      )..add(const FetchAvailableCountries()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.addCountriesPageTitle, style: textTheme.titleLarge),
        ),
        body: BlocBuilder<AvailableCountriesBloc, AvailableCountriesState>(
          builder: (context, countriesState) {
            if (countriesState.status == AvailableCountriesStatus.loading) {
              return LoadingStateWidget(
                icon: Icons.flag_outlined,
                headline: l10n.countryFilterLoadingHeadline,
                subheadline: l10n.pleaseWait,
              );
            }
            if (countriesState.status == AvailableCountriesStatus.failure) {
              return FailureStateWidget(
                exception: OperationFailedException(
                  countriesState.error ?? l10n.countryFilterError,
                ),
                onRetry: () => context.read<AvailableCountriesBloc>().add(
                  const FetchAvailableCountries(),
                ),
              );
            }
            if (countriesState.availableCountries.isEmpty) {
              return InitialStateWidget(
                icon: Icons.search_off_outlined,
                headline: l10n.countryFilterEmptyHeadline,
                subheadline: l10n.countryFilterEmptySubheadline,
              );
            }

            final countries = countriesState.availableCountries;

            return BlocBuilder<AppBloc, AppState>(
              buildWhen: (previous, current) =>
                  previous.userContentPreferences?.followedCountries !=
                  current.userContentPreferences?.followedCountries,
              builder: (context, appState) {
                final userContentPreferences = appState.userContentPreferences;
                final followedCountries =
                    userContentPreferences?.followedCountries ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.paddingMedium,
                    vertical: AppSpacing.paddingSmall,
                  ).copyWith(bottom: AppSpacing.xxl),
                  itemCount: countries.length,
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    final isFollowed = followedCountries.any(
                      (fc) => fc.id == country.id,
                    );
                    final colorScheme = Theme.of(context).colorScheme;

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                        ),
                      ),
                      child: ListTile(
                        leading: SizedBox(
                          width: AppSpacing.xl + AppSpacing.xs,
                          height: AppSpacing.xl + AppSpacing.xs,
                          child:
                              Uri.tryParse(country.flagUrl)?.isAbsolute == true
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.xs,
                                  ),
                                  child: Image.network(
                                    country.flagUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.flag_outlined,
                                          color: colorScheme.onSurfaceVariant,
                                          size: AppSpacing.lg,
                                        ),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                  ),
                                )
                              : Icon(
                                  Icons.flag_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                  size: AppSpacing.lg,
                                ),
                        ),
                        title: Text(country.name, style: textTheme.titleMedium),
                        trailing: IconButton(
                          icon: isFollowed
                              ? Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                )
                              : Icon(
                                  Icons.add_circle_outline,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          tooltip: isFollowed
                              ? l10n.unfollowCountryTooltip(country.name)
                              : l10n.followCountryTooltip(country.name),
                          onPressed: () {
                            // Ensure user preferences are available before
                            // proceeding.
                            if (userContentPreferences == null) return;

                            // Create a mutable copy of the followed countries list.
                            final updatedFollowedCountries = List<Country>.from(
                              followedCountries,
                            );

                            // If the user is unfollowing, always allow it.
                            if (isFollowed) {
                              updatedFollowedCountries.removeWhere(
                                (c) => c.id == country.id,
                              );
                              final updatedPreferences = userContentPreferences
                                  .copyWith(
                                    followedCountries: updatedFollowedCountries,
                                  );

                              context.read<AppBloc>().add(
                                AppUserContentPreferencesChanged(
                                  preferences: updatedPreferences,
                                ),
                              );
                            } else {
                              // If the user is following, check the limit first.
                              final limitationService = context
                                  .read<ContentLimitationService>();
                              final status = limitationService.checkAction(
                                ContentAction.followCountry,
                              );

                              if (status == LimitationStatus.allowed) {
                                updatedFollowedCountries.add(country);
                                final updatedPreferences =
                                    userContentPreferences.copyWith(
                                      followedCountries:
                                          updatedFollowedCountries,
                                    );

                                context.read<AppBloc>().add(
                                  AppUserContentPreferencesChanged(
                                    preferences: updatedPreferences,
                                  ),
                                );
                              } else {
                                // If the limit is reached, show the bottom sheet.
                                showModalBottomSheet<void>(
                                  context: context,
                                  builder: (_) => ContentLimitationBottomSheet(
                                    status: status,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.paddingMedium,
                          vertical: AppSpacing.xs,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
