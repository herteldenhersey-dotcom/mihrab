import 'dart:ui';

/// Languages supported by the app. Arabic is rendered RTL.
enum LanguageCode {
  tr,
  en,
  ar;

  String get code => name;

  Locale get locale => Locale(name);

  bool get isRtl => this == LanguageCode.ar;

  static LanguageCode fromCode(String code) =>
      LanguageCode.values.firstWhere((e) => e.name == code,
          orElse: () => LanguageCode.tr);

  /// Resolves a supported [LanguageCode] from a device/[Locale], or `null` if
  /// the locale's language is not one of the supported languages. Only the
  /// language subtag is considered (e.g. `ar_EG` -> [ar]).
  static LanguageCode? fromLocaleOrNull(Locale locale) {
    for (final c in LanguageCode.values) {
      if (c.name == locale.languageCode) return c;
    }
    return null;
  }

  /// Resolves a supported language from [locale], falling back to English when
  /// the device language is not supported (per the Phase 2 spec).
  static LanguageCode fromDeviceLocale(Locale locale) =>
      fromLocaleOrNull(locale) ?? LanguageCode.en;
}
