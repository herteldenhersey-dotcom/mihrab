import '../models/location_model.dart';

/// Abstraction over device location + geocoding.
abstract class LocationRepository {
  /// Whether location services are enabled at the OS level.
  Future<bool> isLocationServiceEnabled();

  /// Requests location permission if needed. Returns true if granted.
  Future<bool> ensurePermission();

  /// Gets the current device position and reverse-geocodes it.
  Future<AppLocation> getCurrentLocation();

  /// Reverse-geocodes arbitrary coordinates into an [AppLocation].
  Future<AppLocation> reverseGeocode(double latitude, double longitude);
}
