import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/enums/asr_calculation_method.dart';
import 'package:mihrab/domain/enums/prayer_calculation_method.dart';
import 'package:mihrab/domain/enums/prayer_type.dart';
import 'package:mihrab/domain/models/calculation_settings_model.dart';
import 'package:mihrab/domain/models/prayer_times_model.dart';
import 'package:mihrab/domain/providers/prayer_time_provider.dart';
import 'package:mihrab/domain/usecases/get_next_prayer_usecase.dart';
import 'package:mihrab/domain/usecases/get_prayer_times_usecase.dart';

/// Fake provider returning fixed daily times per requested date.
class _FakePrayerTimeProvider implements PrayerTimeProvider {
  @override
  Future<DailyPrayerTimes> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerCalculationMethod method,
    required AsrCalculationMethod asrMethod,
  }) async {
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
  late GetNextPrayerUseCase usecase;

  setUp(() {
    final getTimes = GetPrayerTimesUseCase(_FakePrayerTimeProvider());
    usecase = GetNextPrayerUseCase(getTimes);
  });

  const settings = CalculationSettings();

  test('midday → returns Asr (today)', () async {
    final next = await usecase(
      latitude: 41.0,
      longitude: 29.0,
      settings: settings,
      now: DateTime(2024, 3, 15, 14, 0),
    );
    expect(next.type, PrayerType.asr);
    expect(next.isTomorrow, isFalse);
  });

  test('post-Isha → returns tomorrow Fajr (uses tomorrow computation)',
      () async {
    final next = await usecase(
      latitude: 41.0,
      longitude: 29.0,
      settings: settings,
      now: DateTime(2024, 3, 15, 22, 0),
    );
    expect(next.type, PrayerType.fajr);
    expect(next.isTomorrow, isTrue);
    expect(next.time, DateTime(2024, 3, 16, 5, 0));
  });
}
