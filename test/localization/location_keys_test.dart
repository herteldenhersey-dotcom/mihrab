import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Focused regression guard for the Phase 3 location strings: every new
/// location key must exist and be non-blank in all three locales, and the
/// Arabic values must actually be in Arabic script (not English placeholders).
/// The broader parity check lives in arb_keys_test.dart.
void main() {
  const arbDir = 'lib/localization/l10n';
  const locales = ['tr', 'en', 'ar'];

  // The keys added for the location onboarding step.
  const locationKeys = [
    'locationSetupTitle',
    'locationSetupSubtitle',
    'locationUseMyLocation',
    'locationSelectManually',
    'locationRationaleTitle',
    'locationRationaleBody',
    'locationSearching',
    'locationFound',
    'locationServicesDisabledTitle',
    'locationServicesDisabledBody',
    'locationPermissionDeniedTitle',
    'locationPermissionDeniedBody',
    'locationPermissionPermanentlyDeniedTitle',
    'locationPermissionPermanentlyDeniedBody',
    'locationTimeoutBody',
    'locationErrorBody',
    'openAppSettings',
    'openLocationSettings',
    'locationManualTitle',
    'locationSearchHint',
    'locationSearch',
    'locationCountry',
    'locationCity',
    'locationDistrict',
    'locationNoResults',
    'tryAgain',
    'locationConfirm',
    'locationChange',
    'locationAddressUnavailable',
    'locationUsingCoordinates',
  ];

  Map<String, dynamic> readArb(String locale) =>
      jsonDecode(File('$arbDir/app_$locale.arb').readAsStringSync())
          as Map<String, dynamic>;

  test('all location keys exist and are non-blank in every locale', () {
    for (final locale in locales) {
      final arb = readArb(locale);
      for (final key in locationKeys) {
        expect(arb.containsKey(key), isTrue,
            reason: '$locale is missing "$key"');
        expect((arb[key] as String).trim(), isNotEmpty,
            reason: '$locale/$key is blank');
      }
    }
  });

  test('Arabic location values are in Arabic script', () {
    final ar = readArb('ar');
    final arabic = RegExp(r'[\u0600-\u06FF]');
    for (final key in locationKeys) {
      final value = ar[key] as String;
      expect(arabic.hasMatch(value), isTrue,
          reason: 'ar/$key is not Arabic script: "$value"');
    }
  });
}
