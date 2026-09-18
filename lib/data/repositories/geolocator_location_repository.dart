import 'dart:async';

import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/enums/location_permission_status.dart';
import '../../domain/models/location_model.dart';
import '../../domain/repositories/location_repository.dart';

/// [LocationRepository] backed by `geolocator` + `geocoding`.
///
/// Accuracy policy: we request a SINGLE `LocationAccuracy.high` fix with a 15 s
/// time limit — a one-time read, never continuous tracking and never a
/// background stream. "high" (≈10 m) is the battery-sensible choice for a
/// one-shot prayer-time/qibla fix: it is accurate enough to resolve the correct
/// city/district yet, because we take exactly one sample and stop, it costs a
/// negligible amount of battery compared with `best`/`bestForNavigation`
/// continuous modes.
class GeolocatorLocationRepository implements LocationRepository {
  static const Duration _fixTimeout = Duration(seconds: 15);

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
  Future<LocationPermissionStatus> requestPermission() async {
    // Services must be on before a permission is meaningful; report that first
    // so the UI can send the user to the correct (services) settings screen.
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationPermissionStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.permanentlyDenied;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.denied;
    }
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
          timeLimit: _fixTimeout,
        ),
      );
      // Guard against malformed reads before they propagate any further.
      if (!AppLocation.isValidCoordinate(
          position.latitude, position.longitude)) {
        throw const LocationException('Geçersiz konum verisi alındı');
      }
      return await reverseGeocode(position.latitude, position.longitude);
    } on TimeoutException catch (e) {
      throw TimeoutAppException('Konum zaman aşımına uğradı', cause: e);
    } on LocationException {
      rethrow;
    } on PermissionException {
      rethrow;
    } catch (e) {
      // geolocator throws a plain TimeoutException subtype on some platforms.
      if (e.runtimeType.toString().contains('Timeout')) {
        throw TimeoutAppException('Konum zaman aşımına uğradı', cause: e);
      }
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

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
