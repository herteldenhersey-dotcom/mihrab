import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/enums/language_code.dart';
import '../../../../domain/enums/prayer_calculation_method.dart';
import '../../../../domain/models/location_model.dart';
import '../../../../domain/repositories/settings_repository.dart';

part 'onboarding_state.dart';

/// Drives the multi-step onboarding flow and persists the user's initial
/// choices via [SettingsRepository].
class OnboardingCubit extends Cubit<OnboardingState> {
  final SettingsRepository _settings;

  OnboardingCubit(this._settings) : super(const OnboardingState());

  static const int totalSteps = 4;

  void nextStep() {
    if (state.step < totalSteps - 1) {
      emit(state.copyWith(step: state.step + 1));
    }
  }

  void previousStep() {
    if (state.step > 0) {
      emit(state.copyWith(step: state.step - 1));
    }
  }

  Future<void> setLanguage(LanguageCode language) async {
    emit(state.copyWith(language: language));
    await _settings.saveLanguage(language);
  }

  /// Records the location resolved by the location step. The
  /// [LocationOnboardingCubit] already persisted it to storage; this keeps the
  /// shell's Continue gate and the final [complete] in sync. Passing null
  /// (e.g. after "Change location") clears it.
  void setLocation(AppLocation? location) => emit(
        location == null
            ? state.copyWith(clearLocation: true)
            : state.copyWith(location: location),
      );

  void setNotificationsEnabled(bool enabled) =>
      emit(state.copyWith(notificationsEnabled: enabled));

  void setMethod(PrayerCalculationMethod method) =>
      emit(state.copyWith(method: method));

  /// Persists all selections and marks onboarding complete.
  Future<void> complete() async {
    await _settings.saveLanguage(state.language);
    await _settings.saveNotificationsEnabled(state.notificationsEnabled);
    final current = await _settings.getCalculationSettings();
    await _settings
        .saveCalculationSettings(current.copyWith(method: state.method));
    // Re-persist the chosen location (idempotent: the location step already
    // saved it) so a valid coordinate is guaranteed to be stored on completion.
    final location = state.location;
    if (location != null && location.hasValidCoordinates) {
      await _settings.saveLocation(location);
    }
    await _settings.saveOnboardingComplete(true);
    emit(state.copyWith(completed: true));
  }
}
