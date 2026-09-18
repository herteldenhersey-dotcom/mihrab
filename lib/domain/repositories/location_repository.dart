import '../enums/location_permission_status.dart';
import '../models/location_model.dart';

/// Abstraction over device location + geocoding.
abstract class LocationRepository {
  /// Whether location services are enabled at the OS level.
  Future<bool> isLocationServiceEnabled();

  /// Requests location permission if needed. Returns true if granted.
  ///
  /// Kept for the simple GPS→saved→default fallback used by [LocationService].
  /// New onboarding code should prefer [requestPermission] for explicit states.
  Future<bool> ensurePermission();

  /// Requests permission (asking the OS if needed) and returns an explicit,
  /// provider-agnostic [LocationPermissionStatus] so the presentation layer can
  /// distinguish granted / denied / permanently-denied / services-disabled
  /// without relying on booleans.
  Future<LocationPermissionStatus> requestPermission();

  /// Gets the current device position and reverse-geocodes it.
  Future<AppLocation> getCurrentLocation();

  /// Reverse-geocodes arbitrary coordinates into an [AppLocation].
  Future<AppLocation> reverseGeocode(double latitude, double longitude);

  /// Opens the OS app-settings screen (for a permanently-denied permission).
  /// Returns true if the screen was opened.
  Future<bool> openAppSettings();

  /// Opens the OS location-services settings screen (for disabled GPS).
  /// Returns true if the screen was opened.
  Future<bool> openLocationSettings();
}
