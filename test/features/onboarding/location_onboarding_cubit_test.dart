import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/core/errors/exceptions.dart';
import 'package:mihrab/domain/enums/location_permission_status.dart';
import 'package:mihrab/domain/models/location_model.dart';
import 'package:mihrab/domain/models/location_search_result.dart';
import 'package:mihrab/domain/repositories/location_repository.dart';
import 'package:mihrab/domain/repositories/location_search_repository.dart';
import 'package:mihrab/features/onboarding/presentation/cubit/location_onboarding_cubit.dart';

import '../../helpers/fake_settings_repository.dart';

/// Programmable fake location repository — no real GPS, OS dialogs or platform
/// channels. Each behaviour is configured per test.
class _FakeLocationRepository implements LocationRepository {
  LocationPermissionStatus permission = LocationPermissionStatus.granted;
  AppLocation? currentLocation;
  Object? currentError;
  bool openAppSettingsCalled = false;
  bool openLocationSettingsCalled = false;

  @override
  Future<LocationPermissionStatus> requestPermission() async => permission;

  @override
  Future<AppLocation> getCurrentLocation() async {
    if (currentError != null) throw currentError!;
    return currentLocation!;
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCalled = true;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCalled = true;
    return true;
  }

  @override
  Future<bool> ensurePermission() async =>
      permission == LocationPermissionStatus.granted;

  @override
  Future<bool> isLocationServiceEnabled() async =>
      permission != LocationPermissionStatus.serviceDisabled;

  @override
  Future<AppLocation> reverseGeocode(double latitude, double longitude) async =>
      AppLocation(latitude: latitude, longitude: longitude);
}

class _FakeSearchRepository implements LocationSearchRepository {
  List<LocationSearchResult> results = const [];
  Object? error;
  String? lastQuery;

  @override
  Future<List<LocationSearchResult>> search(String query, {int limit = 6}) async {
    lastQuery = query;
    if (error != null) throw error!;
    return results;
  }
}

