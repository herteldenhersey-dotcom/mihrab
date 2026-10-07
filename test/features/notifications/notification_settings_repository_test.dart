// test/features/notifications/notification_settings_repository_test.dart
//
// Phase 5 — SharedPrefsNotificationSettingsRepository integration tests.
// Uses SharedPreferences.setMockInitialValues to avoid platform channels.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mihrab/data/datasources/local/shared_prefs_settings.dart';
import 'package:mihrab/data/repositories/shared_prefs_notification_settings_repository.dart';
import 'package:mihrab/domain/enums/prayer_type.dart';
import 'package:mihrab/domain/models/notification_settings_model.dart';

/// Creates a fresh [SharedPrefsNotificationSettingsRepository] backed by an
/// empty in-memory SharedPreferences store.
Future<SharedPrefsNotificationSettingsRepository> _freshRepo() async {
  final prefs = await SharedPreferences.getInstance();
  return SharedPrefsNotificationSettingsRepository(SharedPrefsSettings(prefs));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── load with no prior data ───────────────────────────────────────────────

  group('load — no prior data', () {
    test('R01: load returns defaults when nothing is persisted', () async {
      final repo = await _freshRepo();
      final settings = await repo.load();
      expect(settings.masterEnabled, isTrue);
      expect(settings.effectiveEnabledPrayers, isNot(contains(PrayerType.sunrise)));
    });

    test('R02: defaults contain all 6 prayer type configs', () async {
      final repo = await _freshRepo();
      final settings = await repo.load();
      for (final type in PrayerType.values) {
        expect(settings.prayerConfigs.containsKey(type), isTrue,
            reason: '$type should have a default config');
      }
    });
  });

  // ── save then load ────────────────────────────────────────────────────────

  group('save then load', () {
    test('R03: masterEnabled=false survives round-trip', () async {
      final repo = await _freshRepo();
      final toSave = NotificationSettings.defaults().copyWith(masterEnabled: false);
      await repo.save(toSave);
      final loaded = await repo.load();
      expect(loaded.masterEnabled, isFalse);
    });

    test('R04: per-prayer enabled=false survives round-trip', () async {
      final repo = await _freshRepo();
      final base = NotificationSettings.defaults();
      final modified = base.withPrayerConfig(
        PrayerType.fajr,
        const PrayerNotificationConfig(enabled: false),
      );
      await repo.save(modified);
      final loaded = await repo.load();
      expect(loaded.prayerConfigs[PrayerType.fajr]!.enabled, isFalse);
    });

    test('R05: adhanEnabled=true survives round-trip', () async {
      final repo = await _freshRepo();
      final base = NotificationSettings.defaults();
      final modified = base.withPrayerConfig(
        PrayerType.maghrib,
        const PrayerNotificationConfig(adhanEnabled: true),
      );
      await repo.save(modified);
      final loaded = await repo.load();
      expect(loaded.prayerConfigs[PrayerType.maghrib]!.adhanEnabled, isTrue);
    });

    test('R06: reminderOffsetMinutes=15 survives round-trip', () async {
      final repo = await _freshRepo();
      final base = NotificationSettings.defaults();
      final modified = base.withPrayerConfig(
        PrayerType.isha,
        const PrayerNotificationConfig(reminderOffsetMinutes: 15),
      );
      await repo.save(modified);
      final loaded = await repo.load();
      expect(loaded.prayerConfigs[PrayerType.isha]!.reminderOffsetMinutes, equals(15));
    });

    test('R07: all 5 obligatory prayers preserved after full round-trip', () async {
      final repo = await _freshRepo();
      final settings = NotificationSettings.defaults();
      await repo.save(settings);
      final loaded = await repo.load();
      expect(loaded.effectiveEnabledPrayers, containsAll([
        PrayerType.fajr,
        PrayerType.dhuhr,
        PrayerType.asr,
        PrayerType.maghrib,
        PrayerType.isha,
      ]));
    });

    test('R08: sunrise is not in effectiveEnabledPrayers after round-trip', () async {
      final repo = await _freshRepo();
      await repo.save(NotificationSettings.defaults());
      final loaded = await repo.load();
      expect(loaded.effectiveEnabledPrayers, isNot(contains(PrayerType.sunrise)));
    });
  });

  // ── overwrite ─────────────────────────────────────────────────────────────

  group('overwrite', () {
    test('R09: second save overwrites first', () async {
      final repo = await _freshRepo();
      final first = NotificationSettings.defaults().copyWith(masterEnabled: true);
      final second = NotificationSettings.defaults().copyWith(masterEnabled: false);
      await repo.save(first);
      await repo.save(second);
      final loaded = await repo.load();
      expect(loaded.masterEnabled, isFalse,
          reason: 'Second save should have overwritten the first');
    });

    test('R10: save multiple configs then load returns last saved config', () async {
      final repo = await _freshRepo();
      final base = NotificationSettings.defaults();
      // Save Fajr disabled.
      await repo.save(base.withPrayerConfig(
        PrayerType.fajr,
        const PrayerNotificationConfig(enabled: false),
      ));
      // Overwrite with Fajr enabled, Isha disabled.
      final final_ = base.withPrayerConfig(
        PrayerType.isha,
        const PrayerNotificationConfig(enabled: false),
      );
      await repo.save(final_);
      final loaded = await repo.load();
      // Fajr should be enabled again (last write had Fajr=default=true).
      expect(loaded.prayerConfigs[PrayerType.fajr]!.enabled, isTrue);
      // Isha should be disabled.
      expect(loaded.prayerConfigs[PrayerType.isha]!.enabled, isFalse);
    });
  });

  // ── corrupted data recovery ───────────────────────────────────────────────

  group('corrupted data recovery', () {
    test('R11: load returns defaults when stored JSON is invalid', () async {
      // Pre-seed with invalid JSON.
      SharedPreferences.setMockInitialValues({
        'notification_settings': 'this is not valid json {{',
      });
      final repo = await _freshRepo();
      final settings = await repo.load();
      // Should return defaults without throwing.
      expect(settings.masterEnabled, isTrue);
      expect(settings.effectiveEnabledPrayers.length, equals(5));
    });
  });
}
