import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/models/location_model.dart';
import '../../domain/repositories/location_repository.dart';

/// [LocationRepository] backed by `geolocator` + `geocoding`.
class GeolocatorLocationRepository implements LocationRepository {
  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<bool> ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<AppLocation> getCurrentLocation() async {
    if (!await isLocationServiceEnabled()) {
      throw const LocationException('Konum servisleri kapalı');
    }
    if (!await ensurePermission()) {
      throw const PermissionException('Konum izni verilmedi');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return await reverseGeocode(position.latitude, position.longitude);
    } on LocationException {
      rethrow;
    } on PermissionException {
      rethrow;
    } catch (e) {
      throw LocationException('Konum alınamadı', cause: e);
    }
  }

  @override
  Future<AppLocation> reverseGeocode(double latitude, double longitude) async {
    try {
      // geocoding 5.x exposes these via a Geocoding instance (was a top-level
      // function in 3.x).
      final placemarks =
          await geo.Geocoding().placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        return AppLocation(latitude: latitude, longitude: longitude);
      }
      final p = placemarks.first;
      return AppLocation(
        latitude: latitude,
        longitude: longitude,
        city: p.administrativeArea?.trim().isNotEmpty == true
            ? p.administrativeArea
            : p.locality,
        district: p.subAdministrativeArea?.trim().isNotEmpty == true
            ? p.subAdministrativeArea
            : p.subLocality,
        country: p.country,
      );
    } catch (_) {
      // Geocoding is best-effort; coordinates alone are still usable.
      return AppLocation(latitude: latitude, longitude: longitude);
    }
  }
}
