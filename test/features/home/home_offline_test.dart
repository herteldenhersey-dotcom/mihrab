import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/core/services/clock.dart';
import 'package:mihrab/core/services/location_change_notifier.dart';
import 'package:mihrab/domain/enums/asr_calculation_method.dart';
import 'package:mihrab/domain/enums/prayer_calculation_method.dart';
import 'package:mihrab/domain/models/location_model.dart';
import 'package:mihrab/domain/models/prayer_times_model.dart';
import 'package:mihrab/domain/providers/prayer_time_provider.dart';
import 'package:mihrab/domain/repositories/timezone_repository.dart';
import 'package:mihrab/domain/usecases/get_prayer_times_usecase.dart';
import 'package:mihrab/features/home/presentation/cubit/home_cubit.dart';

import '../../helpers/fake_settings_repository.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeClock implements Clock {
  final DateTime _now;
  const _FakeClock(this._now);
  @override
  DateTime now() => _now;
}

class _PureOfflinePrayerProvider implements PrayerTimeProvider {
  int callCount = 0;

  @override
  Future<DailyPrayerTimes> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerCalculationMethod method,
    required AsrCalculationMethod asrMethod,
  }) async {
    callCount++;
    // Pure offline calculation — no network I/O in this fake.
    final d = DateTime(date.year, date.month, date.day);
    return DailyPrayerTimes(
      date: d,
      fajr: d.copyWith(hour: 5),
      sunrise: d.copyWith(hour: 7),
      dhuhr: d.copyWith(hour: 12, minute: 30),
      asr: d.copyWith(hour: 15, minute: 45),
      maghrib: d.copyWith(hour: 18, minute: 30),
      isha: d.copyWith(hour: 20),
    );
  }

  @override
  double getQiblaDirection({required double latitude, required double longitude}) => 0.0;
}

/// Timezone repository that has a pre-cached ID (simulates previously resolved
/// and persisted timezone) and tracks how many times [resolveTimezone] is called.
class _CachedTzRepo implements TimezoneRepository {
  final String _cached;
  int resolveCalls = 0;

  _CachedTzRepo(this._cached);

  @override
  Future<String?> resolveTimezone(double lat, double lng) async {
    resolveCalls++;
    return _cached;
  }

  @override
  Future<String?> getCachedTimezone() async => _cached;

  @override
  Future<void> cacheTimezone(String ianaId) async {}
}

const _savedLocation = AppLocation(
  latitude: 41.0,
  longitude: 28.98,
  city: 'İstanbul',
  country: 'TR',
  isManual: true,
  timezoneId: 'UTC', // Cached timezone travels with the location.
);

// ── Tests 47–49: Offline behaviour (spec §35) ─────────────────────────────────

void main() {
  final clock = _FakeClock(DateTime.utc(2024, 3, 15, 13, 0));

  // ── T47: Offline load succeeds with saved location + cached timezone ───────
  test(
      'T47: prayer times load successfully with saved location + cached timezone '
      'and no network',
      () async {
    final settings = FakeSettingsRepository();
    await settings.saveLocation(_savedLocation);
    final provider = _PureOfflinePrayerProvider();
    final tzRepo = _CachedTzRepo('UTC'); // pre-cached, no resolve needed

    final cubit = HomeCubit(
      settings: settings,
      getPrayerTimes: GetPrayerTimesUseCase(provider),
      timezoneRepo: tzRepo,
      locationNotifier: LocationChangeNotifier(),
      clock: clock,
    );
    await cubit.load();

    // Successfully loaded without any "network".
    expect(cubit.state, isA<HomeLoaded>());
    final loaded = cubit.state as HomeLoaded;
    expect(loaded.today.fajr.hour, 5);
    expect(loaded.timezoneId, 'UTC');
    await cubit.close();
  });

  // ── T48: Cached timezone prevents unnecessary resolver call ───────────────
  // When the location already carries a timezoneId, HomeCubit must not call
  // TimezoneRepository.resolveTimezone on a normal (non-forced) load.
  test(
      'T48: location with pre-cached timezoneId does not call resolveTimezone',
      () async {
    final settings = FakeSettingsRepository();
    // Location already has a timezoneId — HomeCubit should use it directly.
    await settings.saveLocation(_savedLocation); // timezoneId: 'UTC'
    final tzRepo = _CachedTzRepo('UTC');

    final cubit = HomeCubit(
      settings: settings,
      getPrayerTimes: GetPrayerTimesUseCase(_PureOfflinePrayerProvider()),
      timezoneRepo: tzRepo,
      locationNotifier: LocationChangeNotifier(),
      clock: clock,
    );
    await cubit.load();

    // When location.timezoneId is non-null, the first branch in _loadForLocation
    // skips resolveTimezone.  resolveCalls should be 0.
    expect(tzRepo.resolveCalls, 0,
        reason:
            'resolveTimezone must not be called when location already carries '
            'a cached timezoneId — wasteful and blocks offline use');
    await cubit.close();
  });

  // ── T49: Countdown ticks perform zero network calls ───────────────────────
  // The prayer provider (stand-in for adhan library) must not be called again
  // after the initial load during countdown ticks or onResume on the same day.
  test(
      'T49: countdown onResume on same day does not re-invoke prayer provider',
      () async {
    final settings = FakeSettingsRepository();
    await settings.saveLocation(_savedLocation);
    final provider = _PureOfflinePrayerProvider();
    final tzRepo = _CachedTzRepo('UTC');

    final mutableClock = _MutableFakeClock(DateTime.utc(2024, 3, 15, 13, 0));

    final cubit = HomeCubit(
      settings: settings,
      getPrayerTimes: GetPrayerTimesUseCase(provider),
      timezoneRepo: tzRepo,
      locationNotifier: LocationChangeNotifier(),
      clock: mutableClock,
    );
    await cubit.load();
    final callsAfterLoad = provider.callCount; // should be 2 (today + tomorrow)

    // Simulate several onResume calls within the same day.
    mutableClock.advance(const Duration(minutes: 5));
    await cubit.onResume();
    mutableClock.advance(const Duration(minutes: 5));
    await cubit.onResume();
    mutableClock.advance(const Duration(minutes: 5));
    await cubit.onResume();

    // Provider must NOT have been called again (no recalculation on same day).
    expect(provider.callCount, callsAfterLoad,
        reason:
            'Prayer times must not be recalculated during routine countdown '
            'ticks/resumes on the same day — only at date boundary or location change');
    await cubit.close();
  });
}

// ── Mutable FakeClock ─────────────────────────────────────────────────────────

class _MutableFakeClock implements Clock {
  DateTime _now;
  _MutableFakeClock(this._now);

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);
}
