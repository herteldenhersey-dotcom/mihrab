// test/features/notifications/prayer_scheduler_test.dart
//
// Phase 5 — PrayerSchedulerIdMixin + ScheduleNotificationsUseCase unit tests.
// Uses fakes instead of mocks to avoid platform-channel dependencies.

import 'package:flutter_test/flutter_test.dart';

import 'package:mihrab/core/constants/prayer_constants.dart';
import 'package:mihrab/domain/enums/prayer_type.dart';
import 'package:mihrab/domain/models/calculation_settings_model.dart';
import 'package:mihrab/domain/models/notification_settings_model.dart';
import 'package:mihrab/domain/models/prayer_times_model.dart';
import 'package:mihrab/domain/usecases/get_prayer_times_usecase.dart';
import 'package:mihrab/domain/usecases/schedule_notifications_usecase.dart';
import 'package:mihrab/data/services/notification/prayer_notification_scheduler.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

/// A concrete class that uses PrayerSchedulerIdMixin so we can test the mixin.
class _MixinHost with PrayerSchedulerIdMixin {}

/// Records every scheduleWeek call for assertions.
class _FakeScheduler implements PrayerNotificationScheduler {
  final List<Map<String, dynamic>> calls = [];
  int cancelAllCount = 0;

  @override
  Future<void> scheduleWeek({
    required List<DailyPrayerTimes> days,
    required PrayerNotificationCopy copy,
    NotificationSettings? notificationSettings,
    Set<PrayerType>? enabledPrayers,
  }) async {
    calls.add({
      'days': days,
      'notificationSettings': notificationSettings,
      'enabledPrayers': enabledPrayers,
    });
  }

  @override
  Future<void> cancelAll() async => cancelAllCount++;

  @override
  Future<int> pendingCount() async => 0;
}

