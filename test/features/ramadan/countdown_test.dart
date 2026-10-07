// test/features/ramadan/countdown_test.dart
//
// Phase 6 — RamadanCountdownService unit tests (R12–R18).

import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/features/ramadan/presentation/cubit/ramadan_countdown_service.dart';

void main() {
  const svc = RamadanCountdownService();

  final imsak = DateTime(2025, 3, 10, 5, 0);
  final iftar = DateTime(2025, 3, 10, 18, 30);
  final tomorrowImsak = DateTime(2025, 3, 11, 5, 0);

  test('R12: before Imsak → beforeImsak phase, counts down to Imsak', () {
    final c = svc.compute(
      now: DateTime(2025, 3, 10, 3, 0),
      imsak: imsak,
      iftar: iftar,
      tomorrowImsak: tomorrowImsak,
    );
    expect(c.phase, RamadanCountdownPhase.beforeImsak);
    expect(c.target, imsak);
    expect(c.remaining, const Duration(hours: 2));
  });

  test('R13: between Imsak and Iftar → fasting phase, counts down to Iftar', () {
    final c = svc.compute(
      now: DateTime(2025, 3, 10, 12, 30),
      imsak: imsak,
      iftar: iftar,
      tomorrowImsak: tomorrowImsak,
    );
    expect(c.phase, RamadanCountdownPhase.fasting);
    expect(c.target, iftar);
    expect(c.remaining, const Duration(hours: 6));
  });

  test('R14: after Iftar → afterIftar phase, counts down to tomorrow Imsak', () {
    final c = svc.compute(
      now: DateTime(2025, 3, 10, 20, 0),
      imsak: imsak,
      iftar: iftar,
      tomorrowImsak: tomorrowImsak,
    );
    expect(c.phase, RamadanCountdownPhase.afterIftar);
    expect(c.target, tomorrowImsak);
    expect(c.remaining, const Duration(hours: 9));
  });

  test('R15: exactly at Imsak → fasting phase begins', () {
    final c = svc.compute(
      now: imsak,
      imsak: imsak,
      iftar: iftar,
      tomorrowImsak: tomorrowImsak,
    );
    expect(c.phase, RamadanCountdownPhase.fasting);
  });

  test('R16: remaining duration is never negative', () {
    final c = svc.compute(
      now: DateTime(2025, 3, 11, 4, 59, 59),
      imsak: imsak,
      iftar: iftar,
      tomorrowImsak: tomorrowImsak,
    );
    expect(c.remaining.isNegative, isFalse);
  });

  test('R17: format renders HH:mm:ss with zero-padding', () {
    expect(RamadanCountdownService.format(const Duration(hours: 2, minutes: 5, seconds: 9)),
        '02:05:09');
    expect(RamadanCountdownService.format(const Duration(hours: 13, minutes: 0, seconds: 0)),
        '13:00:00');
  });

  test('R18: format clamps a negative duration to 00:00:00', () {
    expect(RamadanCountdownService.format(const Duration(seconds: -5)),
        '00:00:00');
  });
}
