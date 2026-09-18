import 'dart:async';

import 'package:geocoding/geocoding.dart' as geo;

import '../../core/errors/exceptions.dart';
import '../../domain/models/location_model.dart';
import '../../domain/models/location_search_result.dart';
import '../../domain/repositories/location_search_repository.dart';

/// [LocationSearchRepository] backed by the platform geocoder (`geocoding`).
///
/// DATA-SOURCE DECISION (documented in the Phase 3 report):
/// manual selection uses FORWARD geocoding of a free-text query rather than a
/// cascading Country→City→District picker. A cascading picker needs a complete,
/// licensed, regularly-updated offline admin-hierarchy dataset (large) or a
/// paid places API. Forward geocoding via the OS geocoder is international out
/// of the box, ships no extra dataset, is already a dependency, and needs no
/// backend or API key. The trade-off — it sends the typed query to the
/// platform geocoder (Android: Google/'`Geocoder`'; iOS: Apple `CLGeocoder`) —
/// is disclosed for the Privacy Policy / Data Safety form. The
/// [LocationSearchRepository] abstraction keeps this swappable for a bundled
/// dataset or REST API in a later phase.
///
/// Flow per query: forward-geocode the text → coordinates, then reverse-geocode
/// each coordinate to enrich it with country/city/district for a readable label.
class GeocodingLocationSearchRepository implements LocationSearchRepository {
  final geo.Geocoding _geocoding;

  GeocodingLocationSearchRepository({geo.Geocoding? geocoding})
      : _geocoding = geocoding ?? geo.Geocoding();

  @override
  Future<List<LocationSearchResult>> search(String query,
      {int limit = 6}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final List<geo.Location> matches;
    try {
      matches = await _geocoding.locationFromAddress(trimmed);
    } on TimeoutException catch (e) {
      throw TimeoutAppException('Arama zaman aşımına uğradı', cause: e);
    } catch (e) {
      // The platform geocoder throws a `PlatformException`/`NoResultFoundException`
      // both for "no results" and for transport failures. Treat a clearly
      // empty-result message as an empty list; otherwise surface a network
      // error so the UI can offer "try again".
      final text = e.toString().toLowerCase();
      if (text.contains('not_found') ||
          text.contains('no result') ||
          text.contains('null')) {
        return const [];
      }
      throw NetworkException('Konum araması başarısız oldu', cause: e);
    }

    final results = <LocationSearchResult>[];
    final seen = <String>{};

    for (final m in matches.take(limit)) {
      if (!AppLocation.isValidCoordinate(m.latitude, m.longitude)) {
        // Skip malformed third-party rows rather than crashing.
        continue;
      }
      final result = await _enrich(m.latitude, m.longitude, trimmed);
      // De-duplicate by ~1 km bucket so identical hits don't repeat.
      final key =
          '${result.latitude.toStringAsFixed(2)}_${result.longitude.toStringAsFixed(2)}';
      if (seen.add(key)) results.add(result);
    }
    return results;
  }

  /// Reverse-geocodes coordinates to add admin fields. Best-effort: on failure
  /// we still return a usable result labelled with the user's query.
  Future<LocationSearchResult> _enrich(
      double latitude, double longitude, String fallbackLabel) async {
    try {
      final placemarks =
          await _geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city = p.administrativeArea?.trim().isNotEmpty == true
            ? p.administrativeArea
            : p.locality;
        final district = p.subAdministrativeArea?.trim().isNotEmpty == true
            ? p.subAdministrativeArea
            : p.subLocality;
        final country = p.country;
        final label = [district, city, country]
            .where((e) => e != null && e.trim().isNotEmpty)
            .join(', ');
        return LocationSearchResult(
          latitude: latitude,
          longitude: longitude,
          city: city,
          district: district,
          country: country,
          displayName: label.isNotEmpty ? label : fallbackLabel,
        );
      }
    } catch (_) {
      // fall through to coordinate-only result
    }
    return LocationSearchResult(
      latitude: latitude,
      longitude: longitude,
      displayName: fallbackLabel,
    );
  }
}
