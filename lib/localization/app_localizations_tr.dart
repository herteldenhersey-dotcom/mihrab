// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'MİHRAB';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navPrayerTimes => 'Namaz Vakitleri';

  @override
  String get navQibla => 'Kıble';

  @override
  String get navMosques => 'Camiler';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get prayerFajr => 'İmsak';

  @override
  String get prayerSunrise => 'Güneş';

  @override
  String get prayerDhuhr => 'Öğle';

  @override
  String get prayerAsr => 'İkindi';

  @override
  String get prayerMaghrib => 'Akşam';

  @override
  String get prayerIsha => 'Yatsı';

  @override
  String get nextPrayer => 'Sonraki Vakit';

  @override
  String get timeRemaining => 'Kalan Süre';

  @override
  String notificationPrayerTitle(String prayer) {
    return '$prayer vakti';
  }

  @override
  String notificationPrayerBody(String prayer) {
    return '$prayer namazı vakti girdi.';
  }

  @override
  String get onboardingWelcomeTitle => 'MİHRAB\'a Hoş Geldiniz';

  @override
  String get onboardingWelcomeBody => 'Çevrimdışı namaz ve ibadet arkadaşınız.';

  @override
  String get onboardingLanguageTitle => 'Dilinizi seçin';

  @override
  String get onboardingLocationTitle => 'Konum izni';

  @override
  String get onboardingLocationBody =>
      'Doğru namaz vakitlerini hesaplamak ve yakındaki camileri bulmak için konumunuzu kullanırız.';

  @override
  String get onboardingNotificationTitle => 'Namaz bildirimleri';

  @override
  String get onboardingNotificationBody => 'Her namaz vaktinde bildirim alın.';

  @override
  String get onboardingCalculationTitle => 'Hesaplama yöntemi';

  @override
  String get onboardingCalculationBody =>
      'Türkiye için varsayılan olarak Diyanet seçilidir.';

  @override
  String get continueLabel => 'Devam';

  @override
  String get skip => 'Atla';

  @override
  String get finish => 'Bitir';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsCalculationMethod => 'Hesaplama yöntemi';

  @override
  String get settingsAsrMethod => 'İkindi yöntemi';

  @override
  String get settingsNotifications => 'Bildirimler';

  @override
  String get settingsDarkMode => 'Karanlık mod';

  @override
  String get settingsManualOffsets => 'Manuel vakit düzeltmeleri';

  @override
  String get asrStandard => 'Standart (Şafii)';

  @override
  String get asrHanafi => 'Hanefi';

  @override
  String get feedbackTitle => 'Geri Bildirim';

  @override
  String get feedbackCategory => 'Kategori';

  @override
  String get feedbackMessage => 'Mesajınız';

  @override
  String get feedbackEmail => 'E-postanız (isteğe bağlı)';

  @override
  String get feedbackSend => 'Gönder';

  @override
  String get feedbackCategoryBug => 'Hata bildirimi';

  @override
  String get feedbackCategorySuggestion => 'Öneri';

  @override
  String get feedbackCategoryPrayerTimeIssue => 'Namaz vakti sorunu';

  @override
  String get feedbackCategoryTranslation => 'Çeviri';

  @override
  String get feedbackCategoryOther => 'Diğer';

  @override
  String get mosquesNearby => 'Yakındaki camiler';

  @override
  String get mosquesEmpty => 'Yakında cami bulunamadı.';

  @override
  String get qiblaTitle => 'Kıble yönü';

  @override
  String get qiblaCalibrate =>
      'Pusulayı kalibre etmek için telefonu 8 çizerek hareket ettirin.';

  @override
  String get ramadanTitle => 'Ramazan';

  @override
  String get jummahTitle => 'Cuma';

  @override
  String get errorNetwork => 'İnternet bağlantısı yok.';

  @override
  String get errorTimeout => 'İstek zaman aşımına uğradı.';

  @override
  String get errorRateLimit =>
      'Servis meşgul, lütfen daha sonra tekrar deneyin.';

  @override
  String get errorServer => 'Bir sunucu hatası oluştu.';

  @override
  String get errorLocation => 'Konum alınamadı.';

  @override
  String get errorPermission => 'İzin verilmedi.';

  @override
  String get errorSensor => 'Pusula sensörü kullanılamıyor.';

  @override
  String get errorUnknown => 'Bir şeyler ters gitti.';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get grantPermission => 'İzin ver';

  @override
  String get phase1Placeholder =>
      'Bu ekran ilerleyen bir fazda uygulanacaktır.';
}
