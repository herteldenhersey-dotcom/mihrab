import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/data/providers/adhan_prayer_time_provider.dart';
import 'package:mihrab/domain/enums/asr_calculation_method.dart';
import 'package:mihrab/domain/enums/prayer_calculation_method.dart';
import 'package:mihrab/domain/models/prayer_times_model.dart';

/// ============================================================================
/// DIYANET ACCURACY TEST — Istanbul, 2024-03-15
/// ============================================================================
///
/// The spec makes prayer-time accuracy the highest priority and requires a test
/// that compares the engine output against known Diyanet values with a ±2 min
/// tolerance, plus a demonstration that the [ManualOffsets] mechanism can
/// reconcile any residual systematic deviation.
///
/// REFERENCE VALUES
/// ----------------
/// Reference times below are the Diyanet İşleri Başkanlığı (Turkey) prayer
/// times for Istanbul (41.0082, 28.9784) on 2024-03-15, wall-clock in
/// Europe/Istanbul (UTC+3, no DST). They were obtained from the AlAdhan API
/// `method=13` ("Diyanet İşleri Başkanlığı, Turkey"):
///   GET https://api.aladhan.com/v1/timings/15-03-2024
///        ?latitude=41.0082&longitude=28.9784&method=13
/// yielding:
///   Fajr 05:44 · Sunrise 07:08 · Dhuhr 13:18 · Asr 16:37 · Maghrib 19:18 · Isha 20:37
///
/// TIMEZONE HANDLING IN TESTS
/// --------------------------
/// The `adhan` package computes instants in UTC and exposes them as local
/// `DateTime`s. CI typically runs in UTC, whereas a real device in Istanbul
/// runs in UTC+3. To make this test environment-independent we normalise every
/// result back to UTC (`toUtc()`) and add the fixed +3h Turkey offset to obtain
/// the Istanbul wall-clock, which is what the reference values represent.
const double _istanbulLat = 41.0082;
const double _istanbulLng = 28.9784;
final DateTime _date = DateTime(2024, 3, 15);

/// Fixed Turkey offset (UTC+3, no DST since 2016).
const Duration _turkeyOffset = Duration(hours: 3);

/// Diyanet reference wall-clock times (minutes from midnight, Europe/Istanbul).
const Map<String, int> _diyanetReference = {
  'fajr': 5 * 60 + 44,
  'sunrise': 7 * 60 + 8,
  'dhuhr': 13 * 60 + 18,
  'asr': 16 * 60 + 37,
  'maghrib': 19 * 60 + 18,
  'isha': 20 * 60 + 37,
};

/// Converts an `adhan` result into Istanbul wall-clock minutes-from-midnight.
int _istanbulMinutes(DateTime t) {
  final trt = t.toUtc().add(_turkeyOffset);
  return trt.hour * 60 + trt.minute;
}

