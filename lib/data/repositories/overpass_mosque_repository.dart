import '../../core/constants/prayer_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/models/location_model.dart';
import '../../domain/models/mosque_model.dart';
import '../../domain/repositories/mosque_repository.dart';
import '../datasources/local/hive_mosque_cache.dart';
import '../datasources/remote/overpass_api_datasource.dart';

/// [MosqueRepository] backed by OpenStreetMap via Overpass.
///
/// Strategy:
///  1. If [forceRefresh] is false and a fresh (<24h) cache entry exists,
///     return it immediately.
///  2. Otherwise hit the network (with retry + dual-endpoint fallback).
///  3. On success, update the cache and return.
///  4. On rate-limit/timeout/network error, gracefully fall back to ANY
///     cached data (even stale). Only throw a [Failure] when there is no
///     cached data to serve.
class OverpassMosqueRepository implements MosqueRepository {
  final OverpassApiDataSource _remote;
  final HiveMosqueCache _cache;

  OverpassMosqueRepository(this._remote, this._cache);

  @override
  Future<List<Mosque>> getNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusMeters = 3000,
    bool forceRefresh = false,
  }) async {
    final locationKey = AppLocation(
      latitude: latitude,
      longitude: longitude,
    ).cacheKey;

    final cached = _cache.get(locationKey, radiusMeters);

    if (!forceRefresh &&
        cached != null &&
        cached.isFresh(PrayerConstants.mosqueCacheTtl)) {
      return cached.mosques;
    }

    try {
      final mosques = await _remote.fetchNearbyMosques(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );
      await _cache.put(locationKey, radiusMeters, mosques);
      return mosques;
    } on AppException catch (e) {
      // Graceful degradation: serve stale cache if we have it.
      if (cached != null) {
        return cached.mosques;
      }
      throw mapExceptionToFailure(e);
    } catch (e) {
      if (cached != null) {
        return cached.mosques;
      }
      throw mapExceptionToFailure(e);
    }
  }
}
