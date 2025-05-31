import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ht_data_repository/ht_data_repository.dart';
import 'package:ht_main/account/bloc/account_bloc.dart';
import 'package:ht_main/l10n/l10n.dart';
import 'package:ht_main/shared/constants/app_spacing.dart';
import 'package:ht_main/shared/widgets/widgets.dart';
import 'package:ht_shared/ht_shared.dart';

/// {@template add_country_to_follow_page}
/// A page that allows users to browse and select countries to follow.
/// {@endtemplate}
class AddCountryToFollowPage extends StatefulWidget {
  /// {@macro add_country_to_follow_page}
  const AddCountryToFollowPage({super.key});

  @override
  State<AddCountryToFollowPage> createState() => _AddCountryToFollowPageState();
}

class _AddCountryToFollowPageState extends State<AddCountryToFollowPage> {
  List<Country> _allCountries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  Future<void> _fetchCountries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final countryRepository = context.read<HtDataRepository<Country>>();
      final paginatedResponse = await countryRepository.readAll();
      setState(() {
        _allCountries = paginatedResponse.items;
        _isLoading = false;
      });
    } on HtHttpException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = context.l10n.unknownError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addCountriesPageTitle),
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_errorMessage != null) {
            return FailureStateWidget(
              message: _errorMessage!,
              onRetry: _fetchCountries,
            );
          }
          if (_allCountries.isEmpty) {
            return FailureStateWidget(
              message: l10n.countryFilterEmptyHeadline,
            );
          }

          return BlocBuilder<AccountBloc, AccountState>(
            buildWhen: (previous, current) =>
                previous.preferences?.followedCountries != current.preferences?.followedCountries ||
                previous.status != current.status,
            builder: (context, accountState) {
              final followedCountries =
                  accountState.preferences?.followedCountries ?? [];

              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _allCountries.length,
                itemBuilder: (context, index) {
                  final country = _allCountries[index];
                  final isFollowed =
                      followedCountries.any((fc) => fc.id == country.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: country.flagUrl.isNotEmpty &&
                              Uri.tryParse(country.flagUrl)?.isAbsolute == true
                          ? SizedBox(
                              width: 36,
                              height: 24,
                              child: Image.network(
                                country.flagUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.public_outlined),
                              ),
                            )
                          : const Icon(Icons.public_outlined),
                      title: Text(country.name),
                      trailing: IconButton(
                        icon: isFollowed
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : const Icon(Icons.add_circle_outline),
                        tooltip: isFollowed
                            ? l10n.unfollowCountryTooltip(country.name)
                            : l10n.followCountryTooltip(country.name),
                        onPressed: () {
                          context.read<AccountBloc>().add(
                                AccountFollowCountryToggled(country: country),
                              );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
