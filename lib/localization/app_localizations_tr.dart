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
  String get onboardingLanguageSubtitle =>
      'Uygulama dilini istediğiniz zaman Ayarlar\'dan değiştirebilirsiniz.';

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
  String get locationSetupTitle => 'Konumunuzu ayarlayın';

  @override
  String get locationSetupSubtitle =>
      'MİHRAB; doğru namaz vakitleri, kıble yönü ve yakındaki camiler için konumunuza ihtiyaç duyar.';

  @override
  String get locationUseMyLocation => 'Konumumu kullan';

  @override
  String get locationSelectManually => 'Elle seç';

  @override
  String get locationRationaleTitle => 'Konumunuz neden gerekli';

  @override
  String get locationRationaleBody =>
      'Konumunuz yalnızca bu cihazda; doğru namaz vakitlerini hesaplamak, kıble yönünü göstermek ve yakındaki camileri bulmak için kullanılır. Arka planda asla takip edilmez.';

  @override
  String get locationSearching => 'Konumunuz aranıyor…';

  @override
  String get locationFound => 'Konum bulundu';

  @override
  String get locationServicesDisabledTitle => 'Konum servisleri kapalı';

  @override
  String get locationServicesDisabledBody =>
      'Mevcut konumunuzu kullanmak için konum servislerini açın veya konumunuzu elle seçin.';

  @override
  String get locationPermissionDeniedTitle => 'Konum izni verilmedi';

  @override
  String get locationPermissionDeniedBody =>
      'Konumunuza erişemiyoruz. Tekrar deneyebilir veya konumunuzu elle seçebilirsiniz.';

  @override
  String get locationPermissionPermanentlyDeniedTitle => 'Konum izni kapalı';

  @override
  String get locationPermissionPermanentlyDeniedBody =>
      'Konum izni kalıcı olarak reddedildi. İzin vermek için Ayarlar\'ı açın veya konumunuzu elle seçin.';

  @override
  String get locationTimeoutBody =>
      'Konumunuz alınırken çok uzun sürdü. Lütfen tekrar deneyin veya elle seçin.';

  @override
  String get locationErrorBody =>
      'Konumunuzu alamadık. Lütfen tekrar deneyin veya elle seçin.';

  @override
  String get openAppSettings => 'Ayarları aç';

  @override
  String get openLocationSettings => 'Konum ayarlarını aç';

  @override
  String get locationManualTitle => 'Konumunuzu arayın';

  @override
  String get locationSearchHint => 'Şehir veya ilçe arayın';

  @override
  String get locationSearch => 'Ara';

  @override
  String get locationCountry => 'Ülke';

  @override
  String get locationCity => 'Şehir';

  @override
  String get locationDistrict => 'İlçe';

  @override
  String get locationNoResults => 'Sonuç bulunamadı. Farklı bir arama deneyin.';

  @override
  String get tryAgain => 'Tekrar dene';

  @override
  String get locationConfirm => 'Konumu onayla';

  @override
  String get locationChange => 'Konumu değiştir';

  @override
  String get locationAddressUnavailable => 'Adres belirlenemedi';

  @override
  String get locationUsingCoordinates => 'Koordinatlar kullanılıyor';

  @override
  String get homeToday => 'Bugün';

  @override
  String get homeTomorrow => 'Yarın';

  @override
  String get homePrayerTimes => 'Namaz Vakitleri';

  @override
  String get homeNextPrayer => 'Sonraki Namaz';

  @override
  String get homeTimeRemaining => 'Kalan Süre';

  @override
  String get homeGregorianDate => 'Gregoryen Tarih';

  @override
  String get homeHijriDate => 'Hicri Tarih';

  @override
  String get homeLocation => 'Konum';

  @override
  String get homeChangeLocation => 'Konumu Değiştir';

  @override
  String get homeRefresh => 'Yenile';

  @override
  String get homeLastUpdated => 'Son Güncelleme';

  @override
  String get homeLoading => 'Namaz vakitleri hesaplanıyor...';

  @override
  String get homeErrorPrayerCalc => 'Namaz vakitleri hesaplanamadı.';

  @override
  String get homeErrorTimezone => 'Konum saat dilimi belirlenemedi.';

  @override
  String get homeErrorMissingLocation =>
      'Namaz vakitleri için konum gereklidir.';

  @override
  String get homeSetLocation => 'Konum Ayarla';

  @override
  String get homeComingSoon => 'Yakında';

  @override
  String get homeQibla => 'Kıble';

  @override
  String get homeNearbyMosques => 'Yakın Camiler';

  @override
  String get homeRamadan => 'Ramazan';

  @override
  String get homeSunriseLabel => 'Güneş Doğuşu';

  @override
  String get homeSunriseNote => '(Farz namaz değil)';

  @override
  String get homeRetry => 'Tekrar Dene';

  @override
  String homeNextPrayerIn(String name) {
    return '$name vakti';
  }

  @override
  String get homePrayerFajr => 'İmsak';

  @override
  String get homePrayerSunrise => 'Güneş';

  @override
  String get homePrayerDhuhr => 'Öğle';

  @override
  String get homePrayerAsr => 'İkindi';

  @override
  String get homePrayerMaghrib => 'Akşam';

  @override
  String get homePrayerIsha => 'Yatsı';

  @override
  String get homeSettings => 'Ayarlar';

  @override
  String homeTimezoneUsed(String id) {
    return 'Saat dilimi: $id';
  }

  @override
  String get phase1Placeholder =>
      'Bu ekran ilerleyen bir fazda uygulanacaktır.';
}