void main() {
  late _FakeLocationRepository location;
  late _FakeSearchRepository search;
  late FakeSettingsRepository settings;

  LocationOnboardingCubit build() =>
      LocationOnboardingCubit(location, search, settings);

  setUp(() {
    location = _FakeLocationRepository();
    search = _FakeSearchRepository();
    settings = FakeSettingsRepository();
  });

  const istanbul = AppLocation(
    latitude: 41.0082,
    longitude: 28.9784,
    city: 'İstanbul',
    country: 'Türkiye',
  );

  group('useMyLocation — permission & GPS flow (8)', () {
    test('granted → success, resolves and persists the location', () async {
      location.permission = LocationPermissionStatus.granted;
      location.currentLocation = istanbul;
      final cubit = build();

      await cubit.useMyLocation();

      expect(cubit.state.deviceStatus, DeviceLocationStatus.success);
      expect(cubit.state.resolved, istanbul);
      expect(await settings.getSavedLocation(), istanbul);
      await cubit.close();
    });

    test('service disabled → serviceDisabled state, nothing persisted',
        () async {
      location.permission = LocationPermissionStatus.serviceDisabled;
      final cubit = build();

      await cubit.useMyLocation();

      expect(cubit.state.deviceStatus, DeviceLocationStatus.serviceDisabled);
      expect(cubit.state.resolved, isNull);
      expect(await settings.getSavedLocation(), isNull);
      await cubit.close();
    });

    test('denied → permissionDenied state', () async {
      location.permission = LocationPermissionStatus.denied;
      final cubit = build();

      await cubit.useMyLocation();

      expect(cubit.state.deviceStatus, DeviceLocationStatus.permissionDenied);
      await cubit.close();
    });

    test('permanently denied → permissionPermanentlyDenied state', () async {
      location.permission = LocationPermissionStatus.permanentlyDenied;
      final cubit = build();

      await cubit.useMyLocation();

      expect(cubit.state.deviceStatus,
          DeviceLocationStatus.permissionPermanentlyDenied);
      await cubit.close();
    });

    test('timeout → timeout state', () async {
      location.permission = LocationPermissionStatus.granted;
      location.currentError = const TimeoutAppException('slow');
      final cubit = build();

      await cubit.useMyLocation();

      expect(cubit.state.deviceStatus, DeviceLocationStatus.timeout);
      await cubit.close();
    });

    test('generic LocationException → failure state', () async {
      location.permission = LocationPermissionStatus.granted;
      location.currentError = const LocationException('boom');
      final cubit = build();

      await cubit.useMyLocation();

      expect(cubit.state.deviceStatus, DeviceLocationStatus.failure);
      await cubit.close();
    });

    test('invalid coordinates from provider → failure, not persisted',
        () async {
      location.permission = LocationPermissionStatus.granted;
      location.currentLocation =
          const AppLocation(latitude: double.nan, longitude: 0);
      final cubit = build();

      await cubit.useMyLocation();

      expect(cubit.state.deviceStatus, DeviceLocationStatus.failure);
      expect(await settings.getSavedLocation(), isNull);
      await cubit.close();
    });

    test('openAppSettings / openLocationSettings delegate to repository',
        () async {
      final cubit = build();
      await cubit.openAppSettings();
      await cubit.openLocationSettings();
      expect(location.openAppSettingsCalled, isTrue);
      expect(location.openLocationSettingsCalled, isTrue);
      await cubit.close();
    });
  });

  group('manual search (7)', () {
    const berlin = LocationSearchResult(
      latitude: 52.52,
      longitude: 13.405,
      city: 'Berlin',
      country: 'Germany',
      displayName: 'Berlin, Germany',
    );

    test('results → results state with rows', () async {
      search.results = const [berlin];
      final cubit = build();

      await cubit.search('Berlin');

      expect(cubit.state.searchStatus, ManualSearchStatus.results);
      expect(cubit.state.results, [berlin]);
      await cubit.close();
    });

    test('empty results → empty state', () async {
      search.results = const [];
      final cubit = build();

      await cubit.search('Zzxx');

      expect(cubit.state.searchStatus, ManualSearchStatus.empty);
      await cubit.close();
    });

    test('network error → error state (no crash)', () async {
      search.error = const NetworkException('offline');
      final cubit = build();

      await cubit.search('Berlin');

      expect(cubit.state.searchStatus, ManualSearchStatus.error);
      await cubit.close();
    });

    test('query shorter than minimum → idle, no provider call', () async {
      final cubit = build();

      await cubit.search('B');

      expect(cubit.state.searchStatus, ManualSearchStatus.idle);
      expect(search.lastQuery, isNull);
      await cubit.close();
    });

    test('invalid-coordinate rows are filtered out', () async {
      search.results = const [
        LocationSearchResult(
          latitude: 200, // impossible
          longitude: 13,
          displayName: 'bad',
        ),
      ];
      final cubit = build();

      await cubit.search('bad');

      expect(cubit.state.searchStatus, ManualSearchStatus.empty);
      await cubit.close();
    });

    test('selectResult → persists as manual and resolves', () async {
      final cubit = build();

      await cubit.selectResult(berlin);

      expect(cubit.state.resolved, isNotNull);
      expect(cubit.state.resolved!.isManual, isTrue);
      expect(cubit.state.resolved!.city, 'Berlin');
      final saved = await settings.getSavedLocation();
      expect(saved!.isManual, isTrue);
      await cubit.close();
    });

    test('selectResult with invalid coordinates → error, not persisted',
        () async {
      final cubit = build();

      await cubit.selectResult(const LocationSearchResult(
          latitude: double.infinity, longitude: 0, displayName: 'x'));

      expect(cubit.state.searchStatus, ManualSearchStatus.error);
      expect(await settings.getSavedLocation(), isNull);
      await cubit.close();
    });
  });

  group('reset', () {
    test('clears resolved and results', () async {
      location.currentLocation = istanbul;
      final cubit = build();
      await cubit.useMyLocation();
      expect(cubit.state.resolved, isNotNull);

      cubit.reset();

      expect(cubit.state.resolved, isNull);
      expect(cubit.state.deviceStatus, DeviceLocationStatus.idle);
      await cubit.close();
    });
  });
}
