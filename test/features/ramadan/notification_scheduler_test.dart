// test/features/ramadan/notification_scheduler_test.dart
//
// Phase 6 — RamadanNotificationScheduler unit tests (R19–R38).
// CRITICAL coverage: notification-ID ownership (2000–2099), zero collision with
// prayer (1000–1065) and test (0) ids, SCOPED cancellation (never cancelAll),
// Sahur=Imsak-offset / Iftar=Maghrib-offset, past-event filtering, midnight
// crossing, and the iOS 64 pending-notification capacity audit.

import 'package:flutter_test/flutter_test.dart';

import 'package:mihrab/core/constants/prayer_constants.dart';
import 'package:mihrab/data/services/notification/notification_service.dart';
import 'package:mihrab/data/services/ramadan/ramadan_notification_scheduler.dart';
import 'package:mihrab/domain/entities/ramadan_notification_schedule.dart';
import 'package:mihrab/domain/entities/ramadan_settings.dart';
import 'package:mihrab/domain/models/prayer_times_model.dart';

// ── Fake NotificationService ───────────────────────────────────────────────
class _FakeNotificationService implements NotificationService {
  final List<Map<String, dynamic>> scheduled = [];
  final List<List<int>> cancelIdsCalls = [];
  int cancelAllCount = 0;

  @override
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? locationTzId,
    String? payload,
    bool exact = true,
    bool useAdhanChannel = false,
  }) async {
    scheduled.add({
      'id': id,
      'title': title,
      'body': body,
      'when': when,
      'locationTzId': locationTzId,
      'payload': payload,
      'exact': exact,
      'useAdhanChannel': useAdhanChannel,
    });
  }

  @override
  Future<void> cancelIds(Iterable<int> ids) async =>
      cancelIdsCalls.add(ids.toList());

  @override
  Future<void> cancelAll() async => cancelAllCount++;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<int> pendingCount() async => scheduled.length;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> sendTestNotification({
    required String title,
    required String body,
    int secondsAhead = 5,
  }) async {}

  @override
  Future<NotificationDiagnostics> getDiagnostics() async =>
      NotificationDiagnostics(pendingCount: scheduled.length);
}

DailyPrayerTimes _day(DateTime d,
    {int fajrH = 5, int maghribH = 18, int maghribM = 30}) {
  return DailyPrayerTimes(
    date: d,
    fajr: DateTime(d.year, d.month, d.day, fajrH, 0),
    sunrise: DateTime(d.year, d.month, d.day, 6, 30),
    dhuhr: DateTime(d.year, d.month, d.day, 12, 0),
    asr: DateTime(d.year, d.month, d.day, 15, 30),
    maghrib: DateTime(d.year, d.month, d.day, maghribH, maghribM),
    isha: DateTime(d.year, d.month, d.day, 19, 30),
  );
}

List<DailyPrayerTimes> _week(DateTime start) =>
    [for (var i = 0; i < 7; i++) _day(start.add(Duration(days: i)))];

RamadanNotificationCopy _copy() => RamadanNotificationCopy(
      sahurTitle: (_) => 'Sahur',
      sahurBody: (_) => 'Sahur body',
      iftarTitle: (_) => 'Iftar',
      iftarBody: (_) => 'Iftar body',
    );

