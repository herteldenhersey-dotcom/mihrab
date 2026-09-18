part of 'location_onboarding_cubit.dart';

/// Explicit device-GPS flow states. No boolean soup: every value maps to a
/// distinct, localized screen state.
enum DeviceLocationStatus {
  /// Nothing requested yet.
  idle,

  /// Acquiring permission and/or a position fix (show a spinner, disable button).
  loading,

  /// A valid location was obtained.
  success,

  /// OS location services (GPS) are off — offer "open location settings".
  serviceDisabled,

  /// Permission denied this time — the user can try again.
  permissionDenied,

  /// Permission permanently denied — offer "open settings", never re-prompt.
  permissionPermanentlyDenied,

  /// The one-time fix timed out — offer "try again".
  timeout,

  /// Any other failure (invalid data, unexpected error) — offer "try again".
  failure,
}

/// Explicit manual-search flow states.
enum ManualSearchStatus {
  /// No query / results yet.
  idle,

  /// A search is in flight.
  loading,

  /// Results are available in [LocationOnboardingState.results].
  results,

  /// The query returned no matches.
  empty,

  /// The search failed (network/provider). Offer "try again".
  error,
}

/// State for the location onboarding step. Holds both the device-GPS sub-flow
/// and the manual-search sub-flow, plus the final [resolved] location.
class LocationOnboardingState extends Equatable {
  final DeviceLocationStatus deviceStatus;
  final ManualSearchStatus searchStatus;
  final List<LocationSearchResult> results;

  /// The confirmed location (from GPS or a manual pick). Non-null once the user
  /// has a usable location; drives the "Confirm/Continue" gate.
  final AppLocation? resolved;

  const LocationOnboardingState({
    this.deviceStatus = DeviceLocationStatus.idle,
    this.searchStatus = ManualSearchStatus.idle,
    this.results = const [],
    this.resolved,
  });

  bool get isBusy =>
      deviceStatus == DeviceLocationStatus.loading ||
      searchStatus == ManualSearchStatus.loading;

  bool get hasLocation => resolved != null;

  LocationOnboardingState copyWith({
    DeviceLocationStatus? deviceStatus,
    ManualSearchStatus? searchStatus,
    List<LocationSearchResult>? results,
    AppLocation? resolved,
    bool clearResolved = false,
  }) {
    return LocationOnboardingState(
      deviceStatus: deviceStatus ?? this.deviceStatus,
      searchStatus: searchStatus ?? this.searchStatus,
      results: results ?? this.results,
      resolved: clearResolved ? null : (resolved ?? this.resolved),
    );
  }

  @override
  List<Object?> get props => [deviceStatus, searchStatus, results, resolved];
}
