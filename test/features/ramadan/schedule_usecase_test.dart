// test/features/ramadan/schedule_usecase_test.dart
//
// Phase 6 — ScheduleRamadanNotificationsUseCase tests (R39–R44).
// Verifies it reuses GetPrayerTimesUseCase (no duplicated calc), builds the
// full horizon, forwards the timezone, and clears (scoped) when disabled.

import 'package:flutter_test/flutter_test.dart';

import 'package:mihrab/data/services/notification/notification_service.dart';
import 'package:mihrab/data/services/ramadan/ramadan_notification_scheduler.dart';
import 'package:mihrab/domain/entities/ramadan_settings.dart';
import 'package:mihrab/domain/models/calculation_settings_model.dart';
import 'package:mihrab/domain/models/prayer_times_model.dart';
import 'package:mihrab/domain/usecases/get_prayer_times_usecase.dart';
import 'package:mihrab/domain/usecases/schedule_ramadan_notifications_usecase.dart';

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
    scheduled.add({'id': id, 'when': when, 'locationTzId': locationTzId});
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
  Future<void> sendTestNotification(
      {required String title, required String body, int secondsAhead = 5}) async {}
  @override
  Future<NotificationDiagnostics> getDiagnostics() async =>
      NotificationDiagnostics(pendingCount: scheduled.length);
}

class _FakeGetPrayerTimesUseCase implements GetPrayerTimesUseCase {
  int callCount = 0;
  @override
  Future<DailyPrayerTimes> call({
    required double latitude,
    required double longitude,
    required DateTime date,
    required CalculationSettings settings,
  }) async {
    callCount++;
    return DailyPrayerTimes(
      date: date,
      fajr: DateTime(date.year, date.month, date.day, 5, 0),
      sunrise: DateTime(date.year, date.month, date.day, 6, 30),
      dhuhr: DateTime(date.year, date.month, date.day, 12, 0),
      asr: DateTime(date.year, date.month, date.day, 15, 30),
      maghrib: DateTime(date.year, date.month, date.day, 18, 30),
      isha: DateTime(date.year, date.month, date.day, 19, 30),
    );
  }
}

RamadanNotificationCopy _copy() => RamadanNotificationCopy(
      sahurTitle: (_) => 'S',
      sahurBody: (_) => 'Sb',
      iftarTitle: (_) => 'I',
      iftarBody: (_) => 'Ib',
    );

void main() {
  late _FakeNotificationService notif;
  late _FakeGetPrayerTimesUseCase prayer;
  late RamadanNotificationScheduler scheduler;
  late ScheduleRamadanNotificationsUseCase useCase;

  setUp(() {
    notif = _FakeNotificationService();
    prayer = _FakeGetPrayerTimesUseCase();
    scheduler = RamadanNotificationScheduler(notif);
    useCase = ScheduleRamadanNotificationsUseCase(prayer, scheduler);
  });

  test('R39: reuses GetPrayerTimesUseCase for exactly horizonDays days', () async {
    await useCase.call(
      latitude: 41.0,
      longitude: 29.0,
      settings: const CalculationSettings(),
      ramadanSettings: const RamadanSettings(),
      copy: _copy(),
      from: DateTime(2025, 3, 10),
    );
    expect(prayer.callCount, RamadanNotificationScheduler.horizonDays);
  });

  test('R40: schedules both reminders across the horizon', () async {
    await useCase.call(
      latitude: 41.0,
      longitude: 29.0,
      settings: const CalculationSettings(),
      ramadanSettings: const RamadanSettings(),
      copy: _copy(),
      from: DateTime(2025, 3, 10, 0, 0),
    );
    // 7 days × 2 reminders, all future relative to from.
    expect(notif.scheduled.length, 14);
  });

  test('R41: forwards locationTzId to the scheduler', () async {
    await useCase.call(
      latitude: 41.0,
      longitude: 29.0,
      settings: const CalculationSettings(),
      ramadanSettings: const RamadanSettings(),
      copy: _copy(),
      locationTzId: 'Europe/Istanbul',
      from: DateTime(2025, 3, 10, 0, 0),
    );
    expect(notif.scheduled.first['locationTzId'], 'Europe/Istanbul');
  });

  test('R42: both reminders disabled → scoped cancel, no scheduling', () async {
    await useCase.call(
      latitude: 41.0,
      longitude: 29.0,
      settings: const CalculationSettings(),
      ramadanSettings: const RamadanSettings(
          sahurEnabled: false, iftarEnabled: false),
      copy: _copy(),
      from: DateTime(2025, 3, 10),
    );
    expect(notif.scheduled, isEmpty);
    expect(notif.cancelAllCount, 0);
    expect(notif.cancelIdsCalls, isNotEmpty);
    expect(prayer.callCount, 0, reason: 'no prayer calc when nothing enabled');
  });

  test('R43: scheduleWeek always issues a scoped cancel first', () async {
    await useCase.call(
      latitude: 41.0,
      longitude: 29.0,
      settings: const CalculationSettings(),
      ramadanSettings: const RamadanSettings(),
      copy: _copy(),
      from: DateTime(2025, 3, 10, 0, 0),
    );
    expect(notif.cancelIdsCalls.first,
        RamadanNotificationScheduler.ramadanScheduleIds());
    expect(notif.cancelAllCount, 0);
  });

  test('R44: cancel() clears scoped Ramadan ids', () async {
    await useCase.cancel();
    expect(notif.cancelIdsCalls.single,
        RamadanNotificationScheduler.ramadanScheduleIds());
  });
}
