import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/models/location_model.dart';
import 'package:mihrab/features/onboarding/presentation/cubit/onboarding_cubit.dart';

import '../../helpers/fake_settings_repository.dart';

/// Verifies the onboarding shell tracks the resolved location and persists a
/// valid one on completion (so a fresh install is not re-onboarded).
void main() {
  late FakeSettingsRepository settings;

  setUp(() => settings = FakeSettingsRepository());

  const istanbul = AppLocation(
    latitude: 41.0082,
    longitude: 28.9784,
    city: 'İstanbul',
    country: 'Türkiye',
    isManual: true,
  );

  test('setLocation records the location in state', () async {
    final cubit = OnboardingCubit(settings);
    cubit.setLocation(istanbul);
    expect(cubit.state.location, istanbul);
    await cubit.close();
  });

  test('setLocation(null) clears the location', () async {
    final cubit = OnboardingCubit(settings);
    cubit.setLocation(istanbul);
    cubit.setLocation(null);
    expect(cubit.state.location, isNull);
    await cubit.close();
  });

  test('complete persists a valid location and marks onboarding done',
      () async {
    final cubit = OnboardingCubit(settings);
    cubit.setLocation(istanbul);

    await cubit.complete();

    expect(cubit.state.completed, isTrue);
    expect(await settings.getSavedLocation(), istanbul);
    expect(await settings.getOnboardingComplete(), isTrue);
    await cubit.close();
  });

  test('complete does not persist an invalid location', () async {
    final cubit = OnboardingCubit(settings);
    cubit.setLocation(const AppLocation(latitude: double.nan, longitude: 0));

    await cubit.complete();

    // Onboarding still completes, but the malformed coordinate is not stored.
    expect(cubit.state.completed, isTrue);
    expect(await settings.getSavedLocation(), isNull);
    await cubit.close();
  });
}
