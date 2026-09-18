part of 'onboarding_cubit.dart';

/// State for the onboarding flow.
class OnboardingState extends Equatable {
  final int step;
  final LanguageCode language;
  final bool notificationsEnabled;
  final PrayerCalculationMethod method;
  final bool completed;

  const OnboardingState({
    this.step = 0,
    this.language = LanguageCode.tr,
    this.notificationsEnabled = true,
    this.method = PrayerCalculationMethod.diyanet,
    this.completed = false,
  });

  OnboardingState copyWith({
    int? step,
    LanguageCode? language,
    bool? notificationsEnabled,
    PrayerCalculationMethod? method,
    bool? completed,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      method: method ?? this.method,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props =>
      [step, language, notificationsEnabled, method, completed];
}
