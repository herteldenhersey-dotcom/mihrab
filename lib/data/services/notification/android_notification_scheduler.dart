import '../../../core/constants/prayer_constants.dart';
import '../../../domain/enums/prayer_type.dart';
import '../../../domain/models/prayer_times_model.dart';
import 'alarm_permission_service.dart';
import 'notification_service.dart';
import 'prayer_notification_scheduler.dart';

/// Android rolling scheduler with an exact→inexact fallback.
///
/// Behaviour:
///  * Checks [AlarmPermissionService.canScheduleExactAlarms]. If exact alarms
///    are allowed (Android <12, or the user granted SCHEDULE_EXACT_ALARM), we
///    schedule with `exactAllowWhileIdle` so reminders fire precisely even in
///    Doze.
///  * If exact alarms are NOT allowed, we fall back to INEXACT alarms
///    (`inexactAllowWhileIdle`). These may fire a few minutes late but never
///    fail to fire, keeping the app Google-Play-policy compliant without
///    forcing the user through the exact-alarm settings screen.
///  * Android has no 64-notification cap, but we still schedule only the
///    [PrayerConstants.scheduleWindowDays] window and rely on app foregrounding
///    (and, in a later phase, a WorkManager periodic worker) to roll it
///    forward. [rescheduleWithWorkManager] documents that integration point.
class AndroidPrayerNotificationScheduler
    with PrayerSchedulerIdMixin
    implements PrayerNotificationScheduler {
  final NotificationService _service;
  final AlarmPermissionService _alarmPermission;

  AndroidPrayerNotificationScheduler(this._service, this._alarmPermission);

  @override
  Future<void> scheduleWeek({
    required List<DailyPrayerTimes> days,
    required PrayerNotificationCopy copy,
    Set<PrayerType>? enabledPrayers,
  }) async {
    final enabled = enabledPrayers ?? defaultEnabled();
    final useExact = await _alarmPermission.canScheduleExactAlarms();

    await _service.cancelAll();

    final now = DateTime.now();
    for (var d = 0;
        d < days.length && d < PrayerConstants.scheduleWindowDays;
        d++) {
      for (final entry in days[d].ordered) {
        if (!enabled.contains(entry.key)) continue;
        if (!entry.value.isAfter(now)) continue;
        await _service.scheduleAt(
          id: notificationId(d, entry.key),
          title: copy.title(entry.key),
          body: copy.body(entry.key, entry.value),
          when: entry.value,
          payload: 'prayer:${entry.key.key}',
          exact: useExact,
        );
      }
    }
  }

  /// Fallback integration point (Phase 2): register a periodic WorkManager
  /// task that wakes ~daily to recompute and re-arm the schedule when exact
  /// alarms are unavailable or the app is rarely opened. Kept as a documented
  /// no-op hook in Phase 1 so the call site already exists.
  Future<void> rescheduleWithWorkManager() async {
    // Intentionally a no-op in Phase 1. See android_notification_scheduler
    // docs; wiring Workmanager.registerPeriodicTask lands in a later phase.
  }

  @override
  Future<void> cancelAll() => _service.cancelAll();

  @override
  Future<int> pendingCount() => _service.pendingCount();
}
