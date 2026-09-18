import 'package:equatable/equatable.dart';

/// A mosque returned by a [MosqueRepository] (e.g. from Overpass/OSM).
class Mosque extends Equatable {
  /// Provider-specific id (e.g. OSM element id as string).
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;

  /// Distance in meters from the query location, if computed.
  final double? distanceMeters;

  const Mosque({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.distanceMeters,
  });

  Mosque copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    double? distanceMeters,
  }) {
    return Mosque(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'distanceMeters': distanceMeters,
      };

  factory Mosque.fromJson(Map<String, dynamic> json) => Mosque(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] as String?,
        distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props =>
      [id, name, latitude, longitude, address, distanceMeters];
}