/// Returns a fixed DailyPrayerTimes for a given date.
class _FakeGetPrayerTimesUseCase implements GetPrayerTimesUseCase {
  @override
  Future<DailyPrayerTimes> call({
    required double latitude,
    required double longitude,
    required DateTime date,
    required CalculationSettings settings,
  }) async {
    return DailyPrayerTimes(
      date: date,
      fajr: date.copyWith(hour: 5, minute: 0, second: 0),
      sunrise: date.copyWith(hour: 6, minute: 30, second: 0),
      dhuhr: date.copyWith(hour: 12, minute: 0, second: 0),
      asr: date.copyWith(hour: 15, minute: 30, second: 0),
      maghrib: date.copyWith(hour: 18, minute: 0, second: 0),
      isha: date.copyWith(hour: 19, minute: 30, second: 0),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

PrayerNotificationCopy _fakeCopy() => PrayerNotificationCopy(
      title: (t) => t.key,
      body: (t, dt) => '${t.key} ${dt.hour}:${dt.minute}',
    );

CalculationSettings _fakeSettings() => const CalculationSettings();

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── PrayerSchedulerIdMixin ────────────────────────────────────────────────

  group('PrayerSchedulerIdMixin', () {
    late _MixinHost host;

    setUp(() => host = _MixinHost());

    test('S01: notificationId base offset matches PrayerConstants.notificationIdBase', () {
      final id = host.notificationId(0, PrayerType.fajr);
      expect(id, equals(PrayerConstants.notificationIdBase + PrayerType.fajr.index));
    });

    test('S02: notificationId for different days produces different ids', () {
      final id0 = host.notificationId(0, PrayerType.fajr);
      final id1 = host.notificationId(1, PrayerType.fajr);
      expect(id0, isNot(equals(id1)));
    });

    test('S03: notificationId for different prayers on the same day produces different ids', () {
      final idFajr = host.notificationId(0, PrayerType.fajr);
      final idDhuhr = host.notificationId(0, PrayerType.dhuhr);
      expect(idFajr, isNot(equals(idDhuhr)));
    });

    test('S04: notificationId is deterministic (same input → same output)', () {
      final first = host.notificationId(3, PrayerType.isha);
      final second = host.notificationId(3, PrayerType.isha);
      expect(first, equals(second));
    });

    test('S05: defaultEnabled returns exactly the 5 obligatory prayers', () {
      final enabled = host.defaultEnabled();
      expect(enabled, containsAll([
        PrayerType.fajr,
        PrayerType.dhuhr,
        PrayerType.asr,
        PrayerType.maghrib,
        PrayerType.isha,
      ]));
      expect(enabled, isNot(contains(PrayerType.sunrise)));
      expect(enabled.length, equals(5));
    });

    test('S06: resolveEnabledPrayers with null settings and null fallback returns defaults', () {
      final result = host.resolveEnabledPrayers(null, null);
      expect(result.length, equals(5));
      expect(result, isNot(contains(PrayerType.sunrise)));
    });

    test('S07: resolveEnabledPrayers with notificationSettings returns effectiveEnabledPrayers', () {
      final settings = NotificationSettings.defaults().copyWith(masterEnabled: false);
      final result = host.resolveEnabledPrayers(settings, null);
      expect(result, isEmpty,
          reason: 'masterEnabled=false → no effective prayers');
    });

    test('S08: resolveEnabledPrayers filters sunrise from legacy fallback', () {
      final fallbackWithSunrise = PrayerType.values.toSet();
      final result = host.resolveEnabledPrayers(null, fallbackWithSunrise);
      expect(result, isNot(contains(PrayerType.sunrise)));
    });

    test('S09: resolveEnabledPrayers prefers notificationSettings over fallback', () {
      // settings has master on but only Fajr enabled.
      final base = NotificationSettings.defaults();
      final onlyFajr = base.withPrayerConfig(
          PrayerType.dhuhr, const PrayerNotificationConfig(enabled: false));
      final settings = onlyFajr
          .withPrayerConfig(PrayerType.asr, const PrayerNotificationConfig(enabled: false))
          .withPrayerConfig(PrayerType.maghrib, const PrayerNotificationConfig(enabled: false))
          .withPrayerConfig(PrayerType.isha, const PrayerNotificationConfig(enabled: false));
      // fallback says all 5.
      final result = host.resolveEnabledPrayers(settings, PrayerType.values.toSet());
      // Should use settings (only Fajr), NOT fallback (all 5).
      expect(result.length, equals(1));
      expect(result, contains(PrayerType.fajr));
    });

    test('S10: adjustedFireTime with offset=0 returns unchanged prayer time', () {
      final time = DateTime(2025, 1, 1, 5, 30);
      const cfg = PrayerNotificationConfig(reminderOffsetMinutes: 0);
      final result = host.adjustedFireTime(time, cfg);
      expect(result, equals(time));
    });

    test('S11: adjustedFireTime with offset=10 returns 10 minutes before prayer time', () {
      final time = DateTime(2025, 1, 1, 12, 0);
      const cfg = PrayerNotificationConfig(reminderOffsetMinutes: 10);
      final result = host.adjustedFireTime(time, cfg);
      expect(result, equals(DateTime(2025, 1, 1, 11, 50)));
    });

    test('S12: useAdhanChannel returns false for sunrise regardless of config', () {
      const cfg = PrayerNotificationConfig(adhanEnabled: true);
      expect(host.useAdhanChannel(PrayerType.sunrise, cfg), isFalse,
          reason: 'Sunrise must never use the adhan channel');
    });

    test('S13: useAdhanChannel returns false when adhanEnabled=false', () {
      const cfg = PrayerNotificationConfig(adhanEnabled: false);
      expect(host.useAdhanChannel(PrayerType.fajr, cfg), isFalse);
    });

    test('S14: useAdhanChannel returns true for obligatory prayer when adhanEnabled=true', () {
      const cfg = PrayerNotificationConfig(adhanEnabled: true);
      expect(host.useAdhanChannel(PrayerType.fajr, cfg), isTrue);
    });
  });

  // ── ScheduleNotificationsUseCase ─────────────────────────────────────────

  group('ScheduleNotificationsUseCase', () {
    late _FakeScheduler fakeScheduler;
    late _FakeGetPrayerTimesUseCase fakePrayerTimes;
    late ScheduleNotificationsUseCase useCase;

    setUp(() {
      fakeScheduler = _FakeScheduler();
      fakePrayerTimes = _FakeGetPrayerTimesUseCase();
      useCase = ScheduleNotificationsUseCase(fakePrayerTimes, fakeScheduler);
    });

    test('S15: call invokes scheduleWeek exactly once', () async {
      await useCase.call(
        latitude: 41.0,
        longitude: 29.0,
        settings: _fakeSettings(),
        copy: _fakeCopy(),
      );
      expect(fakeScheduler.calls.length, equals(1));
    });

    test('S16: call passes scheduleWindowDays days to scheduler', () async {
      await useCase.call(
        latitude: 41.0,
        longitude: 29.0,
        settings: _fakeSettings(),
        copy: _fakeCopy(),
      );
      final days = fakeScheduler.calls.first['days'] as List<DailyPrayerTimes>;
      expect(days.length, equals(PrayerConstants.scheduleWindowDays));
    });

    test('S17: call forwards notificationSettings to scheduler', () async {
      final ns = NotificationSettings.defaults().copyWith(masterEnabled: false);
      await useCase.call(
        latitude: 41.0,
        longitude: 29.0,
        settings: _fakeSettings(),
        copy: _fakeCopy(),
        notificationSettings: ns,
      );
      final passed = fakeScheduler.calls.first['notificationSettings'];
      expect(passed, equals(ns));
    });

    test('S18: call with null notificationSettings passes null to scheduler', () async {
      await useCase.call(
        latitude: 41.0,
        longitude: 29.0,
        settings: _fakeSettings(),
        copy: _fakeCopy(),
      );
      final passed = fakeScheduler.calls.first['notificationSettings'];
      expect(passed, isNull);
    });

    test('S19: cancelAll delegates to scheduler', () async {
      await useCase.cancelAll();
      expect(fakeScheduler.cancelAllCount, equals(1));
    });

    test('S20: calling call twice produces two scheduleWeek calls', () async {
      await useCase.call(
        latitude: 41.0,
        longitude: 29.0,
        settings: _fakeSettings(),
        copy: _fakeCopy(),
      );
      await useCase.call(
        latitude: 41.0,
        longitude: 29.0,
        settings: _fakeSettings(),
        copy: _fakeCopy(),
      );
      expect(fakeScheduler.calls.length, equals(2));
    });

    test('S21: generated days are chronological (each day is 1 day after previous)', () async {
      final from = DateTime(2025, 6, 1);
      await useCase.call(
        latitude: 41.0,
        longitude: 29.0,
        settings: _fakeSettings(),
        copy: _fakeCopy(),
        from: from,
      );
      final days = fakeScheduler.calls.first['days'] as List<DailyPrayerTimes>;
      for (var i = 1; i < days.length; i++) {
        expect(days[i].date.isAfter(days[i - 1].date), isTrue,
            reason: 'Day ${i} should be after day ${i - 1}');
      }
    });
  });

  // ── Notification ID collision check ───────────────────────────────────────

  group('Notification ID uniqueness', () {
    test('S22: all IDs in the schedule window are unique', () {
      final host = _MixinHost();
      final allIds = <int>{};
      for (var day = 0; day < PrayerConstants.scheduleWindowDays; day++) {
        for (final prayer in PrayerType.values) {
          final id = host.notificationId(day, prayer);
          expect(allIds.add(id), isTrue,
              reason: 'Duplicate ID $id for day=$day prayer=$prayer');
        }
      }
    });

    test('S23: test notification ID (0) does not collide with schedule IDs', () {
      final host = _MixinHost();
      for (var day = 0; day < PrayerConstants.scheduleWindowDays; day++) {
        for (final prayer in PrayerType.values) {
          expect(host.notificationId(day, prayer),
              isNot(equals(PrayerConstants.testNotificationId)),
              reason: 'Schedule ID collides with test notification ID 0');
        }
      }
    });
  });
}
