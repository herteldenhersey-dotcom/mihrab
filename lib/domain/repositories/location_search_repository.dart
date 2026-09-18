import '../models/location_search_result.dart';

/// Abstraction over the manual location-search backend.
///
/// Keeps the search provider swappable (platform geocoder today; a bundled
/// dataset or REST API later) without touching the domain/presentation layers.
/// Implementations translate transport/parse errors into the app's
/// [AppException] hierarchy so callers can render localized messages.
abstract class LocationSearchRepository {
  /// Resolves a free-text query (city, district or country name) into a ranked
  /// list of coordinate-bearing suggestions.
  ///
  /// Returns an empty list when there are no matches (this is NOT an error).
  /// Throws a [NetworkException]/[TimeoutAppException] on connectivity issues
  /// and a [LocationException] for provider failures.
  Future<List<LocationSearchResult>> search(String query, {int limit = 6});
}
