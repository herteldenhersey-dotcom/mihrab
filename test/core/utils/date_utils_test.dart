import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/core/utils/date_utils.dart';

void main() {
  group('startOfDay / endOfDay', () {
    test('startOfDay is midnight', () {
      final d = DateTime(2024, 3, 15, 14, 37, 22);
      expect(AppDateUtils.startOfDay(d), DateTime(2024, 3, 15));
    });

    test('endOfDay is 23:59:59.999', () {
      final d = DateTime(2024, 3, 15, 1, 2, 3);
      expect(AppDateUtils.endOfDay(d), DateTime(2024, 3, 15, 23, 59, 59, 999));
    });
  });

  group('isSameDay', () {
    test('same calendar day, different times', () {
      expect(
        AppDateUtils.isSameDay(
            DateTime(2024, 3, 15, 1), DateTime(2024, 3, 15, 23)),
        isTrue,
      );
    });
    test('different day', () {
      expect(
        AppDateUtils.isSameDay(DateTime(2024, 3, 15), DateTime(2024, 3, 16)),
        isFalse,
      );
    });
  });

  group('Hijri conversion (Kuwaiti algorithm, ±1 day)', () {
    test('2024-03-11 falls in Ramadan 1445', () {
      // Ramadan 1445 began ~2024-03-11.
      final h = AppDateUtils.toHijri(DateTime(2024, 3, 15));
      expect(h.month, 9); // Ramadan
      expect(h.year, 1445);
    });

    test('isRamadan true inside Ramadan', () {
      expect(AppDateUtils.isRamadan(DateTime(2024, 3, 15)), isTrue);
    });

    test('isRamadan false outside Ramadan', () {
      expect(AppDateUtils.isRamadan(DateTime(2024, 1, 1)), isFalse);
    });

    test('formatHijriTr yields a non-empty Turkish month name', () {
      final s = AppDateUtils.formatHijriTr(DateTime(2024, 3, 15));
      expect(s.contains('Ramazan'), isTrue);
      expect(s.contains('1445'), isTrue);
    });
  });
}
