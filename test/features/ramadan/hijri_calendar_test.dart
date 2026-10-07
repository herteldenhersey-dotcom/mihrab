// test/features/ramadan/hijri_calendar_test.dart
//
// Phase 6 — HijriCalendarService unit tests (R01–R11).
// Pure Dart, no platform channels. Anchors validated against the official
// start dates of Ramadan in Turkey (Diyanet): 2024=11 Mar, 2025=1 Mar,
// 2026=18 Feb.

import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/data/services/hijri/hijri_calendar_service.dart';

void main() {
  const svc = HijriCalendarService();

  group('HijriCalendarService — conversion anchors', () {
    test('R01: 11 Mar 2024 → 1 Ramadan 1445', () {
      final h = svc.toHijri(DateTime(2024, 3, 11));
      expect(h.day, 1);
      expect(h.month, HijriCalendarService.ramadanMonth);
      expect(h.year, 1445);
    });

    test('R02: 1 Mar 2025 → 1 Ramadan 1446', () {
      final h = svc.toHijri(DateTime(2025, 3, 1));
      expect(h.day, 1);
      expect(h.month, 9);
      expect(h.year, 1446);
    });

    test('R03: 18 Feb 2026 → 1 Ramadan 1447', () {
      final h = svc.toHijri(DateTime(2026, 2, 18));
      expect(h.day, 1);
      expect(h.month, 9);
      expect(h.year, 1447);
    });
  });

  group('HijriCalendarService — isRamadan / ramadanInfo', () {
    test('R04: a mid-Ramadan date reports isRamadan=true with correct day', () {
      final info = svc.ramadanInfo(DateTime(2024, 3, 15));
      expect(info.isRamadan, isTrue);
      expect(info.dayNumber, 5); // 11 Mar = day 1 → 15 Mar = day 5
      expect(info.hijriYear, 1445);
    });

    test('R05: a non-Ramadan date reports isRamadan=false', () {
      expect(svc.isRamadan(DateTime(2024, 1, 1)), isFalse);
      final info = svc.ramadanInfo(DateTime(2024, 1, 1));
      expect(info.isRamadan, isFalse);
      expect(info.dayNumber, 0);
    });

    test('R06: first/last civil days of Ramadan 1445 are consistent', () {
      final info = svc.ramadanInfo(DateTime(2024, 3, 20));
      expect(info.firstDay, DateTime(2024, 3, 11));
      expect(info.lastDay,
          info.firstDay.add(Duration(days: info.totalDays - 1)));
    });

    test('R07: totalDays is 29 or 30 (never hardcoded)', () {
      for (final d in [
        DateTime(2024, 3, 20),
        DateTime(2025, 3, 10),
        DateTime(2026, 3, 1),
      ]) {
        final info = svc.ramadanInfo(d);
        expect(info.totalDays, anyOf(29, 30),
            reason: 'Ramadan length must be 29 or 30, got ${info.totalDays}');
      }
    });

    test('R08: outside Ramadan → next upcoming Ramadan is returned', () {
      final info = svc.ramadanInfo(DateTime(2024, 1, 1));
      expect(info.isRamadan, isFalse);
      // The next Ramadan after Jan 2024 starts 11 Mar 2024.
      expect(info.firstDay, DateTime(2024, 3, 11));
      expect(info.hijriYear, 1445);
    });
  });

  group('HijriCalendarService — month length & leap', () {
    test('R09: odd months have 30 days, even months 29 (non-leap year 12)', () {
      expect(svc.monthLength(1445, 1), 30);
      expect(svc.monthLength(1445, 2), 29);
      expect(svc.monthLength(1445, 9), 30); // Ramadan
    });

    test('R10: month 12 gains a day in a leap year', () {
      // 1443 % 30 == 3 (non-leap) ; find a leap year in {2,5,...29}.
      // 1445 % 30 = 5 → leap. 1444 % 30 = 4 → non-leap.
      expect(svc.monthLength(1445, 12), 30, reason: '1445 is a leap year');
      expect(svc.monthLength(1444, 12), 29, reason: '1444 is not a leap year');
    });
  });

  group('HijriCalendarService — adjustment', () {
    test('R11: adjustment is clamped to -3..+3 and shifts the date', () {
      expect(HijriCalendarService.clampAdjustment(10), 3);
      expect(HijriCalendarService.clampAdjustment(-10), -3);
      expect(HijriCalendarService.clampAdjustment(2), 2);
      // +1 day adjustment on 10 Mar 2024 → treated as 11 Mar → Ramadan day 1.
      final adjusted = svc.toHijri(DateTime(2024, 3, 10), adjustment: 1);
      expect(adjusted.month, 9);
      expect(adjusted.day, 1);
    });
  });
}
