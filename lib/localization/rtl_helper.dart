import 'dart:ui';

import '../domain/enums/language_code.dart';

/// Helpers for right-to-left layout (Arabic).
class RtlHelper {
  RtlHelper._();

  static TextDirection getTextDirection(LanguageCode code) =>
      code.isRtl ? TextDirection.rtl : TextDirection.ltr;

  static bool isRtl(LanguageCode code) => code.isRtl;
}
