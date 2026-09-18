import '../../../core/constants/prayer_constants.dart';
import '../../../domain/enums/prayer_type.dart';
import '../../../domain/models/prayer_times_model.dart';
import 'notification_service.dart';
import 'prayer_notification_scheduler.dart';

/// iOS rolling scheduler.
///
/// iOS caps PENDING local notifications at 64 (OS-enforced) and does NOT
/// guarantee background execution. Strategy & documented limitations:
///
///  * We schedule at most [PrayerConstants.iosMaxPendingNotifications] (64)
///    notifications per pass, prioritising the soonest prayers first.
///  * With 5 obligatory prayers that is ~12 days of coverage; with sunrise
///    enabled (6/day) it is ~10 days. We target a 7-day window
///    ([PrayerConstants.scheduleWindowDays]) and re-schedule every time the
///    app is foregrounded, so under normal usage the window keeps rolling.
///  * LIMITATION: if the user does NOT open the app for longer than the
///    scheduled window, iOS will run out of pending notifications and prayers
///    beyond the window will NOT fire. iOS provides no reliable way to
///    re-arm notifications purely in the background. This is an OS constraint,
///    not an app bug, and is surfaced to the user in Settings.
///  * LIMITATION: iOS does not allow custom notification sounds to bypass
///    Silent Mode / Focus. Time-sensitive interruption level is requested to
///    improve delivery, but silent-mode behaviour remains user/OS controlled.
class IosPrayerNotificationScheduler
    with PrayerSchedulerIdMixin
    implements PrayerNotificationScheduler {
  final NotificationService _service;

  IosPrayerNotificationScheduler(this._service);

  @override
  Future<void> scheduleWeek({
    required List<DailyPrayerTimes> days,
    required PrayerNotificationCopy copy,
    Set<PrayerType>? enabledPrayers,
  }) async {
    final enabled = enabledPrayers ?? defaultEnabled();
    await _service.cancelAll();

    final now = DateTime.now();
    // Flatten to a chronological list of (dayIndex, prayer, time), future-only.
    final slots = <({int dayIndex, PrayerType prayer, DateTime time})>[];
    for (var d = 0;
        d < days.length && d < PrayerConstants.scheduleWindowDays;
        d++) {
      for (final entry in days[d].ordered) {
        if (!enabled.contains(entry.key)) continue;
        if (entry.value.isAfter(now)) {
          slots.add((dayIndex: d, prayer: entry.key, time: entry.value));
        }
      }
    }

    slots.sort((a, b) => a.time.compareTo(b.time));

    // Respect the iOS 64-pending cap.
    final capped = slots.take(PrayerConstants.iosMaxPendingNotifications);

    for (final slot in capped) {
      await _service.scheduleAt(
        id: notificationId(slot.dayIndex, slot.prayer),
        title: copy.title(slot.prayer),
        body: copy.body(slot.prayer, slot.time),
        when: slot.time,
        payload: 'prayer:${slot.prayer.key}',
        exact: true,
      );
    }
  }

  @override
  Future<void> cancelAll() => _service.cancelAll();

  @override
  Future<int> pendingCount() => _service.pendingCount();
}
