import '../../../core/constants/app_constants.dart';
import '../../../domain/models/location_model.dart';
import '../../../domain/repositories/location_repository.dart';
import '../../../domain/repositories/settings_repository.dart';

/// High-level location facade: resolves the "best available" location with a
/// graceful fallback chain (GPS → last saved → hard-coded default city).
///
/// Keeps UI/cubits from having to orchestrate permission + persistence logic.
class LocationService {
  final LocationRepository _locationRepo;
  final SettingsRepository _settingsRepo;

  LocationService(this._locationRepo, this._settingsRepo);

  /// Attempts GPS; on failure returns the last saved location; if none, the
  /// default (Istanbul). Successful GPS reads are persisted for next launch.
  Future<AppLocation> resolveBestLocation() async {
    try {
      final current = await _locationRepo.getCurrentLocation();
      await _settingsRepo.saveLocation(current);
      return current;
    } catch (_) {
      final saved = await _settingsRepo.getSavedLocation();
      if (saved != null) return saved;
      return const AppLocation(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
        city: AppConstants.defaultCity,
        country: AppConstants.defaultCountry,
      );
    }
  }

  Future<bool> ensurePermission() => _locationRepo.ensurePermission();

  Future<bool> isServiceEnabled() =>
      _locationRepo.isLocationServiceEnabled();
}
