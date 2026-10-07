import '../../../domain/entities/ramadan_notification_schedule.dart';
import '../../../domain/entities/ramadan_settings.dart';
import '../../../domain/models/prayer_times_model.dart';
import '../notification/notification_service.dart';

/// Localized copy for Ramadan notifications. Supplied by the presentation layer
/// so the data layer stays framework-/locale-agnostic.
class RamadanNotificationCopy {
  final String Function(DateTime imsakTime) sahurTitle;
  final String Function(DateTime imsakTime) sahurBody;
  final String Function(DateTime iftarTime) iftarTitle;
  final String Function(DateTime iftarTime) iftarBody;

  const RamadanNotificationCopy({
    required this.sahurTitle,
    required this.sahurBody,
    required this.iftarTitle,
    required this.iftarBody,
  });
}

/// Schedules Ramadan Sahur/Iftar reminders.
///
/// Notification ID ownership (spec §10 — CRITICAL, zero collisions):
/// ─────────────────────────────────────────────────────────────────────────
///   • Test notification .......... id 0        (PrayerConstants.testNotificationId)
///   • Prayer schedule ............ ids 1000–1065
///   • Ramadan schedule ........... ids 2000–2099  ← THIS scheduler
///
/// Ramadan id formula: [ramadanIdBase] + dayIndex × 2 + typeOffset
///   typeOffset: sahur = 0, iftar = 1
///   dayIndex 0..6 (7-day horizon) → ids 2000..2013. The 2000–2099 range leaves
///   generous headroom and NEVER overlaps the prayer (1000–1065) or test (0) ids.
///
/// Scheduling horizon: [horizonDays] (default 7) → up to 14 reminders
/// (2 per day). Combined with the prayer week this stays within the iOS 64
/// pending-notification cap (audit in PHASE6_COMPLETION_REPORT.md).
///
/// Cancellation: ALWAYS scoped via [NotificationService.cancelIds] over
/// [ramadanScheduleIds] — NEVER [NotificationService.cancelAll], so prayer and
/// test notifications are never collaterally removed.
class RamadanNotificationScheduler {
  final NotificationService _service;

  RamadanNotificationScheduler(this._service);

  /// Base id for Ramadan notifications. Range: [ramadanIdBase] .. +99.
  static const int ramadanIdBase = 2000;

  /// Number of days scheduled in one pass.
  static const int horizonDays = 7;

  /// Deterministic id for a (dayIndex, type) pair. Collision-free with prayer
  /// (1000–1065) and test (0) ids.
  static int notificationId(int dayIndex, RamadanReminderType type) {
    final typeOffset = type == RamadanReminderType.sahur ? 0 : 1;
    return ramadanIdBase + dayIndex * 2 + typeOffset;
  }

  /// All Ramadan ids that could be scheduled across the full horizon.
  /// Used for SCOPED cancellation.
  static List<int> ramadanScheduleIds() {
    return [
      for (var d = 0; d < horizonDays; d++)
        for (final t in RamadanReminderType.values) notificationId(d, t),
    ];
  }

  /// Builds the list of reminder instants from [days] prayer times and
  /// [settings]. Sahur uses Imsak (= Fajr); Iftar uses Maghrib (spec §5/§6).
  ///
  /// Offsets may cross midnight (e.g. Sahur 60 min before a 04:30 Imsak →
  /// 03:30; a reminder could legitimately fall on the previous civil day). The
  /// fire time is computed by plain subtraction so day/boundary crossings are
  /// handled naturally (spec §10).
  ///
  /// [imsakFor]/[iftarFor] extract the event times; defaults use Fajr/Maghrib.
  List<RamadanNotificationSchedule> buildSchedules({
    required List<DailyPrayerTimes> days,
    required RamadanSettings settings,
    DateTime Function(DailyPrayerTimes day)? imsakFor,
    DateTime Function(DailyPrayerTimes day)? iftarFor,
    DateTime? now,
  }) {
    final imsakExtract = imsakFor ?? (d) => d.fajr;
    final iftarExtract = iftarFor ?? (d) => d.maghrib;
    final reference = now;

    final out = <RamadanNotificationSchedule>[];
    final count = days.length < horizonDays ? days.length : horizonDays;
    for (var i = 0; i < count; i++) {
      final day = days[i];
      if (settings.sahurEnabled) {
        final imsak = imsakExtract(day);
        final fire =
            imsak.subtract(Duration(minutes: settings.sahurOffsetMinutes));
        if (reference == null || fire.isAfter(reference)) {
          out.add(RamadanNotificationSchedule(
            id: notificationId(i, RamadanReminderType.sahur),
            type: RamadanReminderType.sahur,
            dayIndex: i,
            eventTime: imsak,
            fireTime: fire,
          ));
        }
      }
      if (settings.iftarEnabled) {
        final iftar = iftarExtract(day);
        final fire =
            iftar.subtract(Duration(minutes: settings.iftarOffsetMinutes));
        if (reference == null || fire.isAfter(reference)) {
          out.add(RamadanNotificationSchedule(
            id: notificationId(i, RamadanReminderType.iftar),
            type: RamadanReminderType.iftar,
            dayIndex: i,
            eventTime: iftar,
            fireTime: fire,
          ));
        }
      }
    }
    return out;
  }

  /// Cancels existing Ramadan notifications (scoped) then schedules the window.
  ///
  /// [locationTzId] is the selected location's IANA timezone (spec §10).
  /// [exact] controls Android exact vs. inexact alarm scheduling.
  Future<void> scheduleWeek({
    required List<DailyPrayerTimes> days,
    required RamadanSettings settings,
    required RamadanNotificationCopy copy,
    String? locationTzId,
    bool exact = true,
    DateTime Function(DailyPrayerTimes day)? imsakFor,
    DateTime Function(DailyPrayerTimes day)? iftarFor,
    DateTime? now,
  }) async {
    // Scoped cancel — NEVER cancelAll().
    await _service.cancelIds(ramadanScheduleIds());

    final schedules = buildSchedules(
      days: days,
      settings: settings,
      imsakFor: imsakFor,
      iftarFor: iftarFor,
      now: now,
    );

    for (final s in schedules) {
      final isSahur = s.type == RamadanReminderType.sahur;
      await _service.scheduleAt(
        id: s.id,
        title: isSahur ? copy.sahurTitle(s.eventTime) : copy.iftarTitle(s.eventTime),
        body: isSahur ? copy.sahurBody(s.eventTime) : copy.iftarBody(s.eventTime),
        when: s.fireTime,
        locationTzId: locationTzId,
        exact: exact,
        // Sahur/Iftar are ordinary reminders, NOT the adhan channel (spec §8).
        useAdhanChannel: false,
        payload: 'ramadan_${isSahur ? 'sahur' : 'iftar'}',
      );
    }
  }

  /// Cancels all Ramadan notifications (scoped).
  Future<void> cancel() => _service.cancelIds(ramadanScheduleIds());
}
