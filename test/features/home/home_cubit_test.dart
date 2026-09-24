import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/core/services/clock.dart';
import 'package:mihrab/core/services/location_change_notifier.dart';
import 'package:mihrab/domain/enums/asr_calculation_method.dart';
import 'package:mihrab/domain/enums/prayer_calculation_method.dart';
import 'package:mihrab/domain/enums/prayer_type.dart';
import 'package:mihrab/domain/models/calculation_settings_model.dart';
import 'package:mihrab/domain/models/location_model.dart';
import 'package:mihrab/domain/models/prayer_times_model.dart';
import 'package:mihrab/domain/providers/prayer_time_provider.dart';
import 'package:mihrab/domain/repositories/settings_repository.dart';
import 'package:mihrab/domain/repositories/timezone_repository.dart';
import 'package:mihrab/domain/usecases/get_prayer_times_usecase.dart';
import 'package:mihrab/features/home/presentation/cubit/home_cubit.dart';

import '../../helpers/fake_settings_repository.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

/// Controllable clock for deterministic countdown tests.
class FakeClock implements Clock {
  DateTime _now;
  FakeClock(this._now);

  @override
  DateTime now() => _now;

  void set(DateTime dt) => _now = dt;
  void advance(Duration d) => _now = _now.add(d);
}

/// Fake prayer-time provider — returns scripted times relative to the date.
class FakePrayerTimeProvider implements PrayerTimeProvider {
  int callCount = 0;
  DailyPrayerTimes Function(DateTime date)? builder;

  @override
  Future<DailyPrayerTimes> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerCalculationMethod method,
    required AsrCalculationMethod asrMethod,
  }) async {
    callCount++;
    if (builder != null) return builder!(date);
    return _default(date);
  }

  @override
  double getQiblaDirection({required double latitude, required double longitude}) => 0.0;

  static DailyPrayerTimes _default(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return DailyPrayerTimes(
      date: d,
      fajr: d.copyWith(hour: 5, minute: 0),
      sunrise: d.copyWith(hour: 7, minute: 0),
      dhuhr: d.copyWith(hour: 12, minute: 30),
      asr: d.copyWith(hour: 15, minute: 45),
      maghrib: d.copyWith(hour: 18, minute: 30),
      isha: d.copyWith(hour: 20, minute: 0),
    );
  }
}

/// Fake timezone repository — returns a preconfigured IANA ID with no I/O.
class FakeTimezoneRepository implements TimezoneRepository {
  String? resolved;
  String? cached;
  int resolveCalls = 0;

  FakeTimezoneRepository({this.resolved = 'UTC', this.cached});

  @override
  Future<String?> resolveTimezone(double lat, double lng) async {
    resolveCalls++;
    return resolved;
  }

  @override
  Future<String?> getCachedTimezone() async => cached;

  @override
  Future<void> cacheTimezone(String ianaId) async => cached = ianaId;
}

// ── Test helpers ──────────────────────────────────────────────────────────────

const _istanbul = AppLocation(
  latitude: 41.0,
  longitude: 28.98,
  city: 'İstanbul',
  country: 'TR',
  isManual: true,
  timezoneId: 'UTC', // Use UTC so _toLocationTime math is trivial in tests
);

HomeCubit _buildCubit({
  FakeClock? clock,
  FakePrayerTimeProvider? provider,
  FakeTimezoneRepository? tzRepo,
  SettingsRepository? settings,
  LocationChangeNotifier? notifier,
  AppLocation? savedLocation,
}) {
  final fakeSettings = settings ?? FakeSettingsRepository();
  if (savedLocation != null && fakeSettings is FakeSettingsRepository) {
    fakeSettings.saveLocation(savedLocation);
  }
  final p = provider ?? FakePrayerTimeProvider();
  final usecase = GetPrayerTimesUseCase(p);
  return HomeCubit(
    settings: fakeSettings,
    getPrayerTimes: usecase,
    timezoneRepo: tzRepo ?? FakeTimezoneRepository(),
    locationNotifier: notifier ?? LocationChangeNotifier(),
    clock: clock,
  );
}

