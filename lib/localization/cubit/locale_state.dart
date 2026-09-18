part of 'locale_cubit.dart';

/// State for [LocaleCubit].
class LocaleState extends Equatable {
  /// The active language.
  final LanguageCode language;

  /// Whether the current [language] came from an explicit, persisted user
  /// choice (`true`) or was auto-detected from the device on a fresh install
  /// (`false`).
  final bool persisted;

  const LocaleState({required this.language, required this.persisted});

  /// Pre-load default (Turkish LTR) until [LocaleCubit.load] resolves. Kept
  /// deterministic so widget tests have a stable starting point.
  const LocaleState.initial()
      : language = LanguageCode.tr,
        persisted = false;

  const LocaleState.loaded(this.language, {required this.persisted});

  /// The [Locale] to hand to `MaterialApp.locale`.
  Locale get locale => language.locale;

  /// Whether the active language is right-to-left (Arabic).
  bool get isRtl => language.isRtl;

  @override
  List<Object?> get props => [language, persisted];
}
