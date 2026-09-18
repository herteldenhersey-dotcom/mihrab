import '../../../core/constants/prayer_constants.dart';
import '../../../domain/enums/prayer_type.dart';
import '../../../domain/models/prayer_times_model.dart';

/// Builds the (title, body) shown for a given prayer notification.
///
/// Injected by the presentation layer so all copy stays localized while the
/// data-layer scheduler remains framework-agnostic.
class PrayerNotificationCopy {
  final String Function(PrayerType type) title;
  final String Function(PrayerType type, DateTime time) body;

  const PrayerNotificationCopy({required this.title, required this.body});
}

/// Abstract rolling scheduler for prayer notifications.
///
/// Implementations schedule a bounded window of upcoming prayers (see
/// [PrayerConstants.scheduleWindowDays]) and are expected to be re-invoked
/// whenever the app is foregrounded so the window keeps rolling forward.
abstract class PrayerNotificationScheduler {
  /// Schedules notifications for the provided [days] (chronological).
  ///
  /// [enabledPrayers] optionally restricts which prayers fire (defaults to the
  /// five obligatory prayers; sunrise is opt-in).
  Future<void> scheduleWeek({
    required List<DailyPrayerTimes> days,
    required PrayerNotificationCopy copy,
    Set<PrayerType>? enabledPrayers,
  });

  Future<void> cancelAll();

  Future<int> pendingCount();
}

/// Shared helpers for concrete schedulers.
mixin PrayerSchedulerIdMixin {
  /// Deterministic, collision-free id per (dayIndex, prayer) so re-scheduling
  /// overwrites the same slot instead of duplicating.
  int notificationId(int dayIndex, PrayerType prayer) {
    return PrayerConstants.notificationIdBase +
        dayIndex * 10 +
        prayer.index;
  }

  /// Default enabled prayers: the five obligatory prayers (sunrise excluded).
  Set<PrayerType> defaultEnabled() =>
      PrayerType.values.where((p) => p.isObligatory).toSet();
}
