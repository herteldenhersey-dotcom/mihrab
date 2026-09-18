import '../enums/asr_calculation_method.dart';
import '../enums/prayer_calculation_method.dart';
import '../models/prayer_times_model.dart';

/// Abstraction over any prayer-time calculation engine.
///
/// The default implementation ([AdhanPrayerTimeProvider]) wraps the offline
/// `adhan` package. Keeping this interface lets us swap to another provider
/// (e.g. an online Diyanet API) without touching the domain/presentation
/// layers — a hard requirement of the spec.
abstract class PrayerTimeProvider {
  /// Computes the six daily prayer times for [date] at the given coordinates.
  ///
  /// Implementations MUST return times in the device's local timezone.
  /// Manual minute offsets are applied by the caller (usecase) via
  /// [DailyPrayerTimes.applyOffsets] so the provider stays pure.
  Future<DailyPrayerTimes> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerCalculationMethod method,
    required AsrCalculationMethod asrMethod,
  });

  /// Computes the qibla direction (degrees clockwise from true north).
  double getQiblaDirection({
    required double latitude,
    required double longitude,
  });
}
