import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../domain/enums/location_permission_status.dart';
import '../../../../domain/models/location_model.dart';
import '../../../../domain/models/location_search_result.dart';
import '../../../../domain/repositories/location_repository.dart';
import '../../../../domain/repositories/location_search_repository.dart';
import '../../../../domain/repositories/settings_repository.dart';

part 'location_onboarding_state.dart';

/// Orchestrates the location onboarding step.
///
/// Owns BOTH sub-flows — "use my location" (device GPS) and "select manually"
/// (search) — and persists a resolved location via [SettingsRepository].
///
/// Architecture note (spec): the UI NEVER calls `Geolocator`/`geocoding`
/// directly. It calls this cubit → repositories → providers. All platform
/// exceptions are caught here and mapped to explicit [DeviceLocationStatus] /
/// [ManualSearchStatus] values so the UI only renders localized strings, never
/// raw errors.
class LocationOnboardingCubit extends Cubit<LocationOnboardingState> {
  final LocationRepository _locationRepo;
  final LocationSearchRepository _searchRepo;
  final SettingsRepository _settings;

  LocationOnboardingCubit(
    this._locationRepo,
    this._searchRepo,
    this._settings,
  ) : super(const LocationOnboardingState());

  /// Minimum characters before a manual search fires.
  static const int minQueryLength = 2;

  /// "Use my location": ask permission (showing an explicit state for every
  /// outcome), then take a one-time fix and persist it.
  ///
  /// Guarded against double-triggering: a second tap while loading is ignored.
  Future<void> useMyLocation() async {
    if (state.deviceStatus == DeviceLocationStatus.loading) return;

    emit(state.copyWith(deviceStatus: DeviceLocationStatus.loading));

    final permission = await _locationRepo.requestPermission();
    switch (permission) {
      case LocationPermissionStatus.serviceDisabled:
        emit(state.copyWith(
            deviceStatus: DeviceLocationStatus.serviceDisabled));
        return;
      case LocationPermissionStatus.permanentlyDenied:
        emit(state.copyWith(
            deviceStatus: DeviceLocationStatus.permissionPermanentlyDenied));
        return;
      case LocationPermissionStatus.denied:
        emit(state.copyWith(
            deviceStatus: DeviceLocationStatus.permissionDenied));
        return;
      case LocationPermissionStatus.granted:
        break;
    }

    try {
      final location = await _locationRepo.getCurrentLocation();
      // Reject malformed coordinates before persisting/using them.
      if (!location.hasValidCoordinates) {
        emit(state.copyWith(deviceStatus: DeviceLocationStatus.failure));
        return;
      }
      await _settings.saveLocation(location);
      emit(state.copyWith(
        deviceStatus: DeviceLocationStatus.success,
        resolved: location,
      ));
    } on TimeoutAppException {
      emit(state.copyWith(deviceStatus: DeviceLocationStatus.timeout));
    } on PermissionException {
      emit(state.copyWith(deviceStatus: DeviceLocationStatus.permissionDenied));
    } on LocationException {
      emit(state.copyWith(deviceStatus: DeviceLocationStatus.failure));
    } catch (_) {
      emit(state.copyWith(deviceStatus: DeviceLocationStatus.failure));
    }
  }

  /// Runs a manual free-text search. No-ops for very short queries.
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < minQueryLength) {
      emit(state.copyWith(
          searchStatus: ManualSearchStatus.idle, results: const []));
      return;
    }

    emit(state.copyWith(searchStatus: ManualSearchStatus.loading));
    try {
      final results = await _searchRepo.search(trimmed);
      // Only keep rows with usable coordinates.
      final valid = results.where((r) => r.hasValidCoordinates).toList();
      if (valid.isEmpty) {
        emit(state.copyWith(
            searchStatus: ManualSearchStatus.empty, results: const []));
      } else {
        emit(state.copyWith(
            searchStatus: ManualSearchStatus.results, results: valid));
      }
    } on AppException {
      emit(state.copyWith(searchStatus: ManualSearchStatus.error));
    } catch (_) {
      emit(state.copyWith(searchStatus: ManualSearchStatus.error));
    }
  }

  /// Confirms a manual search result: validates, persists and resolves it.
  Future<void> selectResult(LocationSearchResult result) async {
    final location = result.toAppLocation();
    if (!location.hasValidCoordinates) {
      emit(state.copyWith(searchStatus: ManualSearchStatus.error));
      return;
    }
    await _settings.saveLocation(location);
    emit(state.copyWith(
      searchStatus: ManualSearchStatus.idle,
      results: const [],
      resolved: location,
    ));
  }

  /// Clears the current resolution and results (used by "Change location").
  void reset() {
    emit(const LocationOnboardingState());
  }

  /// Opens the OS app-settings screen (permanently-denied recovery).
  Future<bool> openAppSettings() => _locationRepo.openAppSettings();

  /// Opens the OS location-services settings screen (disabled-GPS recovery).
  Future<bool> openLocationSettings() =>
      _locationRepo.openLocationSettings();
}
