import '../../core/constants/prayer_constants.dart';
import '../../data/services/notification/prayer_notification_scheduler.dart';
import '../enums/prayer_type.dart';
import '../models/calculation_settings_model.dart';
import '../models/prayer_times_model.dart';
import 'get_prayer_times_usecase.dart';

/// Computes the next [PrayerConstants.scheduleWindowDays] of prayer times and
/// hands them to the platform [PrayerNotificationScheduler].
///
/// The localized [PrayerNotificationCopy] is supplied by the presentation
/// layer so all user-facing strings stay in the ARB files.
class ScheduleNotificationsUseCase {
  final GetPrayerTimesUseCase _getPrayerTimes;
  final PrayerNotificationScheduler _scheduler;

  ScheduleNotificationsUseCase(this._getPrayerTimes, this._scheduler);

  Future<void> call({
    required double latitude,
    required double longitude,
    required CalculationSettings settings,
    required PrayerNotificationCopy copy,
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
      enabledPrayers: enabledPrayers,
    );
  }

  Future<void> cancelAll() => _scheduler.cancelAll();
}
