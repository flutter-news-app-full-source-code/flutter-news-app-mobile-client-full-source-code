import 'package:core/core.dart';
import 'package:data_client/data_client.dart';

/// {@template country_inmemory_client}
/// A specialized in-memory data client for [Country] models that extends
/// the functionality of a generic [DataClient<Country>] by adding custom
/// filtering logic for `hasActiveSources` and `hasActiveHeadlines` filters.
///
/// This client acts as a decorator, wrapping an existing [DataClient<Country>]
/// (typically [DataInMemory<Country>]) and intercepting `readAll` calls
/// to apply application-specific filtering using static fixture data.
/// All other [DataClient] methods are delegated directly to the wrapped client.
/// {@endtemplate}
class CountryInMemoryClient implements DataClient<Country> {
  /// {@macro country_inmemory_client}
  ///
  /// Requires a [decoratedClient] to which standard data operations will be
  /// delegated. Also requires [allSources] and [allHeadlines] (typically
  /// static fixture data from the `core` package) to perform custom filtering.
  const CountryInMemoryClient({
    required DataClient<Country> decoratedClient,
    required List<Source> allSources,
    required List<Headline> allHeadlines,
  })  : _decoratedClient = decoratedClient,
        _allSources = allSources,
        _allHeadlines = allHeadlines;

  final DataClient<Country> _decoratedClient;
  final List<Source> _allSources;
  final List<Headline> _allHeadlines;

  @override
  Future<SuccessApiResponse<List<Map<String, dynamic>>>> aggregate({
    required List<Map<String, dynamic>> pipeline,
    String? userId,
  }) {
    return _decoratedClient.aggregate(pipeline: pipeline, userId: userId);
  }

  @override
  Future<SuccessApiResponse<int>> count({
    String? userId,
    Map<String, dynamic>? filter,
  }) {
    return _decoratedClient.count(userId: userId, filter: filter);
  }

  @override
  Future<SuccessApiResponse<Country>> create({
    required Country item,
    String? userId,
  }) {
    return _decoratedClient.create(item: item, userId: userId);
  }

  @override
  Future<void> delete({required String id, String? userId}) {
    return _decoratedClient.delete(id: id, userId: userId);
  }

  @override
  Future<SuccessApiResponse<Country>> read({
    required String id,
    String? userId,
  }) {
    return _decoratedClient.read(id: id, userId: userId);
  }

  @override
  Future<SuccessApiResponse<PaginatedResponse<Country>>> readAll({
    String? userId,
    Map<String, dynamic>? filter,
    PaginationOptions? pagination,
    List<SortOption>? sort,
  }) async {
    // First, get the initial list of countries from the decorated client.
    // This handles generic filters, sorting, and pagination.
    final response = await _decoratedClient.readAll(
      userId: userId,
      filter: filter,
      pagination: pagination,
      sort: sort,
    );

    var filteredCountries = response.data.items;

    // Apply custom filters if present
    final hasActiveSources = filter?['hasActiveSources'] == true;
    final hasActiveHeadlines = filter?['hasActiveHeadlines'] == true;

    if (hasActiveSources) {
      final countriesWithActiveSources = _allSources
          .where((source) => source.status == ContentStatus.active)
          .map((source) => source.headquarters.id)
          .toSet();

      filteredCountries = filteredCountries
          .where(
            (country) => countriesWithActiveSources.contains(country.id),
          )
          .toList();
    }

    if (hasActiveHeadlines) {
      final countriesWithActiveHeadlines = _allHeadlines
          .where((headline) => headline.status == ContentStatus.active)
          .map((headline) => headline.eventCountry.id)
          .toSet();

      filteredCountries = filteredCountries
          .where(
            (country) => countriesWithActiveHeadlines.contains(country.id),
          )
          .toList();
    }

    // Return a new PaginatedResponse with the potentially further filtered items.
    // The cursor and hasMore logic from the original response are preserved,
    // but the items list is updated.
    return SuccessApiResponse(
      data: response.data.copyWith(items: filteredCountries),
      metadata: response.metadata,
    );
  }

  @override
  Future<SuccessApiResponse<Country>> update({
    required String id,
    required Country item,
    String? userId,
  }) {
    return _decoratedClient.update(id: id, item: item, userId: userId);
  }
}
