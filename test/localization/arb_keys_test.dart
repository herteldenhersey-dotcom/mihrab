import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the translation catalogue: every locale must define the same message
/// keys, and no value may be blank. This catches a missing/empty translation
/// long before it reaches a user-facing screen. Runs directly on the ARB source
/// files (the single source of truth for gen-l10n).
void main() {
  const arbDir = 'lib/localization/l10n';
  const locales = ['tr', 'en', 'ar'];

  Map<String, dynamic> readArb(String locale) {
    final file = File('$arbDir/app_$locale.arb');
    expect(file.existsSync(), isTrue,
        reason: 'Missing ARB file for "$locale" at ${file.path}');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  // Message keys only — drop @@locale and @-prefixed metadata entries.
  Set<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  test('all locales exist and are valid JSON', () {
    for (final locale in locales) {
      final arb = readArb(locale);
      expect(arb, isNotEmpty, reason: '$locale ARB is empty');
    }
  });

  test('all locales define identical message-key sets', () {
    final reference = messageKeys(readArb('en'));
    expect(reference, isNotEmpty);

    for (final locale in locales) {
      final keys = messageKeys(readArb(locale));
      final missing = reference.difference(keys);
      final extra = keys.difference(reference);
      expect(missing, isEmpty,
          reason: '$locale is missing keys present in en: $missing');
      expect(extra, isEmpty,
          reason: '$locale has keys absent from en: $extra');
    }
  });

  test('no message value is blank in any locale', () {
    for (final locale in locales) {
      final arb = readArb(locale);
      for (final key in messageKeys(arb)) {
        final value = arb[key];
        expect(value, isA<String>(),
            reason: '$locale/$key should be a string');
        expect((value as String).trim(), isNotEmpty,
            reason: '$locale/$key is blank');
      }
    }
  });

  test('critical UI keys are present in every locale', () {
    // A representative slice of keys the app cannot render without.
    const critical = [
      'appName',
      'onboardingLanguageTitle',
      'onboardingLanguageSubtitle',
    ];
    for (final locale in locales) {
      final keys = messageKeys(readArb(locale));
      for (final key in critical) {
        expect(keys, contains(key),
            reason: 'Critical key "$key" missing from $locale');
      }
    }
  });

  test('Arabic values contain Arabic-script characters (real translation)', () {
    // Guards against an ar ARB accidentally left as English placeholders.
    final ar = readArb('ar');
    final arabic = RegExp(r'[\u0600-\u06FF]');
    // appTitle can legitimately be a brand transliteration, so sample a few
    // genuinely translated, prose keys instead.
    const sampleKeys = ['onboardingLanguageTitle', 'onboardingLanguageSubtitle'];
    for (final key in sampleKeys) {
      final value = ar[key] as String?;
      expect(value, isNotNull, reason: 'ar/$key missing');
      expect(arabic.hasMatch(value!), isTrue,
          reason: 'ar/$key does not contain Arabic script: "$value"');
    }
  });
}
