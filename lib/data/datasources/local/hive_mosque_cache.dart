import 'package:hive/hive.dart';

import '../../../domain/models/mosque_model.dart';
import 'hive_adapters.dart';
import 'hive_boxes.dart';

/// Local cache for nearby-mosque results, keyed by a coarse location key.
class HiveMosqueCache {
  Box<MosqueCacheEntry> get _box =>
      Hive.box<MosqueCacheEntry>(HiveBoxes.mosqueCache);

  String _key(String locationKey, int radiusMeters) =>
      '${locationKey}_$radiusMeters';

  /// Returns the cache entry for a location, or null if absent.
  MosqueCacheEntry? get(String locationKey, int radiusMeters) =>
      _box.get(_key(locationKey, radiusMeters));

  Future<void> put(
    String locationKey,
    int radiusMeters,
    List<Mosque> mosques,
  ) async {
    await _box.put(
      _key(locationKey, radiusMeters),
      MosqueCacheEntry(cachedAt: DateTime.now(), mosques: mosques),
    );
  }

  Future<void> clear() => _box.clear();
}
