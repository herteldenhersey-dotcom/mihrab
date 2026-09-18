import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/enums/asr_calculation_method.dart';
import 'package:mihrab/domain/enums/prayer_calculation_method.dart';
import 'package:mihrab/domain/models/calculation_settings_model.dart';
import 'package:mihrab/domain/models/prayer_times_model.dart';
import 'package:mihrab/domain/providers/prayer_time_provider.dart';
import 'package:mihrab/domain/usecases/get_prayer_times_usecase.dart';

/// Hand-written fake (no codegen) that returns a fixed set of times and records
/// the arguments it was called with.
class _FakePrayerTimeProvider implements PrayerTimeProvider {
  PrayerCalculationMethod? lastMethod;
  AsrCalculationMethod? lastAsr;
  int callCount = 0;

  @override
  Future<DailyPrayerTimes> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerCalculationMethod method,
    required AsrCalculationMethod asrMethod,
  }) async {
    callCount++;
    lastMethod = method;
    lastAsr = asrMethod;
    DateTime at(int h, int m) =>
        DateTime(date.year, date.month, date.day, h, m);
    return DailyPrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      fajr: at(5, 0),
      sunrise: at(6, 30),
      dhuhr: at(13, 0),
      asr: at(16, 30),
      maghrib: at(19, 0),
      isha: at(20, 30),
    );
  }

  @override
  double getQiblaDirection({
    required double latitude,
    required double longitude,
  }) =>
      151.0;
}

void main() {
  late _FakePrayerTimeProvider fake;
  late GetPrayerTimesUseCase usecase;

  setUp(() {
    fake = _FakePrayerTimeProvider();
    usecase = GetPrayerTimesUseCase(fake);
  });

  test('forwards method & asr method from settings to provider', () async {
    const settings = CalculationSettings(
      method: PrayerCalculationMethod.diyanet,
      asrMethod: AsrCalculationMethod.hanafi,
    );
    await usecase(
      latitude: 41.0,
      longitude: 29.0,
      date: DateTime(2024, 3, 15),
      settings: settings,
    );
    expect(fake.lastMethod, PrayerCalculationMethod.diyanet);
    expect(fake.lastAsr, AsrCalculationMethod.hanafi);
  });

  test('applies manual offsets to the raw provider output', () async {
    const settings = CalculationSettings(
      offsets: ManualOffsets(fajr: -2, dhuhr: 3, isha: 5),
    );
    final result = await usecase(
      latitude: 41.0,
      longitude: 29.0,
      date: DateTime(2024, 3, 15),
      settings: settings,
    );
    expect(result.fajr, DateTime(2024, 3, 15, 4, 58)); // 5:00 - 2
    expect(result.dhuhr, DateTime(2024, 3, 15, 13, 3)); // 13:00 + 3
    expect(result.isha, DateTime(2024, 3, 15, 20, 35)); // 20:30 + 5
    // Untouched prayers keep raw values.
    expect(result.asr, DateTime(2024, 3, 15, 16, 30));
  });

  test('zero offsets return raw times unchanged', () async {
    const settings = CalculationSettings();
    final result = await usecase(
      latitude: 41.0,
      longitude: 29.0,
      date: DateTime(2024, 3, 15),
      settings: settings,
    );
    expect(result.fajr, DateTime(2024, 3, 15, 5, 0));
    expect(result.maghrib, DateTime(2024, 3, 15, 19, 0));
  });
}