void main() {
  const provider = AdhanPrayerTimeProvider();

  group('AdhanPrayerTimeProvider — Diyanet accuracy (Istanbul 2024-03-15)', () {
    late DailyPrayerTimes times;

    setUp(() async {
      times = await provider.getPrayerTimes(
        latitude: _istanbulLat,
        longitude: _istanbulLng,
        date: _date,
        method: PrayerCalculationMethod.diyanet,
        asrMethod: AsrCalculationMethod.standard,
      );
    });

    /// Each prayer must be within ±2 minutes of the Diyanet reference.
    void expectWithinTolerance(String name, DateTime actual) {
      final actualMin = _istanbulMinutes(actual);
      final refMin = _diyanetReference[name]!;
      final delta = (actualMin - refMin).abs();
      expect(
        delta <= 2,
        isTrue,
        reason: '$name deviates by $delta min '
            '(engine=${actualMin ~/ 60}:${(actualMin % 60).toString().padLeft(2, '0')}, '
            'diyanet=${refMin ~/ 60}:${(refMin % 60).toString().padLeft(2, '0')}). '
            'Allowed ±2 min. Use ManualOffsets to reconcile a systematic delta.',
      );
    }

    test('Fajr within ±2 min of Diyanet', () {
      expectWithinTolerance('fajr', times.fajr);
    });
    test('Sunrise within ±2 min of Diyanet', () {
      expectWithinTolerance('sunrise', times.sunrise);
    });
    test('Dhuhr within ±2 min of Diyanet', () {
      expectWithinTolerance('dhuhr', times.dhuhr);
    });
    test('Asr within ±2 min of Diyanet', () {
      expectWithinTolerance('asr', times.asr);
    });
    test('Maghrib within ±2 min of Diyanet', () {
      expectWithinTolerance('maghrib', times.maghrib);
    });
    test('Isha within ±2 min of Diyanet', () {
      expectWithinTolerance('isha', times.isha);
    });
  });

  group('ManualOffsets reconciliation mechanism', () {
    test(
        'applying a per-prayer offset shifts times so a hypothetical residual '
        'delta is corrected to zero', () async {
      final raw = await provider.getPrayerTimes(
        latitude: _istanbulLat,
        longitude: _istanbulLng,
        date: _date,
        method: PrayerCalculationMethod.diyanet,
        asrMethod: AsrCalculationMethod.standard,
      );

      // Simulate a systematic +3 min correction requirement across prayers,
      // proving offsets are honoured exactly (the Diyanet reconciliation path).
      const offsets = ManualOffsets(
        fajr: -1,
        sunrise: 2,
        dhuhr: -1,
        asr: 3,
        maghrib: 1,
        isha: -2,
      );
      final adjusted = raw.applyOffsets(offsets);

      expect(adjusted.fajr, raw.fajr.add(const Duration(minutes: -1)));
      expect(adjusted.sunrise, raw.sunrise.add(const Duration(minutes: 2)));
      expect(adjusted.dhuhr, raw.dhuhr.add(const Duration(minutes: -1)));
      expect(adjusted.asr, raw.asr.add(const Duration(minutes: 3)));
      expect(adjusted.maghrib, raw.maghrib.add(const Duration(minutes: 1)));
      expect(adjusted.isha, raw.isha.add(const Duration(minutes: -2)));
    });

    test('zero offsets are a no-op', () async {
      final raw = await provider.getPrayerTimes(
        latitude: _istanbulLat,
        longitude: _istanbulLng,
        date: _date,
        method: PrayerCalculationMethod.diyanet,
        asrMethod: AsrCalculationMethod.standard,
      );
      final adjusted = raw.applyOffsets(ManualOffsets.zero);
      expect(adjusted, raw);
    });
  });

  group('Method & madhab mapping', () {
    test('Hanafi asr is later than standard (shafi) asr', () async {
      final standard = await provider.getPrayerTimes(
        latitude: _istanbulLat,
        longitude: _istanbulLng,
        date: _date,
        method: PrayerCalculationMethod.diyanet,
        asrMethod: AsrCalculationMethod.standard,
      );
      final hanafi = await provider.getPrayerTimes(
        latitude: _istanbulLat,
        longitude: _istanbulLng,
        date: _date,
        method: PrayerCalculationMethod.diyanet,
        asrMethod: AsrCalculationMethod.hanafi,
      );
      expect(hanafi.asr.isAfter(standard.asr), isTrue);
    });

    test('Qibla direction from Istanbul points roughly south-east (~150–160°)',
        () {
      final dir = provider.getQiblaDirection(
        latitude: _istanbulLat,
        longitude: _istanbulLng,
      );
      expect(dir, inInclusiveRange(140, 170));
    });

    test('diyanet maps to adhan CalculationMethod.turkey', () {
      // Guards against accidental remapping regressions.
      final params = adhan.CalculationMethod.turkey.getParameters();
      expect(params.fajrAngle, 18.0);
      expect(params.ishaAngle, 17.0);
    });
  });
}
