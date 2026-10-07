// test/features/ramadan/localization_test.dart
//
// Phase 6 — Ramadan localization key guards (R49–R52).
// Ensures every Ramadan key is present, non-blank in TR/EN/AR, and that the
// Arabic prose is actually Arabic script.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const arbDir = 'lib/localization/l10n';
  const locales = ['tr', 'en', 'ar'];

  Map<String, dynamic> readArb(String locale) {
    final file = File('$arbDir/app_$locale.arb');
    expect(file.existsSync(), isTrue,
        reason: 'ARB file missing for $locale at ${file.path}');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  const ramadanKeys = [
    'ramadanDayLabel',
    'ramadanDayCounter',
    'imsakLabel',
    'sahurLabel',
    'iftarLabel',
    'timeRemaining',
    'tomorrowImsak',
    'reminderEnabled',
    'reminderDisabled',
    'sahurReminderOffset',
    'iftarReminderOffset',
    'hijriAdjustment',
    'estimatedRamadanDates',
    'officialDateDisclaimer',
    'countdownLabel',
    'dayCounterLabel',
    'hijriDateLabel',
    'ramadanSettingsTitle',
    'ramadanCardVisibility',
    'ramadanUntilImsak',
    'ramadanUntilIftar',
    'ramadanNextRamadan',
    'ramadanEstimateLabel',
    'ramadanSahurReminder',
    'ramadanIftarReminder',
    'ramadanAtIftar',
    'ramadanMinutesBefore',
    'ramadanTotalDays',
    'ramadanNotActiveMessage',
    'ramadanReminderStatus',
  ];

  test('R49: every Ramadan key is present in all three locales', () {
    for (final locale in locales) {
      final arb = readArb(locale);
      for (final key in ramadanKeys) {
        expect(arb.containsKey(key), isTrue,
            reason: 'Ramadan key "$key" missing from $locale ARB');
      }
    }
  });

  test('R50: no Ramadan key is blank in any locale', () {
    for (final locale in locales) {
      final arb = readArb(locale);
      for (final key in ramadanKeys) {
        final value = arb[key];
        expect(value, isA<String>(), reason: '$locale/$key must be a String');
        expect((value as String).trim(), isNotEmpty,
            reason: '$locale/$key is blank');
      }
    }
  });

  test('R51: Arabic Ramadan prose contains Arabic-script characters', () {
    final ar = readArb('ar');
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    const arabicProseKeys = [
      'ramadanNextRamadan',
      'ramadanNotActiveMessage',
      'officialDateDisclaimer',
      'ramadanSahurReminder',
      'ramadanIftarReminder',
    ];
    for (final key in arabicProseKeys) {
      final value = ar[key] as String?;
      expect(value, isNotNull, reason: 'ar/$key is missing');
      expect(arabicRegex.hasMatch(value!), isTrue,
          reason: 'ar/$key is not Arabic script: "$value"');
    }
  });

  test('R52: TR/EN/AR have identical key-set cardinality', () {
    Set<String> msgKeys(Map<String, dynamic> arb) =>
        arb.keys.where((k) => !k.startsWith('@')).toSet();
    final tr = msgKeys(readArb('tr'));
    final en = msgKeys(readArb('en'));
    final ar = msgKeys(readArb('ar'));
    expect(tr.length, en.length);
    expect(tr.length, ar.length);
    // And the Ramadan keys specifically are in the shared set.
    for (final key in ramadanKeys) {
      expect(tr.contains(key) && en.contains(key) && ar.contains(key), isTrue,
          reason: 'Ramadan key "$key" not shared across all locales');
    }
  });
}