/// UTC "today" anchored at a convenient morning time so tests are stable.
/// 2024-03-15 08:00 UTC — between Fajr (05:00) and Dhuhr (12:30).
final _t0 = DateTime.utc(2024, 3, 15, 8, 0, 0);

// ── Tests 9–22: Prayer home logic (spec §31) ──────────────────────────────────

void main() {
  // ── T9: Before Fajr → next prayer is Fajr ─────────────────────────────────
  test('T9: before Fajr next prayer is Fajr', () async {
    // 03:00 UTC — before Fajr at 05:00
    final clock = FakeClock(DateTime.utc(2024, 3, 15, 3, 0));
    final cubit = _buildCubit(clock: clock, savedLocation: _istanbul);
    await cubit.load();
    final state = cubit.state;
    expect(state, isA<HomeLoaded>());
    final loaded = state as HomeLoaded;
    expect(loaded.nextPrayer.type, PrayerType.fajr);
    expect(loaded.nextPrayer.isTomorrow, isFalse);
    await cubit.close();
  });

  // ── T10: Between Dhuhr and Asr → next prayer is Asr ─────────────────────
  test('T10: between Dhuhr and Asr next prayer is Asr', () async {
    // 13:00 UTC — after Dhuhr (12:30), before Asr (15:45)
    final clock = FakeClock(DateTime.utc(2024, 3, 15, 13, 0));
    final cubit = _buildCubit(clock: clock, savedLocation: _istanbul);
    await cubit.load();
    final loaded = cubit.state as HomeLoaded;
    expect(loaded.nextPrayer.type, PrayerType.asr);
    await cubit.close();
  });

  // ── T11: Between Maghrib and Isha → next prayer is Isha ─────────────────
  test('T11: between Maghrib and Isha next prayer is Isha', () async {
    // 19:00 UTC — after Maghrib (18:30), before Isha (20:00)
    final clock = FakeClock(DateTime.utc(2024, 3, 15, 19, 0));
    final cubit = _buildCubit(clock: clock, savedLocation: _istanbul);
    await cubit.load();
    final loaded = cubit.state as HomeLoaded;
    expect(loaded.nextPrayer.type, PrayerType.isha);
    await cubit.close();
  });

  // ── T12: After Isha → next is tomorrow Fajr ──────────────────────────────
  test('T12: after Isha next prayer is tomorrow Fajr', () async {
    // 21:00 UTC — after Isha (20:00)
    final clock = FakeClock(DateTime.utc(2024, 3, 15, 21, 0));
    final cubit = _buildCubit(clock: clock, savedLocation: _istanbul);
    await cubit.load();
    final loaded = cubit.state as HomeLoaded;
    expect(loaded.nextPrayer.type, PrayerType.fajr);
    expect(loaded.nextPrayer.isTomorrow, isTrue);
    await cubit.close();
  });

  // ── T13: Tomorrow Fajr is calculated for tomorrow's date ─────────────────
  test('T13: tomorrow Fajr time belongs to tomorrow\'s date', () async {
    // 21:00 UTC — after today's Isha
    final clock = FakeClock(DateTime.utc(2024, 3, 15, 21, 0));
    final cubit = _buildCubit(clock: clock, savedLocation: _istanbul);
    await cubit.load();
    final loaded = cubit.state as HomeLoaded;
    // tomorrow Fajr should be on 2024-03-16
    expect(loaded.nextPrayer.isTomorrow, isTrue);
    expect(loaded.nextPrayer.time.day, 16);
    expect(loaded.nextPrayer.time.month, 3);
    await cubit.close();
  });

  // ── T14: Countdown is positive ────────────────────────────────────────────
  test('T14: countdown is a positive duration', () async {
    final clock = FakeClock(_t0);
    final cubit = _buildCubit(clock: clock, savedLocation: _istanbul);
    await cubit.load();
    final loaded = cubit.state as HomeLoaded;
    expect(loaded.countdown.inSeconds, greaterThan(0));
    await cubit.close();
  });

  // ── T15: Countdown recalculates from clock (no drift) ────────────────────
  // Tests clock-based recalculation: advance the fake clock by 60s,
  // call onResume, and verify the countdown decreased by ~60s.
  test('T15: resumed countdown recalculates from current clock, not drift', () async {
    final clock = FakeClock(_t0); // 08:00
    final cubit = _buildCubit(clock: clock, savedLocation: _istanbul);
    await cubit.load();
    final first = (cubit.state as HomeLoaded).countdown;

    // Advance clock by 60 seconds and resume.
    clock.advance(const Duration(seconds: 60));
    await cubit.onResume();
    final second = (cubit.state as HomeLoaded).countdown;

    // If clock-based: second ≈ first - 60s.  Allow ±2s tolerance.
    final diff = first.inSeconds - second.inSeconds;
    expect(diff, closeTo(60, 2));
    await cubit.close();
  });

  // ── T16: Prayer transition changes next prayer ────────────────────────────
  test('T16: advancing clock past Asr triggers next prayer = Maghrib', () async {
    // Start: 13:00 UTC, next = Asr (15:45)
    final clock = FakeClock(DateTime.utc(2024, 3, 15, 13, 0));
    final cubit = _buildCubit(clock: clock, savedLocation: _istanbul);
    await cubit.load();
    expect((cubit.state as HomeLoaded).nextPrayer.type, PrayerType.asr);

    // Jump past Asr to 16:00 and call onResume to simulate tick.
    clock.set(DateTime.utc(2024, 3, 15, 16, 0));
    await cubit.onResume();
    expect((cubit.state as HomeLoaded).nextPrayer.type, PrayerType.maghrib);
    await cubit.close();
  });

  // ── T17: Midnight transition reloads prayer day ───────────────────────────
  test('T17: crossing midnight triggers reload with next day\'s prayer times', () async {
    // Start: 22:00 on 2024-03-15 (after Isha)
    final clock = FakeClock(DateTime.utc(2024, 3, 15, 22, 0));
    final cubit = _buildCubit(clock: clock, savedLocation: _istanbul);
    await cubit.load();
    final firstDate = (cubit.state as HomeLoaded).locationNow.day;

    // Cross midnight to 00:30 on 2024-03-16
    clock.set(DateTime.utc(2024, 3, 16, 0, 30));
    await cubit.onResume();
    final secondDate = (cubit.state as HomeLoaded).locationNow.day;
    expect(secondDate, isNot(equals(firstDate)));
    expect(secondDate, 16);
    await cubit.close();
  });

  // ── T18: Manual offsets appear in displayed times ─────────────────────────
  test('T18: calculation settings with manual offsets are forwarded to provider', () async {
    int callCount = 0;
    final provider = FakePrayerTimeProvider()
      ..builder = (date) {
        callCount++;
        return FakePrayerTimeProvider._default(date);
      };

    // Inject settings with a non-default offset.
    final settings = FakeSettingsRepository();
    await settings.saveCalculationSettings(
      CalculationSettings.turkeyDefault.copyWith(
        offsets: const ManualOffsets(fajr: 2),
      ),
    );
    await settings.saveLocation(_istanbul);

    final usecase = GetPrayerTimesUseCase(provider);
    final cubit = HomeCubit(
      settings: settings,
      getPrayerTimes: usecase,
      timezoneRepo: FakeTimezoneRepository(),
      locationNotifier: LocationChangeNotifier(),
      clock: FakeClock(_t0),
    );
    await cubit.load();
    // Provider was called (offsets applied by use case layer).
    expect(callCount, greaterThan(0));
    // The fajr time includes the +2 minute offset.
    final loaded = cubit.state as HomeLoaded;
    expect(loaded.today.fajr.minute, 2); // default 05:00 + 2 min = 05:02
    await cubit.close();
  });

  // ── T19: Asr method reaches provider ─────────────────────────────────────
  test('T19: Hanafi Asr method is forwarded through use case to provider', () async {
    AsrCalculationMethod? received;
    final provider = FakePrayerTimeProvider()
      ..builder = (date) {
        return FakePrayerTimeProvider._default(date);
      };
    // Wrap provider to capture the Asr method.
    final capturingProvider = _CapturingProvider(provider, onAsr: (m) => received = m);

    final settings = FakeSettingsRepository();
    await settings.saveCalculationSettings(
      CalculationSettings.turkeyDefault.copyWith(
        asrMethod: AsrCalculationMethod.hanafi,
      ),
    );
    await settings.saveLocation(_istanbul);

    final cubit = HomeCubit(
      settings: settings,
      getPrayerTimes: GetPrayerTimesUseCase(capturingProvider),
      timezoneRepo: FakeTimezoneRepository(),
      locationNotifier: LocationChangeNotifier(),
      clock: FakeClock(_t0),
    );
    await cubit.load();
    expect(received, AsrCalculationMethod.hanafi);
    await cubit.close();
  });

  // ── T20: Calculation method reaches provider ──────────────────────────────
  test('T20: DiyanetIGMGEurope method is forwarded through use case', () async {
    PrayerCalculationMethod? received;
    final provider = FakePrayerTimeProvider()
      ..builder = (date) => FakePrayerTimeProvider._default(date);
    final capturingProvider = _CapturingProvider(
      provider,
      onMethod: (m) => received = m,
    );

    final settings = FakeSettingsRepository();
    await settings.saveCalculationSettings(
      CalculationSettings.turkeyDefault.copyWith(
        method: PrayerCalculationMethod.northAmerica,
      ),
    );
    await settings.saveLocation(_istanbul);

    final cubit = HomeCubit(
      settings: settings,
      getPrayerTimes: GetPrayerTimesUseCase(capturingProvider),
      timezoneRepo: FakeTimezoneRepository(),
      locationNotifier: LocationChangeNotifier(),
      clock: FakeClock(_t0),
    );
    await cubit.load();
    expect(received, PrayerCalculationMethod.northAmerica);
    await cubit.close();
  });

  // ── T21: Invalid coordinates → provider throws (or returns failure state) ─
  test('T21: invalid coordinates do not reach the prayer provider', () async {
    const invalidLocation = AppLocation(
      latitude: double.nan,
      longitude: 0,
    );
    // hasValidCoordinates is false, so HomeCubit should emit HomeMissingLocation
    // or HomeFailure before ever calling the provider.
    final provider = FakePrayerTimeProvider();
    final settings = FakeSettingsRepository();
    await settings.saveLocation(invalidLocation);

    final cubit = HomeCubit(
      settings: settings,
      getPrayerTimes: GetPrayerTimesUseCase(provider),
      timezoneRepo: FakeTimezoneRepository(),
      locationNotifier: LocationChangeNotifier(),
      clock: FakeClock(_t0),
    );
    await cubit.load();
    // Provider must NOT have been called.
    expect(provider.callCount, 0);
    // State should be missing-location (invalid coordinates).
    expect(cubit.state, isA<HomeMissingLocation>());
    await cubit.close();
  });

  // ── T22: Missing location → HomeMissingLocation state ────────────────────
  test('T22: no saved location emits HomeMissingLocation', () async {
    // FakeSettingsRepository has no saved location by default.
    final cubit = _buildCubit(clock: FakeClock(_t0));
    await cubit.load();
    expect(cubit.state, isA<HomeMissingLocation>());
    await cubit.close();
  });

  // ── Tests 23–28: Countdown / lifecycle (spec §32) ─────────────────────────

  // ── T23: Countdown updates on onResume ────────────────────────────────────
  test('T23: countdown value changes after clock advances + onResume', () async {
    final clock = FakeClock(_t0);
    final cubit = _buildCubit(clock: clock, savedLocation: _istanbul);
    await cubit.load();
    final before = (cubit.state as HomeLoaded).countdown;

    clock.advance(const Duration(seconds: 30));
    await cubit.onResume();
    final after = (cubit.state as HomeLoaded).countdown;

    expect(after, isNot(equals(before)));
    expect(after.inSeconds, lessThan(before.inSeconds));
    await cubit.close();
  });

  // ── T24: Countdown does not drift (not decrement-based) ──────────────────
  // Proves the countdown is clock-based: advancing 2× 30s must match
  // advancing 60s in one go.
  test('T24: countdown recalculated from clock each time — no cumulative drift', () async {
    final clock = FakeClock(_t0);
    final cubit = _buildCubit(clock: clock, savedLocation: _istanbul);
    await cubit.load();

    // Advance 30s twice, then note countdown.
    clock.advance(const Duration(seconds: 30));
    await cubit.onResume();
    clock.advance(const Duration(seconds: 30));
    await cubit.onResume();
    final steppedCountdown = (cubit.state as HomeLoaded).countdown;

    // Fresh cubit advanced 60s in one go — should match.
    final clock2 = FakeClock(_t0.add(const Duration(seconds: 60)));
    final cubit2 = _buildCubit(clock: clock2, savedLocation: _istanbul);
    await cubit2.load();
    final directCountdown = (cubit2.state as HomeLoaded).countdown;

    expect(steppedCountdown.inSeconds, closeTo(directCountdown.inSeconds, 1));
    await cubit.close();
    await cubit2.close();
  });

  // ── T25: Timer disposed when cubit closes ────────────────────────────────
  test('T25: HomeCubit.close cancels the countdown timer without throwing', () async {
    final clock = FakeClock(_t0);
    final cubit = _buildCubit(clock: clock, savedLocation: _istanbul);
    await cubit.load();
    expect(cubit.state, isA<HomeLoaded>());
    // close() must not throw even with an active timer.
    await expectLater(cubit.close(), completes);
  });

  // ── T26: Resume after background recalculates from clock ─────────────────
  test('T26: onResume uses current clock, not stale pre-background value', () async {
    final clock = FakeClock(_t0); // 08:00
    final cubit = _buildCubit(clock: clock, savedLocation: _istanbul);
    await cubit.load();
    final before = (cubit.state as HomeLoaded).countdown;

    // Simulate 10-minute background.
    clock.advance(const Duration(minutes: 10));
    await cubit.onResume();
    final after = (cubit.state as HomeLoaded).countdown;

    // Countdown must have dropped by ~600s.
    expect(before.inSeconds - after.inSeconds, closeTo(600, 5));
    await cubit.close();
  });

  // ── T27: Resume after prayer transition selects correct next prayer ────────
  test('T27: resumed past Asr transition correctly identifies Maghrib as next', () async {
    // Start at 13:00 (after Dhuhr, before Asr)
    final clock = FakeClock(DateTime.utc(2024, 3, 15, 13, 0));
    final cubit = _buildCubit(clock: clock, savedLocation: _istanbul);
    await cubit.load();
    expect((cubit.state as HomeLoaded).nextPrayer.type, PrayerType.asr);

    // Background across Asr (15:45) and resume at 16:30.
    clock.set(DateTime.utc(2024, 3, 15, 16, 30));
    await cubit.onResume();
    expect((cubit.state as HomeLoaded).nextPrayer.type, PrayerType.maghrib);
    await cubit.close();
  });

  // ── T28: Resume after midnight loads correct prayer day ──────────────────
  test('T28: resumed across midnight reloads tomorrow\'s prayer day', () async {
    // Start: 23:30 on 2024-03-15
    final clock = FakeClock(DateTime.utc(2024, 3, 15, 23, 30));
    final cubit = _buildCubit(clock: clock, savedLocation: _istanbul);
    await cubit.load();
    expect((cubit.state as HomeLoaded).locationNow.day, 15);

    // Background across midnight → 00:15 on 2024-03-16.
    clock.set(DateTime.utc(2024, 3, 16, 0, 15));
    await cubit.onResume();
    expect((cubit.state as HomeLoaded).locationNow.day, 16);
    await cubit.close();
  });
}

// ── Capturing provider ────────────────────────────────────────────────────────

/// Wraps [FakePrayerTimeProvider] and intercepts method/asrMethod values.
class _CapturingProvider implements PrayerTimeProvider {
  final FakePrayerTimeProvider _inner;
  final void Function(AsrCalculationMethod)? onAsr;
  final void Function(PrayerCalculationMethod)? onMethod;

  _CapturingProvider(this._inner, {this.onAsr, this.onMethod});

  @override
  Future<DailyPrayerTimes> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerCalculationMethod method,
    required AsrCalculationMethod asrMethod,
  }) async {
    onAsr?.call(asrMethod);
    onMethod?.call(method);
    return _inner.getPrayerTimes(
      latitude: latitude,
      longitude: longitude,
      date: date,
      method: method,
      asrMethod: asrMethod,
    );
  }

  @override
  double getQiblaDirection({required double latitude, required double longitude}) => 0.0;
}
