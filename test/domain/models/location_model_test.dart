import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/models/location_model.dart';
import 'package:mihrab/domain/models/location_search_result.dart';

void main() {
  group('AppLocation.isValidCoordinate', () {
    test('accepts normal coordinates and boundaries', () {
      expect(AppLocation.isValidCoordinate(41.0082, 28.9784), isTrue);
      expect(AppLocation.isValidCoordinate(0, 0), isTrue);
      expect(AppLocation.isValidCoordinate(90, 180), isTrue);
      expect(AppLocation.isValidCoordinate(-90, -180), isTrue);
    });

    test('rejects NaN and infinity', () {
      expect(AppLocation.isValidCoordinate(double.nan, 0), isFalse);
      expect(AppLocation.isValidCoordinate(0, double.nan), isFalse);
      expect(AppLocation.isValidCoordinate(double.infinity, 0), isFalse);
      expect(
          AppLocation.isValidCoordinate(0, double.negativeInfinity), isFalse);
    });

    test('rejects out-of-range coordinates', () {
      expect(AppLocation.isValidCoordinate(90.1, 0), isFalse);
      expect(AppLocation.isValidCoordinate(-91, 0), isFalse);
      expect(AppLocation.isValidCoordinate(0, 180.5), isFalse);
      expect(AppLocation.isValidCoordinate(0, -181), isFalse);
    });

    test('hasValidCoordinates reflects the static check', () {
      expect(
          const AppLocation(latitude: 41, longitude: 29).hasValidCoordinates,
          isTrue);
      expect(
          const AppLocation(latitude: 999, longitude: 0).hasValidCoordinates,
          isFalse);
    });
  });

  group('AppLocation.displayName', () {
    test('joins available admin fields', () {
      const loc = AppLocation(
        latitude: 41,
        longitude: 29,
        district: 'Fatih',
        city: 'İstanbul',
        country: 'Türkiye',
      );
      expect(loc.displayName, 'Fatih, İstanbul, Türkiye');
    });

    test('falls back to coordinates when no address fields', () {
      const loc = AppLocation(latitude: 41.0082, longitude: 28.9784);
      expect(loc.displayName, '41.0082, 28.9784');
    });
  });

  group('AppLocation JSON round-trip', () {
    test('serializes and deserializes all fields including isManual', () {
      const loc = AppLocation(
        latitude: 52.52,
        longitude: 13.405,
        city: 'Berlin',
        district: 'Mitte',
        country: 'Germany',
        isManual: true,
      );
      final restored = AppLocation.fromJson(loc.toJson());
      expect(restored, loc);
      expect(restored.isManual, isTrue);
    });

    test('fromJson defaults isManual to false when absent (backward compat)',
        () {
      final restored = AppLocation.fromJson(const {
        'latitude': 41.0,
        'longitude': 29.0,
      });
      expect(restored.isManual, isFalse);
      expect(restored.latitude, 41.0);
    });
  });

  group('LocationSearchResult', () {
    test('toAppLocation marks the location manual', () {
      const r = LocationSearchResult(
        latitude: 52.52,
        longitude: 13.405,
        city: 'Berlin',
        country: 'Germany',
        displayName: 'Berlin, Germany',
      );
      final loc = r.toAppLocation();
      expect(loc.isManual, isTrue);
      expect(loc.city, 'Berlin');
      expect(loc.hasValidCoordinates, isTrue);
    });

    test('hasValidCoordinates catches malformed provider rows', () {
      expect(
          const LocationSearchResult(
                  latitude: 200, longitude: 0, displayName: 'x')
              .hasValidCoordinates,
          isFalse);
    });
  });
}
