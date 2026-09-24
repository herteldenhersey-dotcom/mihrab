// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/data/repositories/coordinate_timezone_repository.dart';
import 'package:mihrab/domain/repositories/timezone_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests 1–8 — Timezone resolution strategy (spec §30).
///
/// All tests use [CoordinateTimezoneRepository] with a fake SharedPreferences
/// (no network, no GPS, no device timezone).  The bundled country→IANA table
/// is deterministic, making these tests fully hermetic.
///
/// Resolution strategy:
/// • [CoordinateTimezoneRepository.resolveFromCountryCode] — primary, accurate.
///   Uses the embedded ISO-3166-1-alpha-2 → IANA table.  Tests T1–T4 and T7
///   exercise this path because the production HomeCubit always calls it first
///   when AppLocation.country is available (which it is after geocoding).
/// • [TimezoneRepository.resolveTimezone(lat, lng)] — longitude-based fallback
///   only, documented as approximate (±1 offset band for border locations).
///   Not tested for exact country accuracy — it is intentionally approximate.
void main() {
  late SharedPreferences prefs;
  late CoordinateTimezoneRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = CoordinateTimezoneRepository(prefs);
  });

  // ── Test 1 — Türkiye → Europe/Istanbul ───────────────────────────────────
  // HomeCubit calls resolveFromCountryCode('TR', lng) after geocoding.
  test('T1: TR country code resolves to Europe/Istanbul', () {
    final tz = repo.resolveFromCountryCode('TR', 28.98);
    expect(tz, 'Europe/Istanbul');
  });

  // ── Test 2 — New York → America/New_York ─────────────────────────────────
  // USA is multi-zone; longitude -74 (Eastern) → America/New_York.
  test('T2: US country code at New York longitude resolves to America/New_York', () {
    final tz = repo.resolveFromCountryCode('US', -74.01);
    expect(tz, 'America/New_York');
  });

  // ── Test 3 — London DST scenario ─────────────────────────────────────────
  // CoordinateTimezoneRepository resolves London to Europe/London regardless
  // of current season — DST offset is handled by the timezone package at
  // runtime, not by this repository.
  test('T3: GB country code resolves to Europe/London (DST-neutral ID)', () {
    final tz = repo.resolveFromCountryCode('GB', -0.13);
    expect(tz, 'Europe/London');
  });

  // ── Test 4 — Device timezone differs from selected location ──────────────
  // The repository resolves the *location's* timezone regardless of the
  // device timezone.  A Türkiye device selecting London must get Europe/London.
  test('T4: GB resolves to Europe/London (not Europe/Istanbul as device TZ)', () {
    final london = repo.resolveFromCountryCode('GB', -0.13);
    expect(london, isNot(equals('Europe/Istanbul')));
    expect(london, 'Europe/London');
  });

  // ── Test 5 — Caching round-trip ──────────────────────────────────────────
  test('T5: cacheTimezone persists and getCachedTimezone retrieves it', () async {
    expect(await repo.getCachedTimezone(), isNull); // nothing cached yet
    await repo.cacheTimezone('America/New_York');
    expect(await repo.getCachedTimezone(), 'America/New_York');
  });

  // ── Test 6 — Persisted timezone survives across new repo instance ─────────
  // Simulates app restart: same prefs object, fresh repo instance.
  test('T6: cached timezone persists across repo re-instantiation', () async {
    await repo.cacheTimezone('Europe/Berlin');
    final repo2 = CoordinateTimezoneRepository(prefs);
    expect(await repo2.getCachedTimezone(), 'Europe/Berlin');
  });

  // ── Test 7 — Saudi Arabia (single-zone country) ──────────────────────────
  test('T7: SA country code resolves to Asia/Riyadh', () {
    final tz = repo.resolveFromCountryCode('SA', 46.72);
    expect(tz, 'Asia/Riyadh');
  });

  // ── Test 8 — No cache initially returns null ─────────────────────────────
  test('T8: getCachedTimezone returns null when nothing is cached', () async {
    final cached = await repo.getCachedTimezone();
    expect(cached, isNull);
  });
}