void main() {
  // ── ID formula & ownership ───────────────────────────────────────────────
  group('Notification ID ownership (2000–2099)', () {
    test('R19: id formula = base + dayIndex*2 + typeOffset', () {
      expect(
          RamadanNotificationScheduler.notificationId(
              0, RamadanReminderType.sahur),
          2000);
      expect(
          RamadanNotificationScheduler.notificationId(
              0, RamadanReminderType.iftar),
          2001);
      expect(
          RamadanNotificationScheduler.notificationId(
              3, RamadanReminderType.sahur),
          2006);
      expect(
          RamadanNotificationScheduler.notificationId(
              3, RamadanReminderType.iftar),
          2007);
    });

    test('R20: all scheduled ids fall within 2000..2099', () {
      for (final id in RamadanNotificationScheduler.ramadanScheduleIds()) {
        expect(id, inInclusiveRange(2000, 2099));
      }
    });

    test('R21: ramadanScheduleIds has horizonDays*2 entries, all unique', () {
      final ids = RamadanNotificationScheduler.ramadanScheduleIds();
      expect(ids.length, RamadanNotificationScheduler.horizonDays * 2);
      expect(ids.toSet().length, ids.length);
    });

    test('R22: zero collision with prayer ids (1000–1065)', () {
      final ramadanIds =
          RamadanNotificationScheduler.ramadanScheduleIds().toSet();
      for (var id = PrayerConstants.notificationIdBase;
          id <= PrayerConstants.notificationIdBase + 65;
          id++) {
        expect(ramadanIds.contains(id), isFalse);
      }
    });

    test('R23: zero collision with test notification id (0)', () {
      expect(
          RamadanNotificationScheduler.ramadanScheduleIds()
              .contains(PrayerConstants.testNotificationId),
          isFalse);
    });

    test('R24: sahur ids are even-offset, iftar ids odd-offset', () {
      for (var d = 0; d < RamadanNotificationScheduler.horizonDays; d++) {
        final sahur = RamadanNotificationScheduler.notificationId(
            d, RamadanReminderType.sahur);
        final iftar = RamadanNotificationScheduler.notificationId(
            d, RamadanReminderType.iftar);
        expect((sahur - 2000) % 2, 0);
        expect((iftar - 2000) % 2, 1);
      }
    });
  });

  // ── buildSchedules ───────────────────────────────────────────────────────
  group('buildSchedules', () {
    final scheduler = RamadanNotificationScheduler(_FakeNotificationService());

    test('R25: Sahur fire = Imsak(Fajr) minus sahurOffsetMinutes', () {
      final days = _week(DateTime(2025, 3, 10));
      final s = scheduler.buildSchedules(
        days: days,
        settings: const RamadanSettings(
            sahurEnabled: true, iftarEnabled: false, sahurOffsetMinutes: 30),
      );
      final first = s.first;
      expect(first.type, RamadanReminderType.sahur);
      expect(first.eventTime, DateTime(2025, 3, 10, 5, 0));
      expect(first.fireTime, DateTime(2025, 3, 10, 4, 30));
    });

    test('R26: Iftar fire = Maghrib minus iftarOffsetMinutes', () {
      final days = _week(DateTime(2025, 3, 10));
      final s = scheduler.buildSchedules(
        days: days,
        settings: const RamadanSettings(
            sahurEnabled: false, iftarEnabled: true, iftarOffsetMinutes: 15),
      );
      final first = s.first;
      expect(first.type, RamadanReminderType.iftar);
      expect(first.eventTime, DateTime(2025, 3, 10, 18, 30));
      expect(first.fireTime, DateTime(2025, 3, 10, 18, 15));
    });

    test('R27: iftarOffset 0 fires exactly at Maghrib', () {
      final days = _week(DateTime(2025, 3, 10));
      final s = scheduler.buildSchedules(
        days: days,
        settings: const RamadanSettings(
            sahurEnabled: false, iftarEnabled: true, iftarOffsetMinutes: 0),
      );
      expect(s.first.fireTime, DateTime(2025, 3, 10, 18, 30));
    });

    test('R28: both reminders enabled → 2 schedules per day', () {
      final days = _week(DateTime(2025, 3, 10));
      final s = scheduler.buildSchedules(
        days: days,
        settings: const RamadanSettings(
            sahurEnabled: true, iftarEnabled: true),
      );
      expect(s.length, 14); // 7 days × 2
    });

    test('R29: both reminders disabled → empty', () {
      final days = _week(DateTime(2025, 3, 10));
      final s = scheduler.buildSchedules(
        days: days,
        settings: const RamadanSettings(
            sahurEnabled: false, iftarEnabled: false),
      );
      expect(s, isEmpty);
    });

    test('R30: past events are filtered when now is supplied', () {
      final days = _week(DateTime(2025, 3, 10));
      // now = midday day 0 → day-0 sahur (04:30) is in the past, day-0 iftar
      // (18:15) is still ahead.
      final s = scheduler.buildSchedules(
        days: days,
        settings: const RamadanSettings(
            sahurEnabled: true, iftarEnabled: true),
        now: DateTime(2025, 3, 10, 12, 0),
      );
      // Day 0 sahur filtered out → 13 remain (7 iftar + 6 sahur).
      expect(s.length, 13);
      expect(
          s.any((e) =>
              e.type == RamadanReminderType.sahur && e.dayIndex == 0),
          isFalse);
    });

    test('R31: Sahur offset crossing midnight lands on the previous civil day', () {
      // Imsak 00:20, offset 60 → fire 23:20 previous day.
      final day = _day(DateTime(2025, 3, 10), fajrH: 0)
          .copyWith(fajr: DateTime(2025, 3, 10, 0, 20));
      final s = scheduler.buildSchedules(
        days: [day],
        settings: const RamadanSettings(
            sahurEnabled: true, iftarEnabled: false, sahurOffsetMinutes: 60),
      );
      expect(s.first.fireTime, DateTime(2025, 3, 9, 23, 20));
    });

    test('R32: schedules never exceed the horizon even with more days', () {
      final days = _week(DateTime(2025, 3, 10))
        ..addAll(_week(DateTime(2025, 3, 17)));
      final s = scheduler.buildSchedules(
        days: days,
        settings: const RamadanSettings(
            sahurEnabled: true, iftarEnabled: true),
      );
      expect(s.length, lessThanOrEqualTo(
          RamadanNotificationScheduler.horizonDays * 2));
    });
  });

  // ── scheduleWeek ─────────────────────────────────────────────────────────
  group('scheduleWeek', () {
    test('R33: cancels via SCOPED cancelIds — never cancelAll', () async {
      final fake = _FakeNotificationService();
      final scheduler = RamadanNotificationScheduler(fake);
      await scheduler.scheduleWeek(
        days: _week(DateTime(2025, 3, 10)),
        settings: const RamadanSettings(),
        copy: _copy(),
      );
      expect(fake.cancelAllCount, 0, reason: 'cancelAll must never be called');
      expect(fake.cancelIdsCalls.length, 1);
      expect(fake.cancelIdsCalls.first,
          RamadanNotificationScheduler.ramadanScheduleIds());
    });

    test('R34: scheduled ids all live in 2000..2099', () async {
      final fake = _FakeNotificationService();
      final scheduler = RamadanNotificationScheduler(fake);
      await scheduler.scheduleWeek(
        days: _week(DateTime(2025, 3, 10)),
        settings: const RamadanSettings(),
        copy: _copy(),
      );
      for (final c in fake.scheduled) {
        expect(c['id'] as int, inInclusiveRange(2000, 2099));
      }
    });

    test('R35: Ramadan reminders do NOT use the adhan channel', () async {
      final fake = _FakeNotificationService();
      final scheduler = RamadanNotificationScheduler(fake);
      await scheduler.scheduleWeek(
        days: _week(DateTime(2025, 3, 10)),
        settings: const RamadanSettings(),
        copy: _copy(),
      );
      for (final c in fake.scheduled) {
        expect(c['useAdhanChannel'] as bool, isFalse);
      }
    });

    test('R36: locationTzId is forwarded to every scheduleAt', () async {
      final fake = _FakeNotificationService();
      final scheduler = RamadanNotificationScheduler(fake);
      await scheduler.scheduleWeek(
        days: _week(DateTime(2025, 3, 10)),
        settings: const RamadanSettings(),
        copy: _copy(),
        locationTzId: 'Europe/Istanbul',
      );
      expect(fake.scheduled, isNotEmpty);
      for (final c in fake.scheduled) {
        expect(c['locationTzId'], 'Europe/Istanbul');
      }
    });

    test('R37: cancel() delegates to scoped cancelIds only', () async {
      final fake = _FakeNotificationService();
      final scheduler = RamadanNotificationScheduler(fake);
      await scheduler.cancel();
      expect(fake.cancelAllCount, 0);
      expect(fake.cancelIdsCalls.single,
          RamadanNotificationScheduler.ramadanScheduleIds());
    });
  });

  // ── iOS capacity audit ───────────────────────────────────────────────────
  group('iOS pending-notification capacity', () {
    test('R38: prayer week + Ramadan week stays within the iOS 64 cap', () {
      // Prayer schedule worst case: scheduleWindowDays × 5 obligatory prayers.
      final prayerMax = PrayerConstants.scheduleWindowDays * 5;
      final ramadanMax = RamadanNotificationScheduler.horizonDays * 2;
      expect(prayerMax + ramadanMax,
          lessThanOrEqualTo(PrayerConstants.iosMaxPendingNotifications),
          reason:
              'prayer($prayerMax) + ramadan($ramadanMax) must fit in iOS 64 cap');
    });
  });
}
