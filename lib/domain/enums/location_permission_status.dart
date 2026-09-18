/// Explicit, provider-agnostic outcome of a location-permission request.
///
/// The spec forbids "boolean soup": the presentation layer must be able to tell
/// these states apart (each drives a different, localized UX) without depending
/// on `geolocator`'s `LocationPermission` enum. The data layer maps the
/// provider's native enum onto this domain enum.
enum LocationPermissionStatus {
  /// Permission granted (whileInUse or always) — we may read the position.
  granted,

  /// Denied this time; the app may ask again later.
  denied,

  /// Denied permanently ("Don't ask again" / iOS denied) — the only recovery
  /// is the OS Settings screen. The app must NOT keep re-prompting.
  permanentlyDenied,

  /// OS-level location services (GPS) are switched off. This is distinct from a
  /// permission denial and is resolved from a different Settings screen.
  serviceDisabled,
}
