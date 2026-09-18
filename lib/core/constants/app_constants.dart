/// App-wide, non-configurable constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'MİHRAB';

  /// Development identifier. Will be replaced with the production id later.
  static const String packageId = 'com.mihrab.app';

  /// Kaaba coordinates (used for qibla direction).
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;

  /// Default fallback location (Istanbul, Fatih) used before GPS is available.
  static const double defaultLatitude = 41.0082;
  static const double defaultLongitude = 28.9784;
  static const String defaultCity = 'İstanbul';
  static const String defaultCountry = 'Türkiye';

  /// Feedback destination when FEEDBACK_EMAIL env is not provided.
  static const String fallbackFeedbackEmail = 'feedback@mihrab.app';

  /// Overpass API endpoints (primary + fallback). No API key required.
  static const List<String> overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  /// User agent sent to OSM/Overpass (their usage policy requires one).
  static const String httpUserAgent = 'MihrabApp/1.0 (contact: feedback@mihrab.app)';
}
