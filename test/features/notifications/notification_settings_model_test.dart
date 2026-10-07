// test/features/notifications/notification_settings_model_test.dart
//
// Phase 5 — NotificationSettings & PrayerNotificationConfig model tests.
// Pure-Dart unit tests; no platform channels required.

import 'package:flutter_test/flutter_test.dart';

import 'package:mihrab/domain/enums/prayer_type.dart';
import 'package:mihrab/domain/models/notification_settings_model.dart';

void main() {
  // ── PrayerNotificationConfig ─────────────────────────────────────────────

  group('PrayerNotificationConfig', () {
    test('N01: default constructor sets expected defaults', () {
      const cfg = PrayerNotificationConfig();
      expect(cfg.enabled, isTrue);
      expect(cfg.adhanEnabled, isFalse);
      expect(cfg.reminderOffsetMinutes, equals(0));
    });

    test('N02: copyWith overrides individual fields', () {
      const original = PrayerNotificationConfig();
      final modified = original.copyWith(
        enabled: false,
        adhanEnabled: true,
        reminderOffsetMinutes: 10,
      );
      expect(modified.enabled, isFalse);
      expect(modified.adhanEnabled, isTrue);
      expect(modified.reminderOffsetMinutes, equals(10));
    });

    test('N03: copyWith with no arguments returns equal object', () {
      const cfg = PrayerNotificationConfig(
        enabled: false,
        adhanEnabled: true,
        reminderOffsetMinutes: 5,
      );
      final copy = cfg.copyWith();
      expect(copy.enabled, equals(cfg.enabled));
      expect(copy.adhanEnabled, equals(cfg.adhanEnabled));
      expect(copy.reminderOffsetMinutes, equals(cfg.reminderOffsetMinutes));
    });

    test('N04: toJson / fromJson round-trips losslessly', () {
      const cfg = PrayerNotificationConfig(
        enabled: false,
        adhanEnabled: true,
        reminderOffsetMinutes: 15,
      );
      final map = cfg.toJson();
      final restored = PrayerNotificationConfig.fromJson(map);
      expect(restored.enabled, equals(cfg.enabled));
      expect(restored.adhanEnabled, equals(cfg.adhanEnabled));
      expect(restored.reminderOffsetMinutes, equals(cfg.reminderOffsetMinutes));
    });

    test('N05: fromJson with missing fields uses defaults', () {
      final restored = PrayerNotificationConfig.fromJson(const {});
      expect(restored.enabled, isTrue);
      expect(restored.adhanEnabled, isFalse);
      expect(restored.reminderOffsetMinutes, equals(0));
    });

    test('N06: toJson produces expected map keys', () {
      const cfg = PrayerNotificationConfig(
        enabled: true,
        adhanEnabled: false,
        reminderOffsetMinutes: 3,
      );
      final map = cfg.toJson();
      expect(map.containsKey('enabled'), isTrue);
      expect(map.containsKey('adhanEnabled'), isTrue);
      expect(map.containsKey('reminderOffsetMinutes'), isTrue);
    });
  });

  // ── NotificationSettings ─────────────────────────────────────────────────

  group('NotificationSettings', () {
    test('N07: defaults factory creates settings for all 6 prayer types', () {
      final settings = NotificationSettings.defaults();
      for (final type in PrayerType.values) {
        expect(settings.prayerConfigs.containsKey(type), isTrue,
            reason: '$type should have a config entry');
      }
    });

    test('N08: masterEnabled defaults to true', () {
      final settings = NotificationSettings.defaults();
      expect(settings.masterEnabled, isTrue);
    });

    test('N09: effectiveEnabledPrayers excludes Sunrise', () {
      final settings = NotificationSettings.defaults();
      final effective = settings.effectiveEnabledPrayers;
      expect(effective, isNot(contains(PrayerType.sunrise)),
          reason: 'Sunrise must never be in effective enabled prayers');
    });

    test('N10: effectiveEnabledPrayers is empty when masterEnabled=false', () {
      final settings =
          NotificationSettings.defaults().copyWith(masterEnabled: false);
      final effective = settings.effectiveEnabledPrayers;
      expect(effective, isEmpty,
          reason: 'No prayers notified when master switch is off');
    });

    test('N11: effectiveEnabledPrayers excludes prayers with enabled=false', () {
      final base = NotificationSettings.defaults();
      final disabledFajrConfig =
          base.prayerConfigs[PrayerType.fajr]!.copyWith(enabled: false);
      final settings = base.withPrayerConfig(PrayerType.fajr, disabledFajrConfig);
      expect(settings.effectiveEnabledPrayers, isNot(contains(PrayerType.fajr)));
    });

    test('N12: effectiveEnabledPrayers contains all 5 obligatory prayers by default', () {
      final settings = NotificationSettings.defaults();
      final effective = settings.effectiveEnabledPrayers;
      expect(effective, containsAll([
        PrayerType.fajr,
        PrayerType.dhuhr,
        PrayerType.asr,
        PrayerType.maghrib,
        PrayerType.isha,
      ]));
      expect(effective.length, equals(5));
    });

    test('N13: toJson / fromJson round-trips masterEnabled correctly', () {
      final settings =
          NotificationSettings.defaults().copyWith(masterEnabled: false);
      final map = settings.toJson();
      final restored = NotificationSettings.fromJson(map);
      expect(restored.masterEnabled, isFalse);
    });

    test('N14: toJson / fromJson round-trips all prayer configs', () {
      final base = NotificationSettings.defaults();
      final modified = base.withPrayerConfig(
        PrayerType.isha,
        const PrayerNotificationConfig(
          enabled: false,
          adhanEnabled: true,
          reminderOffsetMinutes: 10,
        ),
      );
      final map = modified.toJson();
      final restored = NotificationSettings.fromJson(map);
      final ishaConfig = restored.prayerConfigs[PrayerType.isha]!;
      expect(ishaConfig.enabled, isFalse);
      expect(ishaConfig.adhanEnabled, isTrue);
      expect(ishaConfig.reminderOffsetMinutes, equals(10));
    });

    test('N15: fromJson with empty map returns default-like settings', () {
      final restored = NotificationSettings.fromJson(const {});
      expect(restored.masterEnabled, isTrue);
      expect(restored.effectiveEnabledPrayers, isNot(contains(PrayerType.sunrise)));
    });

    test('N16: copyWith does not mutate original', () {
      final original = NotificationSettings.defaults();
      final modified = original.copyWith(masterEnabled: false);
      expect(original.masterEnabled, isTrue,
          reason: 'Original should be unchanged after copyWith');
      expect(modified.masterEnabled, isFalse);
    });

    test('N17: Sunrise config exists but is never in effectiveEnabledPrayers', () {
      // Even if sunrise enabled=true, effectiveEnabledPrayers filters it out
      // because isObligatory=false.
      final base = NotificationSettings.defaults();
      final sunriseEnabled =
          base.prayerConfigs[PrayerType.sunrise]!.copyWith(enabled: true);
      final settings = base.withPrayerConfig(PrayerType.sunrise, sunriseEnabled);
      expect(settings.effectiveEnabledPrayers, isNot(contains(PrayerType.sunrise)),
          reason:
              'Sunrise must never be in effectiveEnabledPrayers regardless of config');
    });

    test('N18: reminderOffsetMinutes of 0 means fire exactly at prayer time', () {
      const cfg = PrayerNotificationConfig(reminderOffsetMinutes: 0);
      expect(cfg.reminderOffsetMinutes, equals(0));
    });

    test('N19: withPrayerConfig updates single prayer without affecting others', () {
      final base = NotificationSettings.defaults();
      final updated = base.withPrayerConfig(
        PrayerType.fajr,
        const PrayerNotificationConfig(enabled: false),
      );
      expect(updated.prayerConfigs[PrayerType.dhuhr]!.enabled,
          equals(base.prayerConfigs[PrayerType.dhuhr]!.enabled));
      expect(updated.prayerConfigs[PrayerType.fajr]!.enabled, isFalse);
    });

    test('N20: settings JSON contains expected top-level keys', () {
      final settings = NotificationSettings.defaults();
      final map = settings.toJson();
      expect(map.containsKey('masterEnabled'), isTrue);
      expect(map.containsKey('prayerConfigs'), isTrue);
    });
  });

  // ── PrayerType.isObligatory ──────────────────────────────────────────────

  group('PrayerType.isObligatory', () {
    test('N21: Fajr, Dhuhr, Asr, Maghrib, Isha are obligatory', () {
      for (final prayer in [
        PrayerType.fajr,
        PrayerType.dhuhr,
        PrayerType.asr,
        PrayerType.maghrib,
        PrayerType.isha,
      ]) {
        expect(prayer.isObligatory, isTrue,
            reason: '$prayer should be obligatory');
      }
    });

    test('N22: Sunrise is NOT obligatory', () {
      expect(PrayerType.sunrise.isObligatory, isFalse,
          reason: 'Sunrise must never be obligatory');
    });

    test('N23: exactly 5 obligatory prayers exist', () {
      final obligatory = PrayerType.values.where((p) => p.isObligatory);
      expect(obligatory.length, equals(5));
    });

    test('N24: non-obligatory prayer count is exactly 1 (Sunrise)', () {
      final nonObligatory = PrayerType.values.where((p) => !p.isObligatory);
      expect(nonObligatory.length, equals(1));
      expect(nonObligatory.first, equals(PrayerType.sunrise));
    });
  });

  // ── JSON edge cases ──────────────────────────────────────────────────────

  group('JSON edge cases', () {
    test('N25: PrayerNotificationConfig handles extra keys gracefully', () {
      final map = <String, dynamic>{
        'enabled': true,
        'adhanEnabled': false,
        'reminderOffsetMinutes': 5,
        'unknownKey': 'value',
      };
      expect(() => PrayerNotificationConfig.fromJson(map), returnsNormally);
    });

    test('N26: NotificationSettings fromJson with partial prayerConfigs fills defaults', () {
      final partial = <String, dynamic>{
        'masterEnabled': true,
        'prayerConfigs': <String, dynamic>{
          'fajr': <String, dynamic>{
            'enabled': false,
            'adhanEnabled': false,
            'reminderOffsetMinutes': 0,
          },
        },
      };
      final settings = NotificationSettings.fromJson(partial);
      expect(settings.prayerConfigs.containsKey(PrayerType.dhuhr), isTrue);
      expect(settings.prayerConfigs[PrayerType.fajr]!.enabled, isFalse);
    });
  });
}
