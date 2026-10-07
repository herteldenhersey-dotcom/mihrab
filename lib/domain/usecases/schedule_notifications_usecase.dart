import '../../core/constants/prayer_constants.dart';
import '../../data/services/notification/prayer_notification_scheduler.dart';
import '../enums/prayer_type.dart';
import '../models/calculation_settings_model.dart';
import '../models/notification_settings_model.dart';
import '../models/prayer_times_model.dart';
import 'get_prayer_times_usecase.dart';

/// Computes the next [PrayerConstants.scheduleWindowDays] of prayer times and
/// hands them to the platform [PrayerNotificationScheduler].
///
/// The localized [PrayerNotificationCopy] is supplied by the presentation
/// layer so all user-facing strings stay in the ARB files.
///
/// Phase 5: accepts [NotificationSettings] for per-prayer config (enabled,
/// adhan channel, reminder offset). Falls back to legacy [enabledPrayers] if
/// [notificationSettings] is null.
class ScheduleNotificationsUseCase {
  final GetPrayerTimesUseCase _getPrayerTimes;
  final PrayerNotificationScheduler _scheduler;

  ScheduleNotificationsUseCase(this._getPrayerTimes, this._scheduler);

  Future<void> call({
    required double latitude,
    required double longitude,
    required CalculationSettings settings,
    required PrayerNotificationCopy copy,
    String? locationTzId,
    NotificationSettings? notificationSettings,
    Set<PrayerType>? enabledPrayers,
    DateTime? from,
  }) async {
    final start = from ?? DateTime.now();
    final days = <DailyPrayerTimes>[];
    for (var i = 0; i < PrayerConstants.scheduleWindowDays; i++) {
      days.add(
        await _getPrayerTimes(
          latitude: latitude,
          longitude: longitude,
          date: start.add(Duration(days: i)),
          settings: settings,
        ),
      );
    }
    await _scheduler.scheduleWeek(
      days: days,
      copy: copy,
      locationTzId: locationTzId,
      notificationSettings: notificationSettings,
      enabledPrayers: enabledPrayers,
    );
  }

  Future<void> cancelAll() => _scheduler.cancelAll();
}
