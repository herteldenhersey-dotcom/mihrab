import '../../domain/models/mosque_model.dart';
import '../../domain/repositories/mosque_repository.dart';

/// STUB — future Google Places provider for mosque search.
///
/// Intentionally unimplemented in V1. The [MosqueRepository] abstraction lets
/// us swap OpenStreetMap/Overpass for Google Places later WITHOUT touching the
/// domain or presentation layers. When implementing:
///   * read the API key from `flutter_dotenv` (`GOOGLE_MAPS_API_KEY`)
///   * use the Places Nearby Search endpoint (type=mosque)
///   * apply the same caching/retry policy as [OverpassMosqueRepository].
class GooglePlacesMosqueRepository implements MosqueRepository {
  @override
  Future<List<Mosque>> getNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusMeters = 3000,
    bool forceRefresh = false,
  }) {
    throw UnimplementedError(
      'GooglePlacesMosqueRepository is a Phase-2+ stub. '
      'Configure GOOGLE_MAPS_API_KEY and implement Places Nearby Search.',
    );
  }
}
