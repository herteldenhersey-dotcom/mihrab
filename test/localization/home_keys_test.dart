import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards Phase 4 Home screen translation keys (spec §33/38).
///
/// Verifies that every new Phase 4 key introduced for the Home screen is:
/// 1. Present in all three locales (TR / EN / AR).
/// 2. Non-blank.
/// 3. Arabic values contain Arabic-script characters (not English placeholders).
///
/// Full key-set parity across all existing keys is already covered by
/// [test/localization/arb_keys_test.dart].  This file is a targeted smoke-test
/// for the Phase 4 additions only — making the failure message more specific
/// when a Home key is forgotten.
void main() {
  const arbDir = 'lib/localization/l10n';
  const locales = ['tr', 'en', 'ar'];

  Map<String, dynamic> readArb(String locale) {
    final file = File('$arbDir/app_$locale.arb');
    expect(file.existsSync(), isTrue,
        reason: 'ARB file missing for $locale at ${file.path}');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  /// Phase 4 Home keys introduced in this phase.
  const phase4HomeKeys = [
    'homeToday',
    'homeTomorrow',
    'homePrayerTimes',
    'homeNextPrayer',
    'homeTimeRemaining',
    'homeGregorianDate',
    'homeHijriDate',
    'homeLocation',
    'homeChangeLocation',
    'homeRefresh',
    'homeLastUpdated',
    'homeLoading',
    'homeErrorPrayerCalc',
    'homeErrorTimezone',
    'homeErrorMissingLocation',
    'homeSetLocation',
    'homeComingSoon',
    'homeQibla',
    'homeNearbyMosques',
    'homeRamadan',
    'homeSunriseLabel',
    'homeSunriseNote',
    'homeRetry',
    'homeNextPrayerIn',
    'homePrayerFajr',
    'homePrayerSunrise',
    'homePrayerDhuhr',
    'homePrayerAsr',
    'homePrayerMaghrib',
    'homePrayerIsha',
    'homeSettings',
    'homeTimezoneUsed',
  ];

  test('all Phase 4 Home keys are present in every locale', () {
    for (final locale in locales) {
      final arb = readArb(locale);
      for (final key in phase4HomeKeys) {
        expect(arb.containsKey(key), isTrue,
            reason: 'Phase 4 key "$key" is missing from $locale ARB');
      }
    }
  });

  test('no Phase 4 Home key is blank in any locale', () {
    for (final locale in locales) {
      final arb = readArb(locale);
      for (final key in phase4HomeKeys) {
        final value = arb[key];
        expect(value, isA<String>(),
            reason: '$locale/$key must be a String');
        expect((value as String).trim(), isNotEmpty,
            reason: '$locale/$key is blank');
      }
    }
  });

  test('Arabic Phase 4 Home keys contain Arabic-script characters', () {
    final ar = readArb('ar');
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    // A representative subset of prose keys that must be in Arabic.
    const arabicProseKeys = [
      'homeNextPrayer',
      'homeErrorMissingLocation',
      'homeSetLocation',
      'homeComingSoon',
    ];
    for (final key in arabicProseKeys) {
      final value = ar[key] as String?;
      expect(value, isNotNull, reason: 'ar/$key is missing');
      expect(arabicRegex.hasMatch(value!), isTrue,
          reason:
              'ar/$key does not contain Arabic script: "$value" — '
              'is this an English placeholder?');
    }
  });

  test('Phase 4 key count in TR matches EN and AR', () {
    final trArb = readArb('tr');
    final enArb = readArb('en');
    final arArb = readArb('ar');

    Set<String> msgKeys(Map<String, dynamic> arb) =>
        arb.keys.where((k) => !k.startsWith('@')).toSet();

    final tr = msgKeys(trArb);
    final en = msgKeys(enArb);
    final ar = msgKeys(arArb);

    expect(tr.length, en.length,
        reason: 'TR and EN have different number of keys');
    expect(tr.length, ar.length,
        reason: 'TR and AR have different number of keys');
  });
}
