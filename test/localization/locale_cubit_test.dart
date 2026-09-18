import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/enums/language_code.dart';
import 'package:mihrab/domain/models/calculation_settings_model.dart';
import 'package:mihrab/domain/models/location_model.dart';
import 'package:mihrab/domain/repositories/settings_repository.dart';
import 'package:mihrab/localization/cubit/locale_cubit.dart';

/// Hand-written in-memory fake so the LocaleCubit can be tested without Hive.
/// Only the language-related methods carry behaviour; everything else throws or
/// returns a benign default, keeping the fake honest about what it supports.
class FakeSettingsRepository implements SettingsRepository {
  LanguageCode? _storedLanguage;

  FakeSettingsRepository({LanguageCode? initialLanguage})
      : _storedLanguage = initialLanguage;

  /// Number of times [saveLanguage] was invoked (asserts persistence happened).
  int saveLanguageCalls = 0;

  @override
  Future<LanguageCode?> getStoredLanguage() async => _storedLanguage;

  @override
  Future<LanguageCode> getLanguage() async =>
      _storedLanguage ?? LanguageCode.tr;

  @override
  Future<void> saveLanguage(LanguageCode language) async {
    saveLanguageCalls++;
    _storedLanguage = language;
  }

  // --- Unused by these tests -------------------------------------------------
  @override
  Future<CalculationSettings> getCalculationSettings() =>
      throw UnimplementedError();
  @override
  Future<void> saveCalculationSettings(CalculationSettings settings) =>
      throw UnimplementedError();
  @override
  Future<AppLocation?> getSavedLocation() => throw UnimplementedError();
  @override
  Future<void> saveLocation(AppLocation location) => throw UnimplementedError();
  @override
  Future<bool> getNotificationsEnabled() => throw UnimplementedError();
  @override
  Future<void> saveNotificationsEnabled(bool enabled) =>
      throw UnimplementedError();
  @override
  Future<bool> getOnboardingComplete() => throw UnimplementedError();
  @override
  Future<void> saveOnboardingComplete(bool complete) =>
      throw UnimplementedError();
  @override
  Future<bool> getDarkMode() => throw UnimplementedError();
  @override
  Future<void> saveDarkMode(bool enabled) => throw UnimplementedError();
}

void main() {
  group('LocaleCubit.load — stored language wins', () {
    for (final lang in LanguageCode.values) {
      test('restores persisted ${lang.code} on launch', () async {
        final settings = FakeSettingsRepository(initialLanguage: lang);
        final cubit = LocaleCubit(
          settings,
          // Device says English, but a stored choice must override it.
          deviceLocaleProvider: () => const Locale('en'),
        );

        await cubit.load();

        expect(cubit.state.language, lang);
        expect(cubit.state.persisted, isTrue);
        expect(cubit.state.locale, lang.locale);
        await cubit.close();
      });
    }
  });

  group('LocaleCubit.load — device-locale detection on fresh install', () {
    test('adopts supported device language (ar) without persisting', () async {
      final settings = FakeSettingsRepository();
      final cubit = LocaleCubit(
        settings,
        deviceLocaleProvider: () => const Locale('ar', 'SA'),
      );

      await cubit.load();

      expect(cubit.state.language, LanguageCode.ar);
      // Auto-detected, not an explicit choice → must NOT be persisted.
      expect(cubit.state.persisted, isFalse);
      expect(settings.saveLanguageCalls, 0);
      expect(cubit.state.isRtl, isTrue);
      await cubit.close();
    });

    test('adopts supported device language (tr)', () async {
      final settings = FakeSettingsRepository();
      final cubit = LocaleCubit(
        settings,
        deviceLocaleProvider: () => const Locale('tr', 'TR'),
      );

      await cubit.load();

      expect(cubit.state.language, LanguageCode.tr);
      expect(cubit.state.persisted, isFalse);
      await cubit.close();
    });

    test('falls back to English for an unsupported device locale', () async {
      final settings = FakeSettingsRepository();
      final cubit = LocaleCubit(
        settings,
        // French is not supported → spec mandates English fallback.
        deviceLocaleProvider: () => const Locale('fr', 'FR'),
      );

      await cubit.load();

      expect(cubit.state.language, LanguageCode.en);
      expect(cubit.state.persisted, isFalse);
      expect(settings.saveLanguageCalls, 0);
      await cubit.close();
    });
  });

  group('LocaleCubit.changeLocale — runtime switching + persistence', () {
    test('switching TR → AR emits RTL and persists', () async {
      final settings = FakeSettingsRepository(initialLanguage: LanguageCode.tr);
      final cubit = LocaleCubit(
        settings,
        deviceLocaleProvider: () => const Locale('tr'),
      );
      await cubit.load();
      expect(cubit.state.language, LanguageCode.tr);
      expect(cubit.state.isRtl, isFalse);

      await cubit.changeLocale(LanguageCode.ar);

      expect(cubit.state.language, LanguageCode.ar);
      expect(cubit.state.persisted, isTrue);
      expect(cubit.state.isRtl, isTrue);
      expect(settings.saveLanguageCalls, 1);
      await cubit.close();
    });

    test('switching AR → EN restores LTR and persists', () async {
      final settings = FakeSettingsRepository(initialLanguage: LanguageCode.ar);
      final cubit = LocaleCubit(
        settings,
        deviceLocaleProvider: () => const Locale('ar'),
      );
      await cubit.load();

      await cubit.changeLocale(LanguageCode.en);

      expect(cubit.state.language, LanguageCode.en);
      expect(cubit.state.isRtl, isFalse);
      expect(settings.saveLanguageCalls, 1);
      await cubit.close();
    });

    test('choice survives a simulated app restart', () async {
      // First run: user explicitly picks Arabic.
      final settings = FakeSettingsRepository();
      final first = LocaleCubit(
        settings,
        deviceLocaleProvider: () => const Locale('en'),
      );
      await first.load();
      await first.changeLocale(LanguageCode.ar);
      await first.close();

      // Second run: a brand-new cubit over the SAME persisted store.
      final second = LocaleCubit(
        settings,
        deviceLocaleProvider: () => const Locale('en'),
      );
      await second.load();

      expect(second.state.language, LanguageCode.ar);
      expect(second.state.persisted, isTrue);
      await second.close();
    });

    test('re-selecting the already-persisted language does not re-save',
        () async {
      final settings = FakeSettingsRepository(initialLanguage: LanguageCode.en);
      final cubit = LocaleCubit(
        settings,
        deviceLocaleProvider: () => const Locale('en'),
      );
      await cubit.load();

      await cubit.changeLocale(LanguageCode.en);

      // load() marked it persisted; a no-op re-selection must not persist again.
      expect(settings.saveLanguageCalls, 0);
      await cubit.close();
    });
  });
}
