import '../models/mosque_model.dart';

/// Abstraction over nearby-mosque discovery.
///
/// V1 implementation is [OverpassMosqueRepository] (OpenStreetMap). A
/// [GooglePlacesMosqueRepository] stub exists for a future provider swap.
abstract class MosqueRepository {
  /// Returns mosques within [radiusMeters] of the given point, nearest first.
  ///
  /// Implementations should: apply timeouts, retry with backoff, cache
  /// results, and gracefully fall back to cached data on rate-limit/timeout.
  /// Throws a mapped [Failure] only when no data (fresh or cached) is
  /// available.
  Future<List<Mosque>> getNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusMeters = 3000,
    bool forceRefresh = false,
  });
}
