import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/services/clock.dart';
import '../../../../data/repositories/coordinate_timezone_repository.dart';
import '../../../../domain/entities/ramadan_info.dart';
import '../../../../domain/entities/ramadan_settings.dart';
import '../../../../domain/models/calculation_settings_model.dart';
import '../../../../domain/models/location_model.dart';
import '../../../../domain/models/prayer_times_model.dart';
import '../../../../domain/repositories/ramadan_repository.dart';
import '../../../../domain/repositories/settings_repository.dart';
import '../../../../domain/repositories/timezone_repository.dart';
import '../../../../domain/usecases/get_prayer_times_usecase.dart';
import '../../../../domain/usecases/get_ramadan_info_usecase.dart';
import 'ramadan_countdown_service.dart';

part 'ramadan_state.dart';

/// Drives the Ramadan feature (card + settings page countdown, spec §4/§7/§11).
///
/// Reuses the existing prayer-time calculation ([GetPrayerTimesUseCase]) — it
/// does NOT duplicate any sunset/Fajr math. Imsak = Fajr, Iftar = Maghrib.
///
/// Timezone: all "now"/day computations use the SELECTED LOCATION's IANA zone
/// (never the device zone), matching HomeCubit's approach.
class RamadanCubit extends Cubit<RamadanState> {
  final SettingsRepository _settings;
  final GetPrayerTimesUseCase _getPrayerTimes;
  final GetRamadanInfoUseCase _getRamadanInfo;
  final RamadanRepository _ramadanRepo;
  final TimezoneRepository _timezoneRepo;
  final Clock _clock;
  final RamadanCountdownService _countdownService;

  Timer? _timer;

  RamadanCubit({
    required SettingsRepository settings,
    required GetPrayerTimesUseCase getPrayerTimes,
    required GetRamadanInfoUseCase getRamadanInfo,
    required RamadanRepository ramadanRepo,
    required TimezoneRepository timezoneRepo,
    Clock? clock,
    RamadanCountdownService countdownService =
        const RamadanCountdownService(),
  })  : _settings = settings,
        _getPrayerTimes = getPrayerTimes,
        _getRamadanInfo = getRamadanInfo,
        _ramadanRepo = ramadanRepo,
        _timezoneRepo = timezoneRepo,
        _clock = clock ?? const SystemClock(),
        _countdownService = countdownService,
        super(const RamadanInitial());

  Future<void> load() async {
    emit(const RamadanLoading());
    final location = await _settings.getSavedLocation();
    if (location == null || !location.hasValidCoordinates) {
      emit(const RamadanMissingLocation());
      return;
    }
    await _loadForLocation(location);
  }

  Future<void> refresh() => load();

  /// Called when the app resumes — recompute from the real clock (no drift).
  Future<void> onResume() async {
    final current = state;
    if (current is! RamadanLoaded) return;
    final locationNow = _nowInZone(current.timezoneId);
    if (locationNow.day != current.locationNow.day) {
      await _loadForLocation(await _settings.getSavedLocation() ??
          _fallbackLocation(current));
      return;
    }
    _tick();
  }

  /// Persists updated Ramadan [settings] and reloads (triggers reschedule by
  /// the caller/home via its own notification pipeline).
  Future<void> updateSettings(RamadanSettings settings) async {
    await _ramadanRepo.saveSettings(settings);
    await load();
  }

  Future<void> _loadForLocation(AppLocation location) async {
    _stopTimer();

    // Resolve timezone (reuse the same strategy as HomeCubit).
    String? tzId = location.timezoneId;
    if (tzId == null) {
      if (location.country != null &&
          location.country!.isNotEmpty &&
          _timezoneRepo is CoordinateTimezoneRepository) {
        tzId = (_timezoneRepo)
            .resolveFromCountryCode(location.country!, location.longitude);
      }
      tzId ??= await _timezoneRepo.resolveTimezone(
          location.latitude, location.longitude);
      tzId ??= await _timezoneRepo.getCachedTimezone();
    }
    if (tzId == null) {
      emit(const RamadanFailure('ramadanErrorTimezone'));
      return;
    }

    final locationNow = _nowInZone(tzId);

    CalculationSettings calc;
    try {
      calc = await _settings.getCalculationSettings();
    } catch (_) {
      calc = CalculationSettings.turkeyDefault;
    }

    final ramadanSettings = await _ramadanRepo.loadSettings();

    final todayDate =
        DateTime(locationNow.year, locationNow.month, locationNow.day);
    final tomorrowDate = todayDate.add(const Duration(days: 1));

    DailyPrayerTimes today, tomorrow;
    try {
      today = await _getPrayerTimes(
        latitude: location.latitude,
        longitude: location.longitude,
        date: todayDate,
        settings: calc,
      );
      tomorrow = await _getPrayerTimes(
        latitude: location.latitude,
        longitude: location.longitude,
        date: tomorrowDate,
        settings: calc,
      );
    } catch (_) {
      emit(const RamadanFailure('ramadanErrorCalc'));
      return;
    }

    final info = _getRamadanInfo(locationNow,
        adjustment: ramadanSettings.hijriAdjustment);

    final countdown = _countdownService.compute(
      now: locationNow,
      imsak: today.fajr,
      iftar: today.maghrib,
      tomorrowImsak: tomorrow.fajr,
    );

    emit(RamadanLoaded(
      info: info,
      settings: ramadanSettings,
      imsak: today.fajr,
      iftar: today.maghrib,
      tomorrowImsak: tomorrow.fajr,
      countdown: countdown,
      locationNow: locationNow,
      timezoneId: tzId,
    ));

    _startTimer();
  }

  AppLocation _fallbackLocation(RamadanLoaded current) => AppLocation(
        latitude: 41.0082,
        longitude: 28.9784,
        timezoneId: current.timezoneId,
      );

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    final current = state;
    if (current is! RamadanLoaded) {
      _stopTimer();
      return;
    }
    final locationNow = _nowInZone(current.timezoneId);
    // Day boundary → reload.
    if (locationNow.day != current.locationNow.day ||
        locationNow.month != current.locationNow.month) {
      load();
      return;
    }
    final countdown = _countdownService.compute(
      now: locationNow,
      imsak: current.imsak,
      iftar: current.iftar,
      tomorrowImsak: current.tomorrowImsak,
    );
    emit(current.copyWith(countdown: countdown, locationNow: locationNow));
  }

  DateTime _nowInZone(String tzId) {
    final utc = _clock.now().toUtc();
    try {
      final loc = tz.getLocation(tzId);
      final t = tz.TZDateTime.from(utc, loc);
      return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
    } catch (_) {
      return utc.toLocal();
    }
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}
