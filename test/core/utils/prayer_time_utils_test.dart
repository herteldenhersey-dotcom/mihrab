import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/core/utils/prayer_time_utils.dart';
import 'package:mihrab/domain/enums/prayer_type.dart';
import 'package:mihrab/domain/models/prayer_times_model.dart';

/// Builds a [DailyPrayerTimes] for a fixed day with easy-to-reason times.
DailyPrayerTimes _day(DateTime date, {int fajrHour = 5}) {
  DateTime at(int h, int m) => DateTime(date.year, date.month, date.day, h, m);
  return DailyPrayerTimes(
    date: DateTime(date.year, date.month, date.day),
    fajr: at(fajrHour, 0),
    sunrise: at(6, 30),
    dhuhr: at(13, 0),
    asr: at(16, 30),
    maghrib: at(19, 0),
    isha: at(20, 30),
  );
}

void main() {
  final today = DateTime(2024, 3, 15);
  final tomorrow = DateTime(2024, 3, 16);

  group('getNextPrayer', () {
    test('before Fajr → returns Fajr (today)', () {
      final now = DateTime(2024, 3, 15, 4, 0);
      final next = PrayerTimeUtils.getNextPrayer(_day(today), now,
          tomorrow: _day(tomorrow));
      expect(next.type, PrayerType.fajr);
      expect(next.isTomorrow, isFalse);
    });

    test('between Dhuhr and Asr → returns Asr', () {
      final now = DateTime(2024, 3, 15, 14, 0);
      final next = PrayerTimeUtils.getNextPrayer(_day(today), now,
          tomorrow: _day(tomorrow));
      expect(next.type, PrayerType.asr);
      expect(next.isTomorrow, isFalse);
    });

    test('exactly at a prayer time → returns the NEXT prayer (strictly after)',
        () {
      final now = DateTime(2024, 3, 15, 13, 0); // exactly Dhuhr
      final next = PrayerTimeUtils.getNextPrayer(_day(today), now,
          tomorrow: _day(tomorrow));
      expect(next.type, PrayerType.asr);
    });

    test('after Isha with tomorrow provided → tomorrow Fajr', () {
      final now = DateTime(2024, 3, 15, 21, 0);
      final next = PrayerTimeUtils.getNextPrayer(_day(today), now,
          tomorrow: _day(tomorrow, fajrHour: 5));
      expect(next.type, PrayerType.fajr);
      expect(next.isTomorrow, isTrue);
      expect(next.time.day, 16);
    });

    test('after Isha without tomorrow → today Fajr advanced by one day', () {
      final now = DateTime(2024, 3, 15, 23, 30);
      final next = PrayerTimeUtils.getNextPrayer(_day(today), now);
      expect(next.type, PrayerType.fajr);
      expect(next.isTomorrow, isTrue);
      expect(next.time, DateTime(2024, 3, 16, 5, 0));
    });
  });

  group('getCurrentPrayer', () {
    test('before Fajr → null', () {
      final now = DateTime(2024, 3, 15, 3, 0);
      expect(PrayerTimeUtils.getCurrentPrayer(_day(today), now), isNull);
    });

    test('after Dhuhr, before Asr → Dhuhr', () {
      final now = DateTime(2024, 3, 15, 14, 0);
      expect(PrayerTimeUtils.getCurrentPrayer(_day(today), now),
          PrayerType.dhuhr);
    });

    test('after Isha → Isha', () {
      final now = DateTime(2024, 3, 15, 22, 0);
      expect(
          PrayerTimeUtils.getCurrentPrayer(_day(today), now), PrayerType.isha);
    });
  });

  group('getCountdown / formatCountdown', () {
    test('positive difference', () {
      final now = DateTime(2024, 3, 15, 12, 0);
      final target = DateTime(2024, 3, 15, 13, 30);
      expect(PrayerTimeUtils.getCountdown(target, now),
          const Duration(hours: 1, minutes: 30));
    });

    test('past target clamps to zero', () {
      final now = DateTime(2024, 3, 15, 14, 0);
      final target = DateTime(2024, 3, 15, 13, 0);
      expect(PrayerTimeUtils.getCountdown(target, now), Duration.zero);
    });

    test('formatCountdown pads HH:mm:ss', () {
      expect(PrayerTimeUtils.formatCountdown(const Duration(hours: 1, minutes: 5, seconds: 9)),
          '01:05:09');
      expect(PrayerTimeUtils.formatCountdown(Duration.zero), '00:00:00');
    });
  });
}
