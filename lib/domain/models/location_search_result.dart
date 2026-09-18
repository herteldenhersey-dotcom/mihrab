import 'package:equatable/equatable.dart';

import 'location_model.dart';

/// A single manual-search suggestion resolved to real coordinates.
///
/// This is a DOMAIN type: the `LocationSearchRepository` implementation maps
/// whatever the underlying provider returns (platform geocoder placemarks,
/// bundled dataset rows, a future REST API, …) onto this shape so no
/// provider-specific object ever leaks into the presentation layer.
class LocationSearchResult extends Equatable {
  final double latitude;
  final double longitude;
  final String? country;
  final String? city;
  final String? district;

  /// A human-readable label for the suggestion list (already composed by the
  /// repository from the best available admin fields).
  final String displayName;

  const LocationSearchResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    this.country,
    this.city,
    this.district,
  });

  /// Whether the resolved coordinates are usable (finite, within Earth bounds).
  bool get hasValidCoordinates =>
      AppLocation.isValidCoordinate(latitude, longitude);

  /// Converts this suggestion into a persistable [AppLocation] flagged as a
  /// manual selection.
  AppLocation toAppLocation() => AppLocation(
        latitude: latitude,
        longitude: longitude,
        city: city,
        district: district,
        country: country,
        isManual: true,
      );

  @override
  List<Object?> get props =>
      [latitude, longitude, country, city, district, displayName];
}
