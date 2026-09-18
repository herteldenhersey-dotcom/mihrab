import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/data/datasources/local/shared_prefs_settings.dart';
import 'package:mihrab/data/repositories/hive_settings_repository.dart';
import 'package:mihrab/domain/models/location_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Location persistence via the real [HiveSettingsRepository] backed by a mocked
/// SharedPreferences store (no platform channel). Verifies that a confirmed
/// location survives a simulated app restart and that onboarding completion is
/// remembered so the user is not re-onboarded.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HiveSettingsRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<HiveSettingsRepository> freshRepo() async {
    final prefs = await SharedPreferences.getInstance();
    return HiveSettingsRepository(SharedPrefsSettings(prefs));
  }

  const manual = AppLocation(
    latitude: 52.52,
    longitude: 13.405,
    city: 'Berlin',
    district: 'Mitte',
    country: 'Germany',
    isManual: true,
  );

  test('saveLocation → getSavedLocation round-trips every field', () async {
    repo = await freshRepo();
    await repo.saveLocation(manual);

    final saved = await repo.getSavedLocation();
    expect(saved, manual);
    expect(saved!.isManual, isTrue);
    expect(saved.district, 'Mitte');
  });

  test('location survives a simulated restart (new repo instance)', () async {
    repo = await freshRepo();
    await repo.saveLocation(manual);

    // Simulate relaunch: brand new repository reading the same store.
    final afterRestart = await freshRepo();
    final restored = await afterRestart.getSavedLocation();
    expect(restored, manual);
  });

  test('getSavedLocation is null on a fresh install', () async {
    repo = await freshRepo();
    expect(await repo.getSavedLocation(), isNull);
  });

  test('onboarding completion persists across restart', () async {
    repo = await freshRepo();
    expect(await repo.getOnboardingComplete(), isFalse);

    await repo.saveOnboardingComplete(true);

    final afterRestart = await freshRepo();
    expect(await afterRestart.getOnboardingComplete(), isTrue);
  });

  test('a GPS (non-manual) location persists with isManual=false', () async {
    repo = await freshRepo();
    const gps = AppLocation(latitude: 41.0082, longitude: 28.9784);
    await repo.saveLocation(gps);

    final restored = await (await freshRepo()).getSavedLocation();
    expect(restored!.isManual, isFalse);
    expect(restored.latitude, 41.0082);
  });
}
