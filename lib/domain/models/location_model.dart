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

  const AppLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    this.district,
    this.country,
    this.isManual = false,
  });

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
  }) {
    return AppLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      district: district ?? this.district,
      country: country ?? this.country,
      isManual: isManual ?? this.isManual,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'district': district,
        'country': country,
        'isManual': isManual,
      };

  factory AppLocation.fromJson(Map<String, dynamic> json) => AppLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        city: json['city'] as String?,
        district: json['district'] as String?,
        country: json['country'] as String?,
        isManual: json['isManual'] as bool? ?? false,
      );

  @override
  List<Object?> get props =>
      [latitude, longitude, city, district, country, isManual];
}
