import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/enums/language_code.dart';
import '../../../../domain/enums/prayer_calculation_method.dart';
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
    await _settings.saveOnboardingComplete(true);
    emit(state.copyWith(completed: true));
  }
}
