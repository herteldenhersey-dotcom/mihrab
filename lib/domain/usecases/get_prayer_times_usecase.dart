import '../models/calculation_settings_model.dart';
import '../models/prayer_times_model.dart';
import '../providers/prayer_time_provider.dart';

/// Computes prayer times for a given day/location and applies the user's
/// manual minute offsets (the Diyanet reconciliation mechanism).
class GetPrayerTimesUseCase {
  final PrayerTimeProvider _provider;

  GetPrayerTimesUseCase(this._provider);

  Future<DailyPrayerTimes> call({
    required double latitude,
    required double longitude,
    required DateTime date,
    required CalculationSettings settings,
  }) async {
    final raw = await _provider.getPrayerTimes(
      latitude: latitude,
      longitude: longitude,
      date: date,
      method: settings.method,
      asrMethod: settings.asrMethod,
    );
    return raw.applyOffsets(settings.offsets);
  }
}
