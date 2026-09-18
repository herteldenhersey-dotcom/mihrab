import '../models/mosque_model.dart';
import '../repositories/mosque_repository.dart';

class GetNearbyMosquesUseCase {
  final MosqueRepository _repository;

  GetNearbyMosquesUseCase(this._repository);

  Future<List<Mosque>> call({
    required double latitude,
    required double longitude,
    int radiusMeters = 3000,
    bool forceRefresh = false,
  }) {
    return _repository.getNearbyMosques(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      forceRefresh: forceRefresh,
    );
  }
}
