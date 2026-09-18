import 'dart:io' show Platform;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/connectivity_service.dart';
import 'core/network/dio_client.dart';
import 'data/datasources/local/hive_adapters.dart';
import 'data/datasources/local/hive_boxes.dart';
import 'data/datasources/local/hive_feedback_local.dart';
import 'data/datasources/local/hive_mosque_cache.dart';
import 'data/datasources/local/shared_prefs_settings.dart';
import 'data/datasources/remote/overpass_api_datasource.dart';
import 'data/providers/adhan_prayer_time_provider.dart';
import 'data/repositories/geolocator_location_repository.dart';
import 'data/repositories/hive_settings_repository.dart';
import 'data/repositories/local_feedback_repository.dart';
import 'data/repositories/overpass_mosque_repository.dart';
import 'data/services/compass/compass_service.dart';
import 'data/services/location/location_service.dart';
import 'data/services/notification/alarm_permission_service.dart';
import 'data/services/notification/android_notification_scheduler.dart';
import 'data/services/notification/ios_notification_scheduler.dart';
import 'data/services/notification/notification_service.dart';
import 'data/services/notification/prayer_notification_scheduler.dart';
import 'domain/models/feedback_model.dart';
import 'domain/providers/prayer_time_provider.dart';
import 'domain/repositories/feedback_repository.dart';
import 'domain/repositories/location_repository.dart';
import 'domain/repositories/mosque_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/usecases/get_nearby_mosques_usecase.dart';
import 'domain/usecases/get_next_prayer_usecase.dart';
import 'domain/usecases/get_prayer_times_usecase.dart';
import 'domain/usecases/get_qibla_direction_usecase.dart';
import 'domain/usecases/schedule_notifications_usecase.dart';
import 'domain/usecases/submit_feedback_usecase.dart';
import 'localization/cubit/locale_cubit.dart';

/// Global service locator.
final GetIt getIt = GetIt.instance;

/// Wires up every dependency. Called once from `main()` after Flutter binding
/// initialization, dotenv load and Hive/prefs setup.
///
/// We use MANUAL registration (no injectable codegen) because the current
/// stable toolchain cannot run injectable_generator (see pubspec.yaml note).
/// The graph below is intentionally explicit and easy to audit.
Future<void> configureDependencies() async {
  // --- Local storage bootstrapping --------------------------------------
  await Hive.initFlutter();
  registerHiveAdapters();
  await Hive.openBox<MosqueCacheEntry>(HiveBoxes.mosqueCache);
  await Hive.openBox<FeedbackItem>(HiveBoxes.feedback);

  final prefs = await SharedPreferences.getInstance();

  // --- Core singletons ---------------------------------------------------
  getIt
    ..registerLazySingleton<DioClient>(() => DioClient.create())
    ..registerLazySingleton<ConnectivityService>(() => ConnectivityService())
    ..registerLazySingleton<SharedPrefsSettings>(
        () => SharedPrefsSettings(prefs));

  // --- Data sources ------------------------------------------------------
  getIt
    ..registerLazySingleton<HiveMosqueCache>(() => HiveMosqueCache())
    ..registerLazySingleton<HiveFeedbackLocal>(() => HiveFeedbackLocal())
    ..registerLazySingleton<OverpassApiDataSource>(
        () => OverpassApiDataSource(getIt<DioClient>().dio));

  // --- Providers ---------------------------------------------------------
  getIt.registerLazySingleton<PrayerTimeProvider>(
      () => const AdhanPrayerTimeProvider());

  // --- Repositories ------------------------------------------------------
  getIt
    ..registerLazySingleton<MosqueRepository>(() => OverpassMosqueRepository(
          getIt<OverpassApiDataSource>(),
          getIt<HiveMosqueCache>(),
        ))
    ..registerLazySingleton<FeedbackRepository>(() => LocalFeedbackRepository(
          getIt<HiveFeedbackLocal>(),
          feedbackEmail: dotenv.maybeGet('FEEDBACK_EMAIL'),
        ))
    ..registerLazySingleton<LocationRepository>(
        () => GeolocatorLocationRepository())
    ..registerLazySingleton<SettingsRepository>(
        () => HiveSettingsRepository(getIt<SharedPrefsSettings>()));

  // --- Services ----------------------------------------------------------
  getIt
    ..registerLazySingleton<NotificationService>(
        () => FlutterLocalNotificationService())
    ..registerLazySingleton<AlarmPermissionService>(
        () => AlarmPermissionService())
    ..registerLazySingleton<LocationService>(() => LocationService(
          getIt<LocationRepository>(),
          getIt<SettingsRepository>(),
        ))
    ..registerLazySingleton<CompassService>(() => CompassService());

  // Platform-specific notification scheduler.
  getIt.registerLazySingleton<PrayerNotificationScheduler>(() {
    final service = getIt<NotificationService>();
    if (Platform.isIOS) {
      return IosPrayerNotificationScheduler(service);
    }
    // Android + fallback for other platforms during development/testing.
    return AndroidPrayerNotificationScheduler(
      service,
      getIt<AlarmPermissionService>(),
    );
  });

  // --- App-wide cubits ---------------------------------------------------
  // LocaleCubit is a singleton: one source of truth for the active language,
  // provided at the widget-tree root and read by the language onboarding step.
  getIt.registerLazySingleton<LocaleCubit>(
      () => LocaleCubit(getIt<SettingsRepository>()));

  // --- Use cases ---------------------------------------------------------
  getIt
    ..registerFactory<GetPrayerTimesUseCase>(
        () => GetPrayerTimesUseCase(getIt<PrayerTimeProvider>()))
    ..registerFactory<GetNextPrayerUseCase>(
        () => GetNextPrayerUseCase(getIt<GetPrayerTimesUseCase>()))
    ..registerFactory<GetNearbyMosquesUseCase>(
        () => GetNearbyMosquesUseCase(getIt<MosqueRepository>()))
    ..registerFactory<GetQiblaDirectionUseCase>(
        () => GetQiblaDirectionUseCase(getIt<PrayerTimeProvider>()))
    ..registerFactory<SubmitFeedbackUseCase>(
        () => SubmitFeedbackUseCase(getIt<FeedbackRepository>()))
    ..registerFactory<ScheduleNotificationsUseCase>(
        () => ScheduleNotificationsUseCase(
              getIt<GetPrayerTimesUseCase>(),
              getIt<PrayerNotificationScheduler>(),
            ));
}
