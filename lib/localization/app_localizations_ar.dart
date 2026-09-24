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
  String get onboardingLanguageSubtitle =>
      'يمكنك تغيير لغة التطبيق في أي وقت من الإعدادات.';

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
  String get locationSetupTitle => 'حدّد موقعك';

  @override
  String get locationSetupSubtitle =>
      'يحتاج المحراب إلى موقعك لحساب أوقات الصلاة الدقيقة واتجاه القبلة والمساجد القريبة.';

  @override
  String get locationUseMyLocation => 'استخدام موقعي';

  @override
  String get locationSelectManually => 'التحديد يدويًا';

  @override
  String get locationRationaleTitle => 'لماذا نحتاج إلى موقعك';

  @override
  String get locationRationaleBody =>
      'يُستخدم موقعك على هذا الجهاز فقط لحساب أوقات الصلاة الدقيقة وتحديد اتجاه القبلة والعثور على المساجد القريبة. ولا تتم مراقبته في الخلفية أبدًا.';

  @override
  String get locationSearching => 'جارٍ تحديد موقعك…';

  @override
  String get locationFound => 'تم العثور على الموقع';

  @override
  String get locationServicesDisabledTitle => 'خدمات الموقع متوقفة';

  @override
  String get locationServicesDisabledBody =>
      'فعّل خدمات الموقع لاستخدام موقعك الحالي، أو حدّد موقعك يدويًا.';

  @override
  String get locationPermissionDeniedTitle => 'تم رفض إذن الموقع';

  @override
  String get locationPermissionDeniedBody =>
      'لا يمكننا الوصول إلى موقعك. يمكنك المحاولة مرة أخرى أو تحديد موقعك يدويًا.';

  @override
  String get locationPermissionPermanentlyDeniedTitle => 'إذن الموقع متوقف';

  @override
  String get locationPermissionPermanentlyDeniedBody =>
      'تم رفض إذن الموقع بشكل دائم. افتح الإعدادات للسماح به، أو حدّد موقعك يدويًا.';

  @override
  String get locationTimeoutBody =>
      'استغرق تحديد موقعك وقتًا طويلًا. يرجى المحاولة مرة أخرى أو التحديد يدويًا.';

  @override
  String get locationErrorBody =>
      'تعذّر الحصول على موقعك. يرجى المحاولة مرة أخرى أو التحديد يدويًا.';

  @override
  String get openAppSettings => 'فتح الإعدادات';

  @override
  String get openLocationSettings => 'فتح إعدادات الموقع';

  @override
  String get locationManualTitle => 'ابحث عن موقعك';

  @override
  String get locationSearchHint => 'ابحث عن مدينة أو منطقة';

  @override
  String get locationSearch => 'بحث';

  @override
  String get locationCountry => 'الدولة';

  @override
  String get locationCity => 'المدينة';

  @override
  String get locationDistrict => 'المنطقة';

  @override
  String get locationNoResults =>
      'لم يتم العثور على نتائج. جرّب بحثًا مختلفًا.';

  @override
  String get tryAgain => 'إعادة المحاولة';

  @override
  String get locationConfirm => 'تأكيد الموقع';

  @override
  String get locationChange => 'تغيير الموقع';

  @override
  String get locationAddressUnavailable => 'تعذّر تحديد العنوان';

  @override
  String get locationUsingCoordinates => 'استخدام الإحداثيات';

  @override
  String get homeToday => 'اليوم';

  @override
  String get homeTomorrow => 'غداً';

  @override
  String get homePrayerTimes => 'مواقيت الصلاة';

  @override
  String get homeNextPrayer => 'الصلاة القادمة';

  @override
  String get homeTimeRemaining => 'الوقت المتبقي';

  @override
  String get homeGregorianDate => 'التاريخ';

  @override
  String get homeHijriDate => 'التاريخ الهجري';

  @override
  String get homeLocation => 'الموقع';

  @override
  String get homeChangeLocation => 'تغيير الموقع';

  @override
  String get homeRefresh => 'تحديث';

  @override
  String get homeLastUpdated => 'آخر تحديث';

  @override
  String get homeLoading => 'جارٍ حساب مواقيت الصلاة...';

  @override
  String get homeErrorPrayerCalc => 'تعذّر حساب مواقيت الصلاة.';

  @override
  String get homeErrorTimezone => 'تعذّر تحديد المنطقة الزمنية للموقع.';

  @override
  String get homeErrorMissingLocation => 'يلزم تحديد الموقع لمواقيت الصلاة.';

  @override
  String get homeSetLocation => 'تحديد الموقع';

  @override
  String get homeComingSoon => 'قريبًا';

  @override
  String get homeQibla => 'القبلة';

  @override
  String get homeNearbyMosques => 'المساجد القريبة';

  @override
  String get homeRamadan => 'رمضان';

  @override
  String get homeSunriseLabel => 'شروق الشمس';

  @override
  String get homeSunriseNote => '(ليست فريضة)';

  @override
  String get homeRetry => 'إعادة المحاولة';

  @override
  String homeNextPrayerIn(String name) {
    return '$name';
  }

  @override
  String get homePrayerFajr => 'الفجر';

  @override
  String get homePrayerSunrise => 'الشروق';

  @override
  String get homePrayerDhuhr => 'الظهر';

  @override
  String get homePrayerAsr => 'العصر';

  @override
  String get homePrayerMaghrib => 'المغرب';

  @override
  String get homePrayerIsha => 'العشاء';

  @override
  String get homeSettings => 'الإعدادات';

  @override
  String homeTimezoneUsed(String id) {
    return 'المنطقة الزمنية: $id';
  }

  @override
  String get phase1Placeholder => 'سيتم تنفيذ هذه الشاشة في مرحلة لاحقة.';
}
