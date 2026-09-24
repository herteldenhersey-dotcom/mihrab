import 'package:equatable/equatable.dart';

/// A resolved geographic location used for prayer-time and mosque queries.
class AppLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? city;
  final String? district;
  final String? country;

  /// Whether this location was picked manually by the user (vs. GPS).
  final bool isManual;

  /// The IANA timezone identifier for this location (e.g. "Europe/Istanbul",
  /// "America/New_York").  Nullable for backward compatibility with previously
  /// persisted locations that pre-date Phase 4.  When null, HomeCubit falls
  /// back to the last successfully resolved/cached timezone ID.
  ///
  /// Phase 4 Design: stored here so the timezone travels with the location
  /// through the DI graph without additional lookups on every Home rebuild.
  final String? timezoneId;

  const AppLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    this.district,
    this.country,
    this.isManual = false,
    this.timezoneId,
  });

  /// Whether [latitude]/[longitude] are finite and within valid Earth bounds.
  ///
  /// Rejects NaN, +/-infinity and impossible coordinates (|lat| > 90 or
  /// |lng| > 180). Used to guard against malformed GPS reads or third-party
  /// geocoder responses BEFORE a location is persisted or used for prayer
  /// calculation.
  static bool isValidCoordinate(double latitude, double longitude) =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90.0 &&
      longitude.abs() <= 180.0;

  /// Whether this location's coordinates pass [isValidCoordinate].
  bool get hasValidCoordinates => isValidCoordinate(latitude, longitude);

  /// A coarse cache key (~1.1 km precision) used for mosque/prayer caching.
  String get cacheKey =>
      '${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}';

  String get displayName {
    final parts = [district, city, country]
        .where((e) => e != null && e.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }
    return parts.join(', ');
  }

  AppLocation copyWith({
    double? latitude,
    double? longitude,
    String? city,
    String? district,
    String? country,
    bool? isManual,
    Object? timezoneId = _sentinel,
  }) {
    return AppLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      district: district ?? this.district,
      country: country ?? this.country,
      isManual: isManual ?? this.isManual,
      timezoneId:
          timezoneId == _sentinel ? this.timezoneId : timezoneId as String?,
    );
  }

  static const Object _sentinel = Object();

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'district': district,
        'country': country,
        'isManual': isManual,
        'timezoneId': timezoneId,
      };

  factory AppLocation.fromJson(Map<String, dynamic> json) => AppLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        city: json['city'] as String?,
        district: json['district'] as String?,
        country: json['country'] as String?,
        isManual: json['isManual'] as bool? ?? false,
        timezoneId: json['timezoneId'] as String?,
      );

  @override
  List<Object?> get props =>
      [latitude, longitude, city, district, country, isManual, timezoneId];
}
