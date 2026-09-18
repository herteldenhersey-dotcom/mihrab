import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/data/providers/adhan_prayer_time_provider.dart';
import 'package:mihrab/domain/models/calculation_settings_model.dart';
import 'package:mihrab/domain/models/location_model.dart';
import 'package:mihrab/domain/models/location_search_result.dart';
import 'package:mihrab/domain/usecases/get_prayer_times_usecase.dart';

/// INTEGRATION: a resolved onboarding location (here a manual selection) feeds
/// real coordinates into the REAL prayer-time engine and produces a valid,
/// correctly-ordered daily timetable. This proves the location → prayer-times
/// hand-off works end-to-end without any hardcoded result.
void main() {
  test('manual location coordinates produce valid, ordered prayer times',
      () async {
    // Simulate the output of a manual search selection.
    const result = LocationSearchResult(
      latitude: 41.0082,
      longitude: 28.9784,
      city: 'İstanbul',
      country: 'Türkiye',
      displayName: 'İstanbul, Türkiye',
    );
    final AppLocation location = result.toAppLocation();
    expect(location.hasValidCoordinates, isTrue);
    expect(location.isManual, isTrue);

    final usecase = GetPrayerTimesUseCase(const AdhanPrayerTimeProvider());
    final times = await usecase(
      latitude: location.latitude,
      longitude: location.longitude,
      date: DateTime(2024, 3, 15),
      settings: CalculationSettings.turkeyDefault,
    );

    // Every prayer falls on the requested day.
    for (final t in [
      times.fajr,
      times.sunrise,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha,
    ]) {
      expect(t.year, 2024);
      expect(t.month, 3);
      expect(t.day, 15);
    }

    // Strictly increasing across the day — a sanity check that the coordinates
    // produced a sensible timetable.
    expect(times.fajr.isBefore(times.sunrise), isTrue);
    expect(times.sunrise.isBefore(times.dhuhr), isTrue);
    expect(times.dhuhr.isBefore(times.asr), isTrue);
    expect(times.asr.isBefore(times.maghrib), isTrue);
    expect(times.maghrib.isBefore(times.isha), isTrue);
  });
}
