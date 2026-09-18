// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'المحراب';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navPrayerTimes => 'أوقات الصلاة';

  @override
  String get navQibla => 'القبلة';

  @override
  String get navMosques => 'المساجد';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get timeRemaining => 'الوقت المتبقي';

  @override
  String notificationPrayerTitle(String prayer) {
    return 'وقت $prayer';
  }

  @override
  String notificationPrayerBody(String prayer) {
    return 'حان وقت صلاة $prayer.';
  }

  @override
  String get onboardingWelcomeTitle => 'مرحبًا بك في المحراب';

  @override
  String get onboardingWelcomeBody => 'رفيقك للصلاة والعبادة دون اتصال.';

  @override
  String get onboardingLanguageTitle => 'اختر لغتك';

  @override
  String get onboardingLocationTitle => 'إذن الموقع';

  @override
  String get onboardingLocationBody =>
      'نستخدم موقعك لحساب أوقات الصلاة الدقيقة والعثور على المساجد القريبة.';

  @override
  String get onboardingNotificationTitle => 'إشعارات الصلاة';

  @override
  String get onboardingNotificationBody => 'احصل على إشعار عند كل وقت صلاة.';

  @override
  String get onboardingCalculationTitle => 'طريقة الحساب';

  @override
  String get onboardingCalculationBody => 'تم اختيار ديانت افتراضيًا لتركيا.';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get skip => 'تخطٍ';

  @override
  String get finish => 'إنهاء';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsCalculationMethod => 'طريقة الحساب';

  @override
  String get settingsAsrMethod => 'طريقة العصر';

  @override
  String get settingsNotifications => 'الإشعارات';

  @override
  String get settingsDarkMode => 'الوضع الداكن';

  @override
  String get settingsManualOffsets => 'تعديلات الوقت اليدوية';

  @override
  String get asrStandard => 'قياسي (شافعي)';

  @override
  String get asrHanafi => 'حنفي';

  @override
  String get feedbackTitle => 'ملاحظات';

  @override
  String get feedbackCategory => 'الفئة';

  @override
  String get feedbackMessage => 'رسالتك';

  @override
  String get feedbackEmail => 'بريدك الإلكتروني (اختياري)';

  @override
  String get feedbackSend => 'إرسال';

  @override
  String get feedbackCategoryBug => 'تقرير خطأ';

  @override
  String get feedbackCategorySuggestion => 'اقتراح';

  @override
  String get feedbackCategoryPrayerTimeIssue => 'مشكلة في وقت الصلاة';

  @override
  String get feedbackCategoryTranslation => 'ترجمة';

  @override
  String get feedbackCategoryOther => 'أخرى';

  @override
  String get mosquesNearby => 'المساجد القريبة';

  @override
  String get mosquesEmpty => 'لم يتم العثور على مساجد قريبة.';

  @override
  String get qiblaTitle => 'اتجاه القبلة';

  @override
  String get qiblaCalibrate => 'حرّك هاتفك على شكل رقم 8 للمعايرة.';

  @override
  String get ramadanTitle => 'رمضان';

  @override
  String get jummahTitle => 'الجمعة';

  @override
  String get errorNetwork => 'لا يوجد اتصال بالإنترنت.';

  @override
  String get errorTimeout => 'انتهت مهلة الطلب.';

  @override
  String get errorRateLimit => 'الخدمة مشغولة، يرجى المحاولة لاحقًا.';

  @override
  String get errorServer => 'حدث خطأ في الخادم.';

  @override
  String get errorLocation => 'الموقع غير متاح.';

  @override
  String get errorPermission => 'تم رفض الإذن.';

  @override
  String get errorSensor => 'مستشعر البوصلة غير متاح.';

  @override
  String get errorUnknown => 'حدث خطأ ما.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get grantPermission => 'منح الإذن';

  @override
  String get phase1Placeholder => 'سيتم تنفيذ هذه الشاشة في مرحلة لاحقة.';
}
