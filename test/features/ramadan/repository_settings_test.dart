// test/features/ramadan/repository_settings_test.dart
//
// Phase 6 — RamadanRepositoryImpl + RamadanSettings persistence (R45–R48).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mihrab/data/datasources/local/shared_prefs_settings.dart';
import 'package:mihrab/data/repositories/ramadan_repository_impl.dart';
import 'package:mihrab/data/services/hijri/hijri_calendar_service.dart';
import 'package:mihrab/domain/entities/ramadan_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<RamadanRepositoryImpl> buildRepo() async {
    final prefs = await SharedPreferences.getInstance();
    return RamadanRepositoryImpl(const HijriCalendarService(),
        SharedPrefsSettings(prefs));
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('R45: defaults are returned when nothing is persisted', () async {
    final repo = await buildRepo();
    final s = await repo.loadSettings();
    expect(s, RamadanSettings.defaults);
    expect(s.sahurEnabled, isTrue);
    expect(s.sahurOffsetMinutes, 30);
    expect(s.iftarOffsetMinutes, 15);
  });

  test('R46: saveSettings round-trips through persistence', () async {
    final repo = await buildRepo();
    const custom = RamadanSettings(
      sahurEnabled: false,
      sahurOffsetMinutes: 45,
      iftarEnabled: true,
      iftarOffsetMinutes: 5,
      hijriAdjustment: -2,
      cardVisible: false,
    );
    await repo.saveSettings(custom);

    // New repo instance reads the same persisted value.
    final repo2 = await buildRepo();
    final loaded = await repo2.loadSettings();
    expect(loaded, custom);
  });

  test('R47: getRamadanInfo applies the persisted hijri adjustment', () async {
    final repo = await buildRepo();
    // +1 adjustment makes 10 Mar 2024 behave like 11 Mar (Ramadan day 1).
    await repo.saveSettings(
        RamadanSettings.defaults.copyWith(hijriAdjustment: 1));
    final info = repo.getRamadanInfo(DateTime(2024, 3, 10));
    expect(info.isRamadan, isTrue);
    expect(info.dayNumber, 1);
  });

  test('R48: explicit adjustment arg overrides the persisted one', () async {
    final repo = await buildRepo();
    await repo.saveSettings(
        RamadanSettings.defaults.copyWith(hijriAdjustment: 3));
    final info = repo.getRamadanInfo(DateTime(2024, 3, 15), adjustment: 0);
    expect(info.isRamadan, isTrue);
    expect(info.dayNumber, 5); // unshifted
  });
}
