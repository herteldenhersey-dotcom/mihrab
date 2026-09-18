import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/prayer_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/location_utils.dart';
import '../../../domain/models/mosque_model.dart';

/// Talks to the public Overpass API (OpenStreetMap) to find mosques.
///
/// Robustness features required by the spec:
///  * 10s timeout per request (configured on the Dio instance)
///  * up to [PrayerConstants.overpassMaxRetries] retries with exponential
///    backoff
///  * dual-endpoint fallback (overpass-api.de → kumi.systems)
///  * precise mapping of HTTP 429 / timeouts / 5xx to typed exceptions so the
///    repository can decide to serve cached data.
class OverpassApiDataSource {
  final Dio _dio;

  OverpassApiDataSource(this._dio);

  /// Fetches mosques (`amenity=place_of_worship` + `religion=muslim`) within
  /// [radiusMeters] of the point. Returns them sorted by distance.
  Future<List<Mosque>> fetchNearbyMosques({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    final query = _buildQuery(latitude, longitude, radiusMeters);

    Object? lastError;
    for (final endpoint in AppConstants.overpassEndpoints) {
      for (int attempt = 0;
          attempt <= PrayerConstants.overpassMaxRetries;
          attempt++) {
        try {
          final response = await _dio.post<dynamic>(
            endpoint,
            data: {'data': query},
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
            ),
          );

          final status = response.statusCode ?? 0;
          if (status == 429) {
            throw RateLimitException(
              'Overpass rate limited (429)',
              statusCode: status,
            );
          }
          if (status < 200 || status >= 300) {
            throw ServerException(
              'Overpass returned HTTP $status',
              statusCode: status,
            );
          }

          return _parse(response.data, latitude, longitude);
        } on RateLimitException catch (e) {
          // Don't hammer a rate-limited endpoint: break to the next endpoint.
          lastError = e;
          break;
        } on DioException catch (e) {
          lastError = _mapDioError(e);
          final isTimeout = e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout;
          // Retry on timeout/connection issues with exponential backoff.
          if (attempt < PrayerConstants.overpassMaxRetries) {
            await Future<void>.delayed(
              PrayerConstants.retryBaseDelay * (1 << attempt),
            );
            continue;
          }
          if (isTimeout) break; // try next endpoint
        } on ServerException catch (e) {
          lastError = e;
          if (attempt < PrayerConstants.overpassMaxRetries) {
            await Future<void>.delayed(
              PrayerConstants.retryBaseDelay * (1 << attempt),
            );
            continue;
          }
          break;
        } catch (e) {
          lastError = ParseException('Failed to parse Overpass response',
              cause: e);
          break;
        }
      }
    }

    // Exhausted all endpoints/retries.
    if (lastError is AppException) throw lastError;
    throw NetworkException('Overpass request failed', cause: lastError);
  }

  /// Overpass QL: mosques as node/way/relation with muslim place_of_worship.
  String _buildQuery(double lat, double lng, int radius) {
    return '''
[out:json][timeout:${PrayerConstants.overpassTimeout.inSeconds}];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$lat,$lng);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$lat,$lng);
  relation["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$lat,$lng);
);
out center tags;
''';
  }

  List<Mosque> _parse(dynamic data, double originLat, double originLng) {
    if (data is! Map || data['elements'] is! List) {
      throw const ParseException('Unexpected Overpass payload shape');
    }
    final elements = data['elements'] as List;
    final mosques = <Mosque>[];

    for (final el in elements) {
      if (el is! Map) continue;
      double? lat = (el['lat'] as num?)?.toDouble();
      double? lng = (el['lon'] as num?)?.toDouble();
      // ways/relations expose coordinates under `center`.
      if (lat == null || lng == null) {
        final center = el['center'];
        if (center is Map) {
          lat = (center['lat'] as num?)?.toDouble();
          lng = (center['lon'] as num?)?.toDouble();
        }
      }
      if (lat == null || lng == null) continue;

      final tags = (el['tags'] as Map?) ?? const {};
      final name = (tags['name'] ?? tags['name:tr'] ?? 'Cami').toString();
      final address = _composeAddress(tags);
      final distance = LocationUtils.distanceMeters(
        originLat,
        originLng,
        lat,
        lng,
      );

      mosques.add(
        Mosque(
          id: '${el['type']}/${el['id']}',
          name: name,
          latitude: lat,
          longitude: lng,
          address: address,
          distanceMeters: distance,
        ),
      );
    }

    mosques.sort((a, b) =>
        (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
    return mosques;
  }

  String? _composeAddress(Map tags) {
    final parts = [
      tags['addr:street'],
      tags['addr:housenumber'],
      tags['addr:neighbourhood'] ?? tags['addr:suburb'],
      tags['addr:district'],
      tags['addr:city'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  AppException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return TimeoutAppException('Overpass request timed out', cause: e);
      case DioExceptionType.connectionError:
        return NetworkException('No connection to Overpass', cause: e);
      default:
        final code = e.response?.statusCode;
        if (code == 429) {
          return RateLimitException('Overpass rate limited',
              statusCode: code);
        }
        return ServerException('Overpass error', statusCode: code, cause: e);
    }
  }
}
