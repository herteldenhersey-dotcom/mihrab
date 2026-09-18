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
}
