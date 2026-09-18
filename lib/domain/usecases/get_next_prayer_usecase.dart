import '../../core/utils/prayer_time_utils.dart';
import '../models/calculation_settings_model.dart';
import 'get_prayer_times_usecase.dart';

/// Determines the next upcoming prayer, correctly handling the post-Isha
/// window by also computing tomorrow's times.
class GetNextPrayerUseCase {
  final GetPrayerTimesUseCase _getPrayerTimes;

  GetNextPrayerUseCase(this._getPrayerTimes);

  Future<NextPrayer> call({
    required double latitude,
    required double longitude,
    required CalculationSettings settings,
    DateTime? now,
  }) async {
    final reference = now ?? DateTime.now();
    final today = await _getPrayerTimes(
      latitude: latitude,
      longitude: longitude,
      date: reference,
      settings: settings,
    );
    final tomorrow = await _getPrayerTimes(
      latitude: latitude,
      longitude: longitude,
      date: reference.add(const Duration(days: 1)),
      settings: settings,
    );
    return PrayerTimeUtils.getNextPrayer(today, reference, tomorrow: tomorrow);
  }
}
