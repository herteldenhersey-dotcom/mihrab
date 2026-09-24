/// Centralized route path definitions for MİHRAB.
///
/// Keeping route strings in one place avoids typos and makes it easy to
/// reference routes from anywhere (widgets, cubits, deep links).
class AppRoutes {
  const AppRoutes._();

  static const String onboarding = '/onboarding';

  // Bottom navigation shell branches.
  static const String home = '/home';
  static const String prayerTimes = '/prayer-times';
  static const String qibla = '/qibla';
  static const String mosques = '/mosques';
  static const String settings = '/settings';

  // Pushed (non-shell) routes.
  static const String ramadan = '/ramadan';
  static const String jummah = '/jummah';
  static const String feedback = '/feedback';

  // Utility routes.
  static const String locationSetup = '/location-setup';
}
