import '../../../core/constants/prayer_constants.dart';
import '../../../domain/enums/prayer_type.dart';
import '../../../domain/models/notification_settings_model.dart';
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
///    forward.
///
/// Phase 5 additions:
///  * [NotificationSettings] drives per-prayer enable/adhan/offset config.
///  * Reminder offset: fire notification [offset] minutes BEFORE prayer time.
///  * Adhan channel: route to [PrayerConstants.adhanChannelId] when enabled.
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
    NotificationSettings? notificationSettings,
    Set<PrayerType>? enabledPrayers,
  }) async {
    // Resolve which prayers to schedule.
    final enabled = resolveEnabledPrayers(notificationSettings, enabledPrayers);
    final useExact = await _alarmPermission.canScheduleExactAlarms();

    await _service.cancelAll();

    if (enabled.isEmpty) return; // master switch off or no prayers enabled

    final now = DateTime.now();
    for (var d = 0;
        d < days.length && d < PrayerConstants.scheduleWindowDays;
        d++) {
      for (final entry in days[d].ordered) {
        final prayer = entry.key;
        if (!enabled.contains(prayer)) continue;

        // Per-prayer config (defaults if no settings provided).
        final config = notificationSettings?.prayerConfigs[prayer] ??
            const PrayerNotificationConfig();

        final fireTime = adjustedFireTime(entry.value, config);
        if (!fireTime.isAfter(now)) continue;

        await _service.scheduleAt(
          id: notificationId(d, prayer),
          title: copy.title(prayer),
          body: copy.body(prayer, entry.value),
          when: fireTime,
          payload: 'prayer:${prayer.key}',
          exact: useExact,
          useAdhanChannel: useAdhanChannel(prayer, config),
        );
      }
    }
  }

  /// Fallback integration point: register a periodic WorkManager task that
  /// wakes ~daily to recompute and re-arm the schedule when exact alarms are
  /// unavailable or the app is rarely opened.  No-op hook in current phase.
  Future<void> rescheduleWithWorkManager() async {
    // Intentionally a no-op. See android_notification_scheduler docs; wiring
    // Workmanager.registerPeriodicTask lands in a later phase.
  }

  @override
  Future<void> cancelAll() => _service.cancelAll();

  @override
  Future<int> pendingCount() => _service.pendingCount();
}
