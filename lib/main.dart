import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'data/services/notification/notification_service.dart';
import 'domain/repositories/settings_repository.dart';
import 'injection.dart';
import 'localization/cubit/locale_cubit.dart';

/// Application entry point.
///
/// Startup order matters:
/// 1. Ensure the Flutter binding before any platform channel usage.
/// 2. Load the `.env` file (tolerant: missing file must not crash the app).
/// 3. Configure dependency injection (opens Hive boxes, SharedPreferences…).
/// 4. Initialize local notifications (timezone db + channels + permissions).
/// 5. Decide the initial route from persisted onboarding state.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tolerant load: a missing .env should not be fatal in Phase 1.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Fall back to compile-time defaults / platform env.
  }

  await configureDependencies();

  // Best-effort notification initialization; failures must not block launch.
  try {
    await getIt<NotificationService>().init();
  } catch (_) {
    // Notification setup can fail on unsupported platforms / denied perms.
  }

  final settings = getIt<SettingsRepository>();
  final onboardingComplete = await settings.getOnboardingComplete();
  final darkMode = await settings.getDarkMode();

  // Resolve the active language before first frame (stored choice, else device
  // locale detection with English fallback) so there is no visible re-layout.
  final localeCubit = getIt<LocaleCubit>();
  await localeCubit.load();

  runApp(
    MihrabApp(
      localeCubit: localeCubit,
      router: buildAppRouter(onboardingComplete: onboardingComplete),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.system,
    ),
  );
}
