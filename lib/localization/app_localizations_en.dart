// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MİHRAB';

  @override
  String get navHome => 'Home';

  @override
  String get navPrayerTimes => 'Prayer Times';

  @override
  String get navQibla => 'Qibla';

  @override
  String get navMosques => 'Mosques';

  @override
  String get navSettings => 'Settings';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get nextPrayer => 'Next Prayer';

  @override
  String get timeRemaining => 'Time Remaining';

  @override
  String notificationPrayerTitle(String prayer) {
    return '$prayer time';
  }

  @override
  String notificationPrayerBody(String prayer) {
    return 'It is time for $prayer prayer.';
  }

  @override
  String get onboardingWelcomeTitle => 'Welcome to MİHRAB';

  @override
  String get onboardingWelcomeBody =>
      'Your offline prayer & worship companion.';

  @override
  String get onboardingLanguageTitle => 'Choose your language';

  @override
  String get onboardingLanguageSubtitle =>
      'You can change the app language anytime from Settings.';

  @override
  String get onboardingLocationTitle => 'Location permission';

  @override
  String get onboardingLocationBody =>
      'We use your location to calculate accurate prayer times and find nearby mosques.';

  @override
  String get onboardingNotificationTitle => 'Prayer notifications';

  @override
  String get onboardingNotificationBody => 'Get notified at each prayer time.';

  @override
  String get onboardingCalculationTitle => 'Calculation method';

  @override
  String get onboardingCalculationBody =>
      'Diyanet is selected by default for Turkey.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get skip => 'Skip';

  @override
  String get finish => 'Finish';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsCalculationMethod => 'Calculation method';

  @override
  String get settingsAsrMethod => 'Asr method';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsDarkMode => 'Dark mode';

  @override
  String get settingsManualOffsets => 'Manual time offsets';

  @override
  String get asrStandard => 'Standard (Shafi\'i)';

  @override
  String get asrHanafi => 'Hanafi';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get feedbackCategory => 'Category';

  @override
  String get feedbackMessage => 'Your message';

  @override
  String get feedbackEmail => 'Your email (optional)';

  @override
  String get feedbackSend => 'Send';

  @override
  String get feedbackCategoryBug => 'Bug report';

  @override
  String get feedbackCategorySuggestion => 'Suggestion';

  @override
  String get feedbackCategoryPrayerTimeIssue => 'Prayer time issue';

  @override
  String get feedbackCategoryTranslation => 'Translation';

  @override
  String get feedbackCategoryOther => 'Other';

  @override
  String get mosquesNearby => 'Nearby mosques';

  @override
  String get mosquesEmpty => 'No mosques found nearby.';

  @override
  String get qiblaTitle => 'Qibla direction';

  @override
  String get qiblaCalibrate => 'Move your phone in a figure-8 to calibrate.';

  @override
  String get ramadanTitle => 'Ramadan';

  @override
  String get jummahTitle => 'Jummah';

  @override
  String get errorNetwork => 'No internet connection.';

  @override
  String get errorTimeout => 'The request timed out.';

  @override
  String get errorRateLimit => 'Service is busy, please try again later.';

  @override
  String get errorServer => 'A server error occurred.';

  @override
  String get errorLocation => 'Location unavailable.';

  @override
  String get errorPermission => 'Permission denied.';

  @override
  String get errorSensor => 'Compass sensor unavailable.';

  @override
  String get errorUnknown => 'Something went wrong.';

  @override
  String get retry => 'Retry';

  @override
  String get grantPermission => 'Grant permission';

  @override
  String get phase1Placeholder =>
      'This screen will be implemented in a later phase.';
}
