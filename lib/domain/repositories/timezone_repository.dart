/// Abstract contract for resolving an IANA timezone identifier for a
/// geographic coordinate.
///
/// Phase 4 Design Decision:
/// ─────────────────────────────────────────────────────────────────────────
/// Prayer calculations require knowing "what time is it NOW at the selected
/// location?" — this must use the location's own timezone, NOT the device
/// timezone.  Especially important for internationally-selected locations:
///   • Device in Istanbul, user selects New York → times must be EST/EDT.
///   • Device in Türkiye, user selects London → times must be GMT/BST.
///
/// Timezone IDs are IANA format (e.g. "Europe/Istanbul", "America/New_York").
/// They are resolved once and persisted so routine daily operation is fully
/// offline and does not call any network service.
///
/// Fallback policy (when resolution fails):
///   1. Use the persisted timezone ID if one exists from a prior resolution.
///   2. If none exists, return null — HomeCubit enters a safe "timezone
///      unavailable" state and prompts the user to retry rather than silently
///      using the wrong timezone.
///
/// DST is handled by the `timezone` package which ships a bundled database;
/// no network is required for DST transitions.
abstract class TimezoneRepository {
  /// Resolves the IANA timezone identifier for the given coordinates.
  ///
  /// Returns null when resolution is not possible (e.g. coordinates out of
  /// embedded table and network unavailable).  Does NOT throw.
  Future<String?> resolveTimezone(double latitude, double longitude);

  /// Returns the most recently persisted timezone ID, if any.
  Future<String?> getCachedTimezone();

  /// Persists a resolved timezone ID for offline use.
  Future<void> cacheTimezone(String ianaId);
}
