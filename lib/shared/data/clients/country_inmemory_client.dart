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
  }) : _decoratedClient = decoratedClient,
       _allSources = allSources,
       _allHeadlines = allHeadlines;

  final DataClient<Country> _decoratedClient;
  final List<Source> _allSources;
  final List<Headline> _allHeadlines;

  /// Filter key for checking if a country has active sources.
  static const String hasActiveSourcesFilter = 'hasActiveSources';

  /// Filter key for checking if a country has active headlines.
  static const String hasActiveHeadlinesFilter = 'hasActiveHeadlines';

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
    // Fetch ALL items from the decorated client first,
    // then apply custom filters, and finally apply pagination.
    // This ensures correct pagination behavior with custom filters.
    final allItemsResponse = await _decoratedClient.readAll(
      userId: userId,
      filter: filter,
      // Pass null for pagination to get all items, as custom filters
      // need to operate on the complete dataset before pagination.
      pagination: null,
      sort: sort,
    );

    Iterable<Country> filteredCountriesIterable = allItemsResponse.data.items;

    // Apply custom filters if present
    final hasActiveSources = filter?[hasActiveSourcesFilter] == true;
    final hasActiveHeadlines = filter?[hasActiveHeadlinesFilter] == true;

    if (hasActiveSources) {
      final countriesWithActiveSources = _allSources
          .where((source) => source.status == ContentStatus.active)
          .map((source) => source.headquarters.id)
          .toSet();

      filteredCountriesIterable = filteredCountriesIterable.where(
        (country) => countriesWithActiveSources.contains(country.id),
      );
    }

    if (hasActiveHeadlines) {
      final countriesWithActiveHeadlines = _allHeadlines
          .where((headline) => headline.status == ContentStatus.active)
          .map((headline) => headline.eventCountry.id)
          .toSet();

      filteredCountriesIterable = filteredCountriesIterable.where(
        (country) => countriesWithActiveHeadlines.contains(country.id),
      );
    }

    // Manually apply pagination to the filtered list.
    final offset = pagination?.cursor != null
        ? int.tryParse(pagination!.cursor!) ?? 0
        : 0;
    final limit = pagination?.limit ?? filteredCountriesIterable.length;

    final paginatedItems = filteredCountriesIterable
        .skip(offset)
        .take(limit)
        .toList();

    final hasMore = (offset + limit) < filteredCountriesIterable.length;
    final nextCursor = hasMore ? (offset + limit).toString() : null;

    // Return a new PaginatedResponse with the correctly filtered and paginated items.
    return SuccessApiResponse(
      data: PaginatedResponse(
        items: paginatedItems,
        cursor: nextCursor,
        hasMore: hasMore,
      ),
      metadata: allItemsResponse.metadata,
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
