import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MİHRAB'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPrayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get navPrayerTimes;

  /// No description provided for @navQibla.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get navQibla;

  /// No description provided for @navMosques.
  ///
  /// In en, this message translates to:
  /// **'Mosques'**
  String get navMosques;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerSunrise;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// No description provided for @nextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Next Prayer'**
  String get nextPrayer;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time Remaining'**
  String get timeRemaining;

  /// No description provided for @notificationPrayerTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayer} time'**
  String notificationPrayerTitle(String prayer);

  /// No description provided for @notificationPrayerBody.
  ///
  /// In en, this message translates to:
  /// **'It is time for {prayer} prayer.'**
  String notificationPrayerBody(String prayer);

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MİHRAB'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Your offline prayer & worship companion.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboardingLanguageTitle;

  /// No description provided for @onboardingLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change the app language anytime from Settings.'**
  String get onboardingLanguageSubtitle;

  /// No description provided for @onboardingLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission'**
  String get onboardingLocationTitle;

  /// No description provided for @onboardingLocationBody.
  ///
  /// In en, this message translates to:
  /// **'We use your location to calculate accurate prayer times and find nearby mosques.'**
  String get onboardingLocationBody;

  /// No description provided for @onboardingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer notifications'**
  String get onboardingNotificationTitle;

  /// No description provided for @onboardingNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Get notified at each prayer time.'**
  String get onboardingNotificationBody;

  /// No description provided for @onboardingCalculationTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get onboardingCalculationTitle;

  /// No description provided for @onboardingCalculationBody.
  ///
  /// In en, this message translates to:
  /// **'Diyanet is selected by default for Turkey.'**
  String get onboardingCalculationBody;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsCalculationMethod.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get settingsCalculationMethod;

  /// No description provided for @settingsAsrMethod.
  ///
  /// In en, this message translates to:
  /// **'Asr method'**
  String get settingsAsrMethod;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsManualOffsets.
  ///
  /// In en, this message translates to:
  /// **'Manual time offsets'**
  String get settingsManualOffsets;

  /// No description provided for @asrStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard (Shafi\'i)'**
  String get asrStandard;

  /// No description provided for @asrHanafi.
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get asrHanafi;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTitle;

  /// No description provided for @feedbackCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get feedbackCategory;

  /// No description provided for @feedbackMessage.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get feedbackMessage;

  /// No description provided for @feedbackEmail.
  ///
  /// In en, this message translates to:
  /// **'Your email (optional)'**
  String get feedbackEmail;

  /// No description provided for @feedbackSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get feedbackSend;

  /// No description provided for @feedbackCategoryBug.
  ///
  /// In en, this message translates to:
  /// **'Bug report'**
  String get feedbackCategoryBug;

  /// No description provided for @feedbackCategorySuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get feedbackCategorySuggestion;

  /// No description provided for @feedbackCategoryPrayerTimeIssue.
  ///
  /// In en, this message translates to:
  /// **'Prayer time issue'**
  String get feedbackCategoryPrayerTimeIssue;

  /// No description provided for @feedbackCategoryTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get feedbackCategoryTranslation;

  /// No description provided for @feedbackCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackCategoryOther;

  /// No description provided for @mosquesNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby mosques'**
  String get mosquesNearby;

  /// No description provided for @mosquesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No mosques found nearby.'**
  String get mosquesEmpty;

  /// No description provided for @qiblaTitle.
  ///
  /// In en, this message translates to:
  /// **'Qibla direction'**
  String get qiblaTitle;

  /// No description provided for @qiblaCalibrate.
  ///
  /// In en, this message translates to:
  /// **'Move your phone in a figure-8 to calibrate.'**
  String get qiblaCalibrate;

  /// No description provided for @ramadanTitle.
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get ramadanTitle;

  /// No description provided for @jummahTitle.
  ///
  /// In en, this message translates to:
  /// **'Jummah'**
  String get jummahTitle;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out.'**
  String get errorTimeout;

  /// No description provided for @errorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Service is busy, please try again later.'**
  String get errorRateLimit;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'A server error occurred.'**
  String get errorServer;

  /// No description provided for @errorLocation.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable.'**
  String get errorLocation;

  /// No description provided for @errorPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission denied.'**
  String get errorPermission;

  /// No description provided for @errorSensor.
  ///
  /// In en, this message translates to:
  /// **'Compass sensor unavailable.'**
  String get errorSensor;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorUnknown;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant permission'**
  String get grantPermission;

  /// No description provided for @locationSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your location'**
  String get locationSetupTitle;

  /// No description provided for @locationSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'MİHRAB needs your location for accurate prayer times, the qibla direction and nearby mosques.'**
  String get locationSetupSubtitle;

  /// No description provided for @locationUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get locationUseMyLocation;

  /// No description provided for @locationSelectManually.
  ///
  /// In en, this message translates to:
  /// **'Select manually'**
  String get locationSelectManually;

  /// No description provided for @locationRationaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Why we need your location'**
  String get locationRationaleTitle;

  /// No description provided for @locationRationaleBody.
  ///
  /// In en, this message translates to:
  /// **'Your location is used only on this device to calculate accurate prayer times, point you toward the qibla and find nearby mosques. It is never tracked in the background.'**
  String get locationRationaleBody;

  /// No description provided for @locationSearching.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get locationSearching;

  /// No description provided for @locationFound.
  ///
  /// In en, this message translates to:
  /// **'Location found'**
  String get locationFound;

  /// No description provided for @locationServicesDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Location services are off'**
  String get locationServicesDisabledTitle;

  /// No description provided for @locationServicesDisabledBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to use your current location, or select your location manually.'**
  String get locationServicesDisabledBody;

  /// No description provided for @locationPermissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDeniedTitle;

  /// No description provided for @locationPermissionDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'We can’t access your location. You can try again or select your location manually.'**
  String get locationPermissionDeniedBody;

  /// No description provided for @locationPermissionPermanentlyDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission is off'**
  String get locationPermissionPermanentlyDeniedTitle;

  /// No description provided for @locationPermissionPermanentlyDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Open Settings to allow it, or select your location manually.'**
  String get locationPermissionPermanentlyDeniedBody;

  /// No description provided for @locationTimeoutBody.
  ///
  /// In en, this message translates to:
  /// **'Getting your location took too long. Please try again or select manually.'**
  String get locationTimeoutBody;

  /// No description provided for @locationErrorBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t get your location. Please try again or select manually.'**
  String get locationErrorBody;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openAppSettings;

  /// No description provided for @openLocationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open location settings'**
  String get openLocationSettings;

  /// No description provided for @locationManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Search for your location'**
  String get locationManualTitle;

  /// No description provided for @locationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a city or district'**
  String get locationSearchHint;

  /// No description provided for @locationSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get locationSearch;

  /// No description provided for @locationCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get locationCountry;

  /// No description provided for @locationCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get locationCity;

  /// No description provided for @locationDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get locationDistrict;

  /// No description provided for @locationNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found. Try a different search.'**
  String get locationNoResults;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @locationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get locationConfirm;

  /// No description provided for @locationChange.
  ///
  /// In en, this message translates to:
  /// **'Change location'**
  String get locationChange;

  /// No description provided for @locationAddressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to determine address'**
  String get locationAddressUnavailable;

  /// No description provided for @locationUsingCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Using coordinates'**
  String get locationUsingCoordinates;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get homeTomorrow;

  /// No description provided for @homePrayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get homePrayerTimes;

  /// No description provided for @homeNextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Next Prayer'**
  String get homeNextPrayer;

  /// No description provided for @homeTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time Remaining'**
  String get homeTimeRemaining;

  /// No description provided for @homeGregorianDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get homeGregorianDate;

  /// No description provided for @homeHijriDate.
  ///
  /// In en, this message translates to:
  /// **'Hijri Date'**
  String get homeHijriDate;

  /// No description provided for @homeLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get homeLocation;

  /// No description provided for @homeChangeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change Location'**
  String get homeChangeLocation;

  /// No description provided for @homeRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get homeRefresh;

  /// No description provided for @homeLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get homeLastUpdated;

  /// No description provided for @homeLoading.
  ///
  /// In en, this message translates to:
  /// **'Calculating prayer times...'**
  String get homeLoading;

  /// No description provided for @homeErrorPrayerCalc.
  ///
  /// In en, this message translates to:
  /// **'Could not calculate prayer times.'**
  String get homeErrorPrayerCalc;

  /// No description provided for @homeErrorTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone for location could not be determined.'**
  String get homeErrorTimezone;

  /// No description provided for @homeErrorMissingLocation.
  ///
  /// In en, this message translates to:
  /// **'Location required for prayer times.'**
  String get homeErrorMissingLocation;

  /// No description provided for @homeSetLocation.
  ///
  /// In en, this message translates to:
  /// **'Set Location'**
  String get homeSetLocation;

  /// No description provided for @homeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get homeComingSoon;

  /// No description provided for @homeQibla.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get homeQibla;

  /// No description provided for @homeNearbyMosques.
  ///
  /// In en, this message translates to:
  /// **'Nearby Mosques'**
  String get homeNearbyMosques;

  /// No description provided for @homeRamadan.
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get homeRamadan;

  /// No description provided for @homeSunriseLabel.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get homeSunriseLabel;

  /// No description provided for @homeSunriseNote.
  ///
  /// In en, this message translates to:
  /// **'(Not an obligatory prayer)'**
  String get homeSunriseNote;

  /// No description provided for @homeRetry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get homeRetry;

  /// No description provided for @homeNextPrayerIn.
  ///
  /// In en, this message translates to:
  /// **'{name}'**
  String homeNextPrayerIn(String name);

  /// No description provided for @homePrayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get homePrayerFajr;

  /// No description provided for @homePrayerSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get homePrayerSunrise;

  /// No description provided for @homePrayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get homePrayerDhuhr;

  /// No description provided for @homePrayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get homePrayerAsr;

  /// No description provided for @homePrayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get homePrayerMaghrib;

  /// No description provided for @homePrayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get homePrayerIsha;

  /// No description provided for @homeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// No description provided for @homeTimezoneUsed.
  ///
  /// In en, this message translates to:
  /// **'Timezone: {id}'**
  String homeTimezoneUsed(String id);

  /// No description provided for @phase1Placeholder.
  ///
  /// In en, this message translates to:
  /// **'This screen will be implemented in a later phase.'**
  String get phase1Placeholder;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
